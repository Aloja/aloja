<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLParamevalController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function mlparamEvaluationAction()
	{
		$rows = $categories = $series = $instance = $model_info = $config = $current_model = $slice_info = '';
		$arrayBenchs_pred = $possible_models = $possible_models_id = $other_models = array();
		$jsonData = $jsonHeader = "[]";
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			if (array_key_exists('parameval',$_GET))
			{
				$paramEval = (isset($_GET['parameval']) && Utils::get_GET_string('parameval') != '') ? Utils::get_GET_string('parameval') : 'maps';
				unset($_GET["parameval"]);
			}

			$this->buildFilters(array(
				'current_model' => array(
					'type' => 'selectOne',
					'default' => null,
					'label' => 'Model tu use: ',
					'generateChoices' => function() {
						return array();
					},
					'parseFunction' => function() {
						$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning'
				), 'minExecs' => array('default' => 0, 'type' => 'inputNumber', 'label' => 'Minimum executions:',
					'parseFunction' => function() { return 0; },
					'filterGroup' => 'basic'
				), 'minexetime' => array(
					'default' => 0
				), 'valid' => array(
					'default' => 0
				), 'filter' => array(
					'default' => 0
				), 'prepares' => array(
					'default' => 0
				)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model'))));

			$where_configs = $this->filters->getWhereClause();

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$param_variables = $this->filters->getFiltersSelectedChoices(array('current_model','minExecs'));
			$param_current_model = $param_variables['current_model'];
			$minExecs = $param_variables['minExecs'];

			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);

			$minExecsFilter = "";
			if ($minExecs > 0) $minExecsFilter = "HAVING COUNT(*) > $minExecs";
			
			$filter_execs = DBUtils::getFilterExecs();

			$options = $this->filters->getFilterChoices();
			$paramOptions = array();
			foreach($options[$paramEval] as $option)
			{
				if ($paramEval == 'comp') $paramOptions[] = Utils::getCompressionName($option);
				else if ($paramEval == 'net') $paramOptions[] = Utils::getNetworkName($option);
				else if ($paramEval == 'disk') $paramOptions[] = Utils::getDisksName($option);
				else $paramOptions[] = $option;
			}

			$param_eval_query = ($paramEval == 'id_cluster')? 'e.id_cluster' : $paramEval;

			$benchOptions = $db->get_rows("SELECT DISTINCT bench FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE 1 $filter_execs $where_configs GROUP BY $param_eval_query, bench order by $param_eval_query");

			// get the result rows
			$query = "SELECT count(*) as count, $param_eval_query, e.id_exec, exec as conf, bench, ".
				"exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
				"from aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE 1 $filter_execs $where_configs".
				"GROUP BY $param_eval_query,bench $minExecsFilter order by bench,$param_eval_query";
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
				else if($paramEval == 'net') $row[$paramEval] = Utils::getNetworkName($row['net']);
				else if($paramEval == 'disk') $row[$paramEval] = Utils::getDisksName($row['disk']);
				else if($paramEval == 'iofilebuf') $row[$paramEval] /= 1024;
				
				$arrayBenchs[$row['bench']][$row[$paramEval]]['y'] = round((int)$row['avg_exe_time'],2);
				$arrayBenchs[$row['bench']][$row[$paramEval]]['count'] = (int)$row['count'];
			}				

			// ----------------------------------------------------
			// Add predictions to the series
			// ----------------------------------------------------

			$param_variables = $this->filters->getFiltersSelectedChoices(array('current_model'));
			$param_current_model = $param_variables['current_model'];

			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			// model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);
			$current_model = '';
			if (!is_null($possible_models_id) && in_array($param_current_model,$possible_models_id)) $current_model = $param_current_model;

			// Other models for filling
			$where_models = '';
			if (!empty($possible_models_id))
			{
				$where_models = " WHERE id_learner NOT IN ('".implode("','",$possible_models_id)."')";
			}
			$result = $dbml->query("SELECT id_learner FROM aloja_ml.learners".$where_models);
			foreach ($result as $row) $other_models[] = $row['id_learner'];

			if (!empty($possible_models_id))
			{
				if ($current_model == "")
				{
					$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, p.id_learner FROM aloja_ml.predictions p, aloja_ml.learners l WHERE l.id_learner = p.id_learner AND p.id_learner IN ('".implode("','",$possible_models_id)."') AND predict_code > 0 ORDER BY MAE LIMIT 1";
					$result = $dbml->query($query);
					$row = $result->fetch();	
					$current_model = $row['id_learner'];
				}
				$config = $instance.'-'.$current_model.' '.$slice_info."-parameval";

				$query_cache = "SELECT count(*) as total FROM aloja_ml.trees WHERE id_learner = '".$current_model."' AND model = '".$model_info."'";
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

					$query = "SELECT count(*) as count, $param_eval_query, bench, exe_time, avg(pred_time) avg_pred_time, min(pred_time) min_pred_time ".
						"FROM aloja_ml.predictions e WHERE e.id_learner = '".$current_model."' $filter_execs $where_configs".
						"GROUP BY $param_eval_query, bench $minExecsFilter order by bench,$param_eval_query";
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

		}
		catch ( \Exception $e )
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$series = $jsonHeader = $colors = '[]';
			$must_wait = 'NO';
		}
		$return_params = array(
			'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
			'categories' => $categories,
			'series' => $series,
			'paramEval' => $paramEval,
			'instance' => $instance,
			'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
			'models_id' => $possible_models_id,
			'current_model' => $current_model,
			'gammacolors' => $colors,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'must_wait' => $must_wait,
		);
		$this->filters->setCurrentChoices('current_model',array_merge($possible_models_id,array('---Other models---'),$other_models));
		return $this->render('mltemplate/mlparameval.html.twig', $return_params);
	}
}
?>
