<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLParamevalController extends AbstractController
{
	public function mlparamEvaluationAction()
	{
		$db = $this->container->getDBUtils ();
		$rows = $categories = $series = '';
		$must_wait = 'NO';
		try {
			$configurations = array ();	// Useless here
			$where_configs = '';
			$concat_config = ""; 		// Useless here
			
			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('parameval',$_GET))
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$params['benchs'] = array('terasort');
				$where_configs = ' AND bench IN ("terasort")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'net') $params['nets'] = array('ETH'); $where_configs .= ' AND net IN ("ETH")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'disk') $params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'iofilebuf') $params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'iofs') $params['iosfs'] = array('10'); $where_configs .= ' AND iosf IN ("10")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'comp') $params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'replication') $params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
			}

			$money		= Utils::read_params ( 'money', $where_configs, $configurations, $concat_config );
			$paramEval	= (isset($_GET['parameval']) && $_GET['parameval'] != '') ? $_GET['parameval'] : 'maps';
			$minExecs	= (isset($_GET['minexecs'])) ? $_GET['minexecs'] : -1;
			$minExecsFilter = "";

			if($minExecs > 0) $minExecsFilter = "HAVING COUNT(*) > $minExecs";
			
			$filter_execs = DBUtils::getFilterExecs();

			$options = Utils::getFilterOptions($db);
			$paramOptions = array();
			foreach($options[$paramEval] as $option)
			{
				if($paramEval == 'id_cluster') $paramOptions[] = $option['name'];
				else if($paramEval == 'comp') $paramOptions[] = Utils::getCompressionName($option[$paramEval]);
				else if($paramEval == 'net') $paramOptions[] = Utils::getNetworkName($option[$paramEval]);
				else if($paramEval == 'disk') $paramOptions[] = Utils::getDisksName($option[$paramEval]);
				else $paramOptions[] = $option[$paramEval];
			}

			$benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs WHERE 1 $filter_execs $where_configs GROUP BY $paramEval, bench order by $paramEval");
						
			// get the result rows
			$query = "SELECT count(*) as count, $paramEval, e.id_exec, exec as conf, bench, ".
				"exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
				"from execs e WHERE 1 $filter_execs $where_configs".
				"GROUP BY $paramEval, bench $minExecsFilter order by bench,$paramEval";
			$rows = $db->get_rows ( $query );
			if (!$rows) throw new \Exception ( "No results for query!" );
	
			$arrayBenchs = array();
			foreach ( $paramOptions as $param )
			{
				foreach($benchOptions as $bench)
				{
					$arrayBenchs[$bench['bench']][$param] = null;
					$arrayBenchs[$bench['bench']][$param]['y'] = 0;
					$arrayBenchs[$bench['bench']][$param]['count'] = 0;
				}
			}

			$series = array();
			$bench = '';
			foreach($rows as $row)
			{
				if($paramEval == 'comp') $row[$paramEval] = Utils::getCompressionName($row['comp']);
				else if($paramEval == 'id_cluster') $row[$paramEval] = Utils::getClusterName($row[$paramEval],$db);
				else if($paramEval == 'net') $row[$paramEval] = Utils::getNetworkName($row['net']);
				else if($paramEval == 'disk') $row[$paramEval] = Utils::getDisksName($row['disk']);
				else if($paramEval == 'iofilebuf') $row[$paramEval] /= 1024;
				
				$arrayBenchs[$row['bench']][$row[$paramEval]]['y'] = round((int)$row['avg_exe_time'],2);
				$arrayBenchs[$row['bench']][$row[$paramEval]]['count'] = (int)$row['count'];
			}				

			// ----------------------------------------------------
			// Add predictions to the series
			// ----------------------------------------------------

			$jsonData = $jsonHeader = "[]";
			$instance = "";
			$arrayBenchs_pred = array();

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);
			$instances = MLUtils::generateInstances($param_names, $params, true, $db);

			// model for filling
			$possible_models = $possible_models_id = array();
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $db);

			if (!empty($possible_models_id))
			{
				if ($current_model != "") $model = $current_model;
				else $current_model = $model = $possible_models_id[0];

				$cache_filename = getcwd().'/cache/query/'.md5($instance.'-'.$model).'-ipred.csv';
				$tmp_file = getcwd().'/cache/query/'.md5($instance.'-'.$model).'.tmp';

				$is_cached = file_exists($cache_filename);
				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$finished_process = $in_process && ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));
		
				if (!$is_cached && !$in_process && !$finished_process)
				{
					// drop query
					exec('cd '.getcwd().'/cache/query ; touch '.md5($instance.'-'.$model).'.lock; rm -f '.$tmp_file);
					foreach ($instances as $inst)
					{
						exec(getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query; ../../resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict=\''.$inst.'\' -v | grep -v \'Prediction\' >>'.$tmp_file.' 2>/dev/null; echo 1 >>'.md5($instance.'-'.$model).'.lock" >/dev/null 2>&1 &');
					}
				}

				$is_cached = file_exists($cache_filename);
				$finished_process = ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));

				if ($finished_process && !$is_cached)
				{
					// read results
					$lines = explode("\n", file_get_contents($tmp_file));
					$jsonData = '[';
					$i = 1;
					while($i < count($lines))
					{
						if ($lines[$i]=='') break;
						$parsed = preg_replace('/\s+/', ',', $lines[$i]);
						if ($jsonData!='[') $jsonData = $jsonData.',';
						$jsonData = $jsonData.'[\''.implode("','",explode(',',$parsed)).'\']';
						$i++;
					}
					$jsonData = $jsonData.']';

					$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Cl.Name','Datanodes','Headnodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Prediction'); #FIXME - Header hardcoded for file-tmp
					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					// save at cache
					file_put_contents($cache_filename, $jsonHeader."\n".$jsonData);

					// update cache record (for human reading)
					$register = md5($instance.'-'.$model).' : '.$instance."-".$model."\n";
					shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
					file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);

					// remove remaining locks and readies
					shell_exec('rm -f '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				}

				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$is_cached = file_exists($cache_filename);

				if ($in_process)
				{
					$jsonData = $jsonHeader = '[]';
					$must_wait = 'YES';
				}
				else
				{
					$must_wait = 'NO';
					if ($is_cached)
					{
						// get cache
						$data = explode("\n",file_get_contents($cache_filename));
						$jsonHeader = $data[0];
						$jsonData = $data[1];

						$header = explode("\"},{title:\"",substr($jsonHeader,9,-3));
						$header = array_splice($header,1);

						// Slice and Aggregate JSON data
						$sliced = explode('],[',substr($jsonData,2,-2));
						$position = -1;
						if($paramEval == 'maps') $position = array_search('Maps', $header); 
						else if($paramEval == 'comp') $position = array_search('Comp', $header);
						else if($paramEval == 'id_cluster') $position = array_search('Cluster', $header);
						else if($paramEval == 'net') $position = array_search('Net', $header);
						else if($paramEval == 'disk') $position = array_search('Disk', $header);
						else if($paramEval == 'replication') $position = array_search('Rep', $header);
						else if($paramEval == 'iofilebuf') $position = array_search('IO.FBuf', $header);
						else if($paramEval == 'blk_size') $position = array_search('Blk.Size', $header);
						else if($paramEval == 'iosf') $position = array_search('IO.SFS', $header);

						if ($position > -1)
						{
							foreach ($paramOptions as $param)
							{
								foreach($benchOptions as $bench)
								{
									$arrayBenchs_pred[$bench['bench'].'_pred'][$param] = null;
									$arrayBenchs_pred[$bench['bench'].'_pred'][$param]['y'] = 0;
									$arrayBenchs_pred[$bench['bench'].'_pred'][$param]['count'] = 0;
								}
							}

							foreach ($sliced as $slice)
							{
								$line = explode("','",substr($slice,1,-1));
								$line = array_splice($line,1);

								$class = $line[$position];
								$pred = $line[array_search('Prediction', $header)];
								$bench_n = $line[array_search('Benchmark', $header)].'_pred';

								if($paramEval == 'comp') $value = Utils::getCompressionName($class);
								else if($paramEval == 'id_cluster') $value = Utils::getClusterName($row[$paramEval],$db);
								else if($paramEval == 'net') $value = Utils::getNetworkName($class);
								else if($paramEval == 'disk') $value = Utils::getDisksName($class);
								else if($paramEval == 'iofilebuf') $value = $class / 1024;
								else $value = $class;

								if (!in_array($value,$paramOptions))
								{
									$paramOptions[] = $value;
									foreach($benchOptions as $bench)
									{
										$arrayBenchs_pred[$bench['bench'].'_pred'][$value] = null;
										$arrayBenchs_pred[$bench['bench'].'_pred'][$value]['y'] = 0;
										$arrayBenchs_pred[$bench['bench'].'_pred'][$value]['count'] = 0;
										$arrayBenchs[$bench['bench']][$value] = null;
										$arrayBenchs[$bench['bench']][$value]['y'] = 0;
										$arrayBenchs[$bench['bench']][$value]['count'] = 0;
									}
								}

								$prev_y = $arrayBenchs_pred[$bench_n][$value]['y'];
								$prev_count = $arrayBenchs_pred[$bench_n][$value]['count'];

								$arrayBenchs_pred[$bench_n][$value]['y'] = (($prev_y * $prev_count) + round((int)$pred,2)) / ($prev_count + 1);
								$arrayBenchs_pred[$bench_n][$value]['count'] = $prev_count + 1;
							}
						}
					}
				}
			}
			// ----------------------------------------------------
			// END - Add predictions to the series
			// ----------------------------------------------------

			asort($paramOptions);

			foreach ($arrayBenchs as $key => $arrayBench)
			{
				$caregories = '';
				$data_a = null;
				$data_p = null;
				foreach ($paramOptions as $param)
				{
					if (($arrayBenchs[$key][$param]['count'] > 0 && empty($arrayBenchs_pred)) || (!empty($arrayBenchs_pred) && ( $arrayBenchs_pred[$key.'_pred'][$param]['count'] > 0 || $arrayBenchs[$key][$param]['count'] > 0)))
					{
						$data_a[] = $arrayBenchs[$key][$param];
						if (!empty($arrayBenchs_pred)) $data_p[] = $arrayBenchs_pred[$key.'_pred'][$param];
						$categories = $categories."'$param ".Utils::getParamevalUnit($paramEval)."',"; // FIXME - Redundant n times performed... don't care now
					}
				}
				$series[] = array('name' => $key, 'data' => $data_a);
				if (!empty($arrayBenchs_pred)) $series[] = array('name' => $key.'_pred', 'data' => $data_p);
			}
			$series = json_encode($series);

			if (!empty($arrayBenchs_pred)) $colors = "['#7cb5ec','#9cd5fc','#434348','#636368','#90ed7d','#b0fd9d','#f7a35c','#f7c37c','#8085e9','#a0a5f9','#f15c80','#f17ca0','#e4d354','#f4f374','#8085e8','#a0a5f8','#8d4653','#ad6673','#91e8e1','#b1f8f1']";
			else $colors = "['#7cb5ec','#434348','#90ed7d','#f7a35c','#8085e9','#f15c80','#e4d354','#8085e8','#8d4653','#91e8e1']";

		} catch ( \Exception $e ) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );

			$series = $jsonHeader = $colors = '[]';
			$instance = $current_model = '';
			$possible_models = $possible_models_id = array();
			$must_wait = 'NO';
		}
		echo $this->container->getTwig ()->render ('mltemplate/mlconfigperf.html.twig', array (
				'selected' => 'mlparameval',
				'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
				'categories' => $categories,
				'series' => $series,
				'benchs' => $params['benchs'],
				'nets' => $params['nets'],
				'disks' => $params['disks'],
				'blk_sizes' => $params['blk_sizes'],
				'comps' => $params['comps'],
				'id_clusters' => $params['id_clusters'],
				'mapss' => $params['mapss'],
				'replications' => $params['replications'],
				'iosfs' => $params['iosfs'],
				'iofilebufs' => $params['iofilebufs'],
				'money' => $money,
				'paramEval' => $paramEval,
				'instance' => $instance,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => '[\''.implode("','",$possible_models_id).'\']',
				'current_model' => $current_model,
				'gammacolors' => $colors,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
		) );
	}
}
?>
