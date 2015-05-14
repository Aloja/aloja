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
		$rows = $categories = $series = '';
		$must_wait = 'NO';
		try {
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			$configurations = array ();	// Useless here
			$where_configs = '';
			$concat_config = ""; 		// Useless here
			
			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters','datanodess','bench_types','vm_sizes','vm_coress','vm_RAMs','types'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('parameval',$_GET))
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$params['benchs'] = $_GET['benchs'] = array('terasort'); $where_configs = ' AND bench IN ("terasort")';
				//if (!isset($_GET['parameval']) || $_GET['parameval'] != 'net') $params['nets'] = $_GET['nets'] = array('ETH'); $where_configs .= ' AND net IN ("ETH")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'disk') $params['disks'] = $_GET['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'iofilebuf') $params['iofilebufs'] = $_GET['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				//if (!isset($_GET['parameval']) || $_GET['parameval'] != 'iofs') $params['iosfs'] = $_GET['iosfs'] = array('10'); $where_configs .= ' AND iosf IN ("10")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'comp') $params['comps'] = $_GET['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				if (!isset($_GET['parameval']) || $_GET['parameval'] != 'replication') $params['replications'] = $_GET['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				//if (!isset($_GET['parameval']) || $_GET['parameval'] != 'id_cluster') $params['id_clusters'] = $_GET['id_clusters'] = array('1','2','3'); $where_configs .= ' AND id_cluster IN ("1","2","3")';
			}

			$money		= Utils::read_params ( 'money', $where_configs, $configurations, $concat_config );
			$paramEval	= (isset($_GET['parameval']) && $_GET['parameval'] != '') ? $_GET['parameval'] : 'maps';
			$minExecs	= (isset($_GET['minexecs'])) ? $_GET['minexecs'] : -1;
			$minExecsFilter = "";

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("`id_cluster`","e.`id_cluster`",$where_configs);

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

			$benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE 1 $filter_execs $where_configs GROUP BY $paramEval, bench order by $paramEval");
						
			// get the result rows
			$query = "SELECT count(*) as count, $paramEval, e.id_exec, exec as conf, bench, ".
				"exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
				"from execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE 1 $filter_execs $where_configs".
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

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("AND .","AND ",$where_configs);

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);
			$instances = MLUtils::generateInstances($param_names, $params, true, $db);

			// model for filling
			$possible_models = $possible_models_id = array();
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			if (!empty($possible_models_id))
			{
				if ($current_model == "")
				{
					$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, p.id_learner FROM predictions p, learners l WHERE l.id_learner = p.id_learner AND p.id_learner IN ('".implode("','",$possible_models_id)."') AND predict_code > 0 ORDER BY MAE LIMIT 1";
					$result = $dbml->query($query);
					$row = $result->fetch();	
					$current_model = $row['id_learner'];
				}
				$config = $instance.'-'.$current_model."-parameval";

				$query_cache = "SELECT count(*) as total FROM trees WHERE id_learner = '".$current_model."' AND model = '".$model_info."'";
				$is_cached_mysql = $dbml->query($query_cache);
				$tmp_result = $is_cached_mysql->fetch();
				$is_cached = ($tmp_result['total'] > 0);

				$ret_data = null;
				if (!$is_cached)
				{
					// Call to MLFindAttributes, to fetch data
					$_GET['pass'] = 2;
					$_GET['unseen'] = 1;
					$_GET['current_model'] = $current_model;
					$mlfa1 = new MLFindAttributesController();
					$mlfa1->container = $this->container;
					$ret_data = $mlfa1->mlfindattributesAction();

					if ($ret_data == 1) // In Process
					{
						$must_wait = "YES";
						$jsonData = $jsonHeader = '[]';
					}
					else
					{
						$is_cached_mysql = $dbml->query($query_cache);
						$tmp_result = $is_cached_mysql->fetch();
						$is_cached = ($tmp_result['total'] > 0);
					}
				}

				if ($is_cached)
				{
					$must_wait = 'NO';

					$query = "SELECT count(*) as count, $paramEval, bench, exe_time, avg(pred_time) avg_pred_time, min(pred_time) min_pred_time ".
						"FROM predictions p WHERE p.id_learner = '".$current_model."' $filter_execs $where_configs".
						"GROUP BY $paramEval, bench $minExecsFilter order by bench, $paramEval";
					$result = $dbml->query($query);
					
					// Initialize array
					foreach ($paramOptions as $param)
					{
						foreach($benchOptions as $bench)
						{
							$arrayBenchs_pred[$bench['bench'].'_pred'][$param] = null;
							$arrayBenchs_pred[$bench['bench'].'_pred'][$param]['y'] = 0;
							$arrayBenchs_pred[$bench['bench'].'_pred'][$param]['count'] = 0;
						}
					}

					foreach ($result as $row)
					{
						$bench_n = $row['bench'].'_pred';
						$class = $row[$paramEval];

						if($paramEval == 'comp') $value = Utils::getCompressionName($class);
						else if($paramEval == 'id_cluster') $value = Utils::getClusterName($class,$db);
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

						$arrayBenchs_pred[$bench_n][$value]['y'] = (int)$row['avg_pred_time'];
						$arrayBenchs_pred[$bench_n][$value]['count'] = (int)$row['count'];
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
				'datanodess' => $params['datanodess'],
				'bench_types' => $params['bench_types'],
				'vm_sizes' => $params['vm_sizes'],
				'vm_coress' => $params['vm_coress'],
				'vm_RAMs' => $params['vm_RAMs'],
				'types' => $params['types'],
				'money' => $money,
				'paramEval' => $paramEval,
				'instance' => $instance,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => $possible_models_id,
				'current_model' => $current_model,
				'gammacolors' => $colors,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
		) );
	}
}
?>
