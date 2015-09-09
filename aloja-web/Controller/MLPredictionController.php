<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLPredictionController extends AbstractController
{
	public function mlpredictionAction()
	{
		$jsonExecs = array();
		$instance = $error_stats = '';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			if (array_key_exists('dump',$_GET))
			{
				$dump = $_GET["dump"];
				unset($_GET["dump"]);
			}

			if (array_key_exists('pass',$_GET))
			{
				$pass = $_GET["pass"];
				unset($_GET["pass"]);
			}

			$this->buildFilters(array('learn' => array(
				'type' => 'selectOne',
				'default' => array('regtree'),
				'label' => 'Learning method: ',
				'generateChoices' => function() {
					return array('regtree','nneighbours','nnet','polyreg');
				},
				'beautifier' => function($value) {
					$labels = array('regtree' => 'Regression Tree','nneighbours' => 'k-NN',
						'nnet' => 'NNets','polyreg' => 'PolyReg-3');
					return $labels[$value];
				},
				'parseFunction' => function() {
					$choice = isset($_GET['learn']) ? $_GET['learn'] : array('regtree');
					return array('whereClause' => '', 'currentChoice' => $choice);
				},
				'filterGroup' => 'MLearning'
			), 'umodel' => array(
				'type' => 'checkbox',
				'default' => 1,
				'label' => 'Unrestricted to new values',
				'parseFunction' => function() {
					$choice = (isset($_GET['submit']) && !isset($_GET['umodel'])) ? 0 : 1;
					return array('whereClause' => '', 'currentChoice' => $choice);
				},
				'filterGroup' => 'MLearning')
			));

			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('learn','umodel'))));

			$where_configs = $this->filters->getWhereClause();

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$learnParams = $this->filters->getFiltersSelectedChoices(array('learn','umodel'));
			$learn_param = $learnParams['learn'];
			$unrestricted = ($learnParams['umodel']) ? true : false;

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, $unrestricted);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, $unrestricted);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$learn_param.' '.(($unrestricted)?'U':'R').' '.$slice_info;
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'.fin');

			if (!$is_cached && !$in_process && !$finished_process)
			{
				// get headers for csv
				$header_names = array(
					'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster',
					'datanodes' => 'Datanodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size',
					'type' => 'Type','bench_type' => 'Bench.Type','hadoop_version'=>'Hadoop.Version'
				);
				$headers = array_keys($header_names);
				$names = array_values($header_names);

			    	// dump the result to csv
			    	$query = "SELECT ".implode(",",$headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp, $names,',','"');
			    	foreach($rows as $row)
				{
					$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
					fputcsv($fp, array_values($row),',','"');
				}

				// run the R processor
				exec('cd '.getcwd().'/cache/query ; touch '.getcwd().'/cache/query/'.md5($config).'.lock');
				exec('cd '.getcwd().'/cache/query ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null 2>&1; rm -f '.getcwd().'/cache/query/'.md5($config).'.lock; touch '.md5($config).'.fin" > /dev/null 2>&1 -p 1 &');
			}

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'.fin');

			if ($in_process)
			{
				$jsonExecs = "[]";
				$must_wait = "YES";
				$max_x = $max_y = 0;
				if (isset($dump)) { echo "1"; exit(0); }
				if (isset($pass)) { return 1; }
			}
			else
			{
				$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
				$tmp_result = $is_cached_mysql->fetch();
				$is_cached = ($tmp_result['num'] > 0);

				if (!$is_cached) 
				{
					// register model to DB
					$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice)";
					$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."');";

					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

					// read results of the CSV and dump to DB
					foreach (array("tt", "tv", "tr") as $value)
					{
						if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv', 'r')) !== FALSE)
						{
							$header = fgetcsv($handle, 1000, ",");

							$token = 0; $insertions = 0;
							$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,datanodes,vm_OS,vm_cores,vm_RAM,provider,vm_size,type,bench_type,hadoop_version,pred_time,id_learner,instance,predict_code) VALUES ";
							while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
							{
								$specific_instance = implode(",",array_slice($data, 2, 21));
								$specific_data = implode(",",$data);
								$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
								$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
								$specific_data = str_replace(",","','",$specific_data);

								$query_var = "SELECT count(*) as num FROM aloja_ml.predictions WHERE instance = '".$specific_instance."' AND id_learner = '".md5($config)."'";
								$result = $dbml->query($query_var);
								$row = $result->fetch();
						
								// Insert instance values
								if ($row['num'] == 0)
								{
									if ($token != 0) { $query = $query.","; } $token = 1; $insertions = 1;
									$query = $query."('".$specific_data."','".md5($config)."','".$specific_instance."','".(($value=='tt')?3:(($value=='tv')?2:1))."') ";								
								}
							}

							if ($insertions > 0)
							{
								if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
							}
							fclose($handle);
						}
					}

					// Store file model to DB
					$filemodel = getcwd().'/cache/query/'.md5($config).'-object.rds';
					$fp = fopen($filemodel, 'r');
					$content = fread($fp, filesize($filemodel));
					$content = addslashes($content);
					fclose($fp);

					$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config)."','learner','".$content."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

					// Remove temporal files
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.csv');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.fin');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.dat');
				}

				$must_wait = "NO";
				$count = 0;
				$max_x = $max_y = 0;
				$error_stats = '';

				$query = "SELECT exe_time, pred_time, instance FROM aloja_ml.predictions WHERE id_learner='".md5($config)."' AND exe_time > 100 LIMIT 5000"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LIMIT WHEN THE BUG IS SOLVED
				$result = $dbml->query($query);
				foreach ($result as $row)
				{
					$jsonExecs[$count]['y'] = (int)$row['exe_time'];
					$jsonExecs[$count]['x'] = (int)$row['pred_time'];
					$jsonExecs[$count]['mydata'] = $row['instance'];

					if ((int)$row['exe_time'] > $max_y) $max_y = (int)$row['exe_time'];
					if ((int)$row['pred_time'] > $max_x) $max_x = (int)$row['pred_time'];
					$count++;
				}

				$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, predict_code FROM aloja_ml.predictions WHERE id_learner='".md5($config)."' AND predict_code > 0 AND exe_time > 100 GROUP BY predict_code";
				$result = $dbml->query($query);
				foreach ($result as $row)
				{
					$error_stats = $error_stats.'Dataset: '.(($row['predict_code']==1)?'tr':(($row['predict_code']==2)?'tv':'tt')).' => MAE: '.$row['MAE'].' RAE: '.$row['RAE'].'<br/>';
				}

				if (isset($dump))
				{
					$data = json_encode($jsonExecs);
					echo "Observed, Predicted, Execution\n";
					echo str_replace(array('},{"y":','"x":','"mydata":','[{"y":','"}]'),array("\n",'','','',''),$data);
					exit(0);
				}
				if (isset($pass))
				{
					$data = json_encode($jsonExecs);
					$retval = "Observed, Predicted, Execution\n";
					$retval = $retval.str_replace(array('},{"y":','"x":','"mydata":','[{"y":','"}]'),array("\n",'','','',''),$data);
					return $retval;
				}
			}
			$dbml = null;
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonExecs = '[]';
			$max_x = $max_y = 0;
			$must_wait = 'NO';
			$dbml = null;
		}

		$return_params = array(
			'jsonExecs' => json_encode($jsonExecs),
			'max_p' => min(array($max_x,$max_y)),
			'unrestricted' => $unrestricted,
			'learn' => $learn_param,
			'must_wait' => $must_wait,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'id_learner' => md5($config),
			'error_stats' => $error_stats,
		);
		return $this->render('mltemplate/mlprediction.html.twig', $return_params);
	}
}
?>
