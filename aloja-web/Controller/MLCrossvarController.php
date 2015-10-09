<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLCrossvarController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function mlcrossvarAction()
	{
		$jsonData = array();
		$instance = $cross_var1 = $cross_var2 = '';
		$categories1 = $categories2 = "''";
		$must_wait = 'NO';
		try
		{
			$db = $this->container->getDBUtils();
		    	
			$learn = 'regtree';
			if (array_key_exists('learn',$_GET))
			{
				$learn = $_GET["learn"];
				unset($_GET["learn"]);
			}

			$this->buildFilters(array(
				'variable2' => array(
					'type' => 'selectOne', 'default' => array('exe_time'), 'table' => 'execs',
					'label' => 'Variable 2: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS','FAILED_MAPS',
							'TOTAL_REDUCES','FAILED_REDUCES','FILE_BYTES_WRITTEN','FILE_BYTES_READ',
							'HDFS_BYTES_WRITTEN','HDFS_BYTES_READ');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Execution time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps',
							'FAILED_MAPS' => 'Failed execution maps',
							'TOTAL_REDUCES' => 'Total execution reduces','FAILED_REDUCES' => 'Failed reduces',
							'FILE_BYTES_WRITTEN' => 'File bytes written','FILE_BYTES_READ' => 'File bytes read',
							'HDFS_BYTES_WRITTEN' => 'HDFS Bytes Written','HDFS_BYTES_READ' => 'HDFS Bytes read');

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable2']) ? $_GET['variable2'] : 'exe_time';
						return array('currentChoice' => $value, 'whereClause' => "");
					},
					'htmlAttributes' => array('onchange="varchange()"','id="crossvar2"')
				),
				'variable1' => array(
					'type' => 'selectOne', 'default' => array('maps'), 'table' => 'execs',
					'label' => 'Variable 1: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS','FAILED_MAPS',
							'TOTAL_REDUCES','FAILED_REDUCES','FILE_BYTES_WRITTEN','FILE_BYTES_READ',
							'HDFS_BYTES_WRITTEN','HDFS_BYTES_READ');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Execution time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps',
							'FAILED_MAPS' => 'Failed execution maps',
							'TOTAL_REDUCES' => 'Total execution reduces','FAILED_REDUCES' => 'Failed reduces',
							'FILE_BYTES_WRITTEN' => 'File bytes written','FILE_BYTES_READ' => 'File bytes read',
							'HDFS_BYTES_WRITTEN' => 'HDFS Bytes Written','HDFS_BYTES_READ' => 'HDFS Bytes read');

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable1']) ? $_GET['variable1'] : 'maps';
						return array('currentChoice' => $value, 'whereClause' => "");
					},
					'htmlAttributes' => array('onchange="varchange()"','id="crossvar1"')
				), 'valid' => array(
					'default' => 0
				), 'filter' => array(
					'default' => 0
				), 'prepares' => array(
					'default' => 1
				), 'current_model' => array(
					'type' => 'selectOne',
					'default' => null,
					'label' => 'Reference Model: ',
					'generateChoices' => function() {
						$query = "SELECT DISTINCT id_learner FROM aloja_ml.predictions";
						$db = $this->container->getDBUtils();
						$retval = $db->get_rows ($query);
						return array_column($retval,"id_learner");
					},
					'parseFunction' => function() {
						$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning',
					'htmlAttributes' => array('id="selectcurrentmodel"','title="Only enabled for \'Prediction Time\' variable without \'Use all models\'"')
				),
				'umods' => array(
					'type' => 'checkbox',
					'default' => 1,
					'label' => 'Use data from all models',
					'parseFunction' => function() {
						$choice = (!isset($_GET['umods'])) ? 0 : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning',
					'htmlAttributes' => array('id="checkumods"','onchange="selectmod_enabler()"','title="Only enabled for \'Prediction Time\' variable"')
				)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','umods'))));
			$where_configs = $this->filters->getWhereClause();

			$model_html = '';
			$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
			foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$variables = $this->filters->getFiltersSelectedChoices(array('variable1','variable2','current_model','umods'));
			$cross_var1 = $variables['variable1'];
			$cross_var2 = $variables['variable2'];
			$current_model = $variables['current_model'];
			$param_allmodels = $variables['umods'];

			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$cross_var1 = str_replace("id_cluster","e.id_cluster",$cross_var1);
			$cross_var2 = str_replace("id_cluster","e.id_cluster",$cross_var2);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			// Get stuff from the DB
			$rows = null;
			if ($cross_var1 != 'pred_time' && $cross_var2 != 'pred_time')
			{
				$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2
					FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster LEFT JOIN aloja2.JOB_details j ON e.id_exec = j.id_exec
					WHERE hadoop_version IS NOT NULL".$where_configs."
					ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}
			else
			{
/*				if ($param_allmodels == 0)
				{
					//TODO - The data-slice should be predicted with the selected model, the stored, and then recovered

					// Call to MLPrediction, to fetch/learn model
					$_GET['pass'] = 1;
					$_GET["learn"] = $learn;
					$mltc1 = new MLPredictionController();
					$mltc1->container = $this->container;
					$ret_learn = $mltc1->mlpredictionAction();

					if ($ret_learn == 1)
					{
						$must_wait = "YES";
						throw new \Exception("WAIT");
					}
					else if ($ret_learn == -1)
					{
						throw new \Exception("There was an error when creating a model for [".$instance."]");
					}
				}
*/
				$other_var = $cross_var1;
				if ($cross_var1 == 'pred_time') { $other_var = $cross_var2; $var1 = 'p.pred_time'; $var2 = 's.'.$cross_var2; }
				else { $var1 = 's.'.$cross_var1; $var2 = 'p.'.$cross_var2; }
				$other_var = str_replace("id_cluster","e.id_cluster",$other_var);

				$where_configsML = ($param_allmodels == 0)?"WHERE p.id_learner = '".$current_model."'":'';

				$query="SELECT ".$var1." as V1, ".$var2." as V2
					FROM (	SELECT ".$other_var.", e.id_exec
						FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster LEFT JOIN aloja2.JOB_details j ON e.id_exec = j.id_exec
						WHERE hadoop_version IS NOT NULL".$where_configs."
					) AS s LEFT JOIN aloja_ml.predictions AS p ON s.id_exec = p.id_exec ".$where_configsML."
					ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
		  	  	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}

			// Show results
			$map_var1 = $map_var2 = array();
			$count_var1 = $count_var2 = 0;
			$categories1 = $categories2 = '';

			$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));
			$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));

			foreach ($rows as $row)
			{
				$entry = array();

				if ($var1_categorical)
				{
					if (!array_key_exists($row['V1'],$map_var1))
					{
						$map_var1[$row['V1']] = $count_var1++;
						$categories1 = $categories1.(($categories1!='')?",":"")."\"".$row['V1']."\"";
					}
					$entry['y'] = $map_var1[$row['V1']]*(rand(990,1010)/1000);
				}
				else $entry['y'] = (int)$row['V1']*(rand(990,1010)/1000);

				if ($var2_categorical)
				{
					if (!array_key_exists($row['V2'],$map_var2))
					{
						$map_var2[$row['V2']] = $count_var2++;
						$categories2 = $categories2.(($categories2!='')?",":"")."\"".$row['V2']."\"";
					}
					$entry['x'] = $map_var2[$row['V2']]*(rand(990,1010)/1000);
				}
				else $entry['x'] = (int)$row['V2']*(rand(990,1010)/1000);

				$entry['name'] = $row['V1']." - ".$row['V2'];
				$jsonData[] = $entry;
			}

			$jsonData = json_encode($jsonData);
			if ($categories1 != '') $categories1 = "[".$categories1."]"; else $categories1 = "''";
			if ($categories2 != '') $categories2 = "[".$categories2."]"; else $categories2 = "''";
		}
		catch(\Exception $e)
		{
			//if ($e->getMessage () != "WAIT")
			//{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			//}
			$jsonData = '[]';
		}
		$return_params = array(
			'jsonData' => $jsonData,
			'variable1' => str_replace("e.id_cluster","id_cluster",$cross_var1),
			'variable2' => str_replace("e.id_cluster","id_cluster",$cross_var2),
			'categories1' => $categories1,
			'categories2' => $categories2,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'must_wait' => $must_wait,
			'models' => $model_html
		);
		return $this->render('mltemplate/mlcrossvar.html.twig', $return_params);
	}

	public function mlcrossvar3dAction()
	{
		$jsonData = array();
		$cross_var1 = $cross_var2 = $instance = '';
		$categories1 = $categories2 = "''";
		$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	
			$this->buildFilters(array(
				'variable2' => array(
					'type' => 'selectOne', 'default' => array('net'), 'table' => 'execs',
					'label' => 'Variable 2: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Execution time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps');

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable2']) ? $_GET['variable2'] : 'exe_time';
						return array('currentChoice' => $value, 'whereClause' => "");
					},
					'htmlAttributes' => array('onchange="varchange()"','id="crossvar2"')
				),
				'variable1' => array(
					'type' => 'selectOne', 'default' => array('maps'), 'table' => 'execs',
					'label' => 'Variable 1: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Exeuction time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps',
						);

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable1']) ? $_GET['variable1'] : 'maps';
						return array('currentChoice' => $value, 'whereClause' => "");
					},
					'htmlAttributes' => array('onchange="varchange()"','id="crossvar1"')
				), 'valid' => array(
					'default' => 0
				), 'filter' => array(
					'default' => 0
				), 'prepares' => array(
					'default' => 1
				), 'current_model' => array(
					'type' => 'selectOne',
					'default' => null,
					'label' => 'Reference Model: ',
					'generateChoices' => function() {
						$query = "SELECT DISTINCT id_learner FROM aloja_ml.predictions";
						$db = $this->container->getDBUtils();
						$retval = $db->get_rows ($query);
						return array_column($retval,"id_learner");
					},
					'parseFunction' => function() {
						$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning',
					'htmlAttributes' => array('id="selectcurrentmodel"','title="Only enabled for \'Prediction Time\' variable without \'Use all models\', or with \'Use predictions instead of observations\'"')
				),
				'umods' => array(
					'type' => 'checkbox',
					'default' => 1,
					'label' => 'Use data from all models',
					'parseFunction' => function() {
						$choice = (!isset($_GET['umods'])) ? 0 : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning',
					'htmlAttributes' => array('id="checkumods"','onchange="selectmod_enabler()"','title="Only enabled for \'Prediction Time\' variable"')
				),
				'upred' => array(
					'type' => 'checkbox',
					'default' => 0,
					'label' => 'Use predictions instead of observations',
					'parseFunction' => function() {
						$choice = (!isset($_GET['upred'])) ? 0 : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning',
					'htmlAttributes' => array('id="checkupred"','onchange="selectmod_enabler()"')
				)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','umods','upred'))));
			$where_configs = $this->filters->getWhereClause();

			$model_html = '';
			$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
			foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$variables = $this->filters->getFiltersSelectedChoices(array('variable1','variable2','current_model','upred','umods'));
			$cross_var1 = $variables['variable1'];
			$cross_var2 = $variables['variable2'];
			$current_model = $variables['current_model'];
			$param_predict = $variables['upred'];
			$param_allmodels = $variables['umods'];

			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$cross_var1 = str_replace("id_cluster","e.id_cluster",$cross_var1);
			$cross_var2 = str_replace("id_cluster","e.id_cluster",$cross_var2);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			// Exceptions
			if (($cross_var1 == 'pred_time' || $cross_var2 == 'pred_time') && $param_predict == 1) throw new \Exception("Error: A Variable can't be 'Predicted Time' if 3D Variable is also 'Predicted Time'");
			if (($cross_var1 == 'exe_time' || $cross_var2 == 'exe_time') && $param_predict == 0) throw new \Exception("Error: A Variable can't be 'Execution Time' if 3D Variable is also 'Execution Time'");
			if ($cross_var1 == $cross_var2) throw new \Exception("Error: Variable 1 and Variable 2 are the same");

			// Get stuff from the DB
			$rows = null;
			if ($cross_var1 != 'pred_time' && $cross_var2 != 'pred_time')
			{
				if ($param_predict == 1)
				{
					$whereClauseML = str_replace("exe_time","pred_time",$where_configs);
					$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
					$query="SELECT ".$cross_var1." AS V1, ".$cross_var2." AS V2, AVG(p.pred_time) as V3, p.instance
						FROM aloja_ml.predictions as p
						WHERE p.id_learner ='".$current_model."' ".$whereClauseML."
						GROUP BY p.instance
						ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
				}
				else
				{
					$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2, exe_time as V3
						FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster LEFT JOIN aloja2.JOB_details j ON e.id_exec = j.id_exec
						WHERE hadoop_version IS NOT NULL".$where_configs."
						ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
				}
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}
			else
			{
/*				if ($param_allmodels == 0)
				{
					//TODO - The data-slice should be predicted with the selected model, the stored, and then recovered

					// Call to MLTemplates, to fetch/learn model
					$_GET['pass'] = 1;
					$_GET["current_model"] = $current_model;
					$mltc1 = new MLPredictionController();
					$mltc1->container = $this->container;
					$ret_learn = $mltc1->mlpredictionAction();

					if ($ret_learn == 1)
					{
						$must_wait = "YES";
						throw new \Exception("WAIT");
					}
					else if ($ret_learn == -1)
					{
						throw new \Exception("There was an error when creating a model for [".$instance."]");
					}
				}
*/
				$other_var = $cross_var1;
				if ($cross_var1 == 'pred_time') { $other_var = $cross_var2; $var1 = 'p.pred_time'; $var2 = 's.'.$cross_var2; }
				else { $var1 = 's.'.$cross_var1; $var2 = 'p.pred_time'; }
				$other_var = str_replace("id_cluster","e.id_cluster",$other_var);

				$where_configsML = ($param_allmodels == 0)?"WHERE p.id_learner = '".$current_model."'":'';

				$query="SELECT ".$var1." as V1, ".$var2." as V2, exe_time as V3
					FROM (	SELECT ".$other_var.", e.id_exec
						FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster LEFT JOIN aloja2.JOB_details j ON e.id_exec = j.id_exec
						WHERE hadoop_version IS NOT NULL".$where_configs."
					) AS s LEFT JOIN aloja_ml.predictions AS p ON s.id_exec = p.id_exec ".$where_configsML."
					ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
		  	  	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}

			// Show the results
			$map_var1 = $map_var2 = array();
			$count_var1 = $count_var2 = 0;
			$categories1 = $categories2 = '';

			$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));
			$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));

			foreach ($rows as $row)
			{
				$entry = array();

				if ($var1_categorical)
				{
					if (!array_key_exists($row['V1'],$map_var1))
					{
						$map_var1[$row['V1']] = $count_var1++;
						$categories1 = $categories1.(($categories1!='')?",":"")."\"".$row['V1']."\"";
					}
					$entry['y'] = $map_var1[$row['V1']]*(rand(990,1010)/1000);
				}
				else $entry['y'] = (int)$row['V1']*(rand(990,1010)/1000);
				if ($entry['y'] > $maxy) $maxy = $entry['y'];
				if ($entry['y'] < $miny) $miny = $entry['y'];

				if ($var2_categorical)
				{
					if (!array_key_exists($row['V2'],$map_var2))
					{
						$map_var2[$row['V2']] = $count_var2++;
						$categories2 = $categories2.(($categories2!='')?",":"")."\"".$row['V2']."\"";
					}
					$entry['x'] = $map_var2[$row['V2']]*(rand(990,1010)/1000);
				}
				else $entry['x'] = (int)$row['V2']*(rand(990,1010)/1000);
				if ($entry['x'] > $maxx) $maxx = $entry['x'];
				if ($entry['x'] < $minx) $minx = $entry['x'];

				$entry['z'] = max(100,(int)$row['V3']*(rand(990,1010)/1000));
				if ($entry['z'] > $maxz) $maxz = $entry['z'];
				if ($entry['z'] < $minz) $minz = $entry['z'];

				$entry['name'] = $row['V1']." - ".$row['V2']." - ".max(100,(int)$row['V3']);

				$jsonData[] = $entry;
			}

			$jsonData = json_encode($jsonData);
			if ($categories1 != '') $categories1 = "[".$categories1."]"; else $categories1 = "''";
			if ($categories2 != '') $categories2 = "[".$categories2."]"; else $categories2 = "''";
		}
		catch(\Exception $e)
		{
			//if ($e->getMessage () != "WAIT")
			//{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			//}
			$jsonData = '[]';
		}
		$dbml = null;
		$return_params = array(
			'jsonData' => $jsonData,
			'variable1' => str_replace("e.id_cluster","id_cluster",$cross_var1),
			'variable2' => str_replace("e.id_cluster","id_cluster",$cross_var2),
			'variable3' => ($param_predict == 0)?'exe_time':'predicted_time',
			'categories1' => $categories1,
			'categories2' => $categories2,
			'maxx' => $maxx, 'minx' => $minx,
			'maxy' => $maxy, 'miny' => $miny,
			'maxz' => $maxz, 'minz' => $minz,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'must_wait' => $must_wait,
			'models' => $model_html
		);
		return $this->render('mltemplate/mlcrossvar3d.html.twig', $return_params);
	}

	public function mlcrossvar3dfaAction()
	{
		$jsonData = $possible_models = $possible_models_id = $other_models = array();
		$message = $instance = $possible_models_id = '';
		$categories1 = $categories2 = "''";
		$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			$this->buildFilters(array(
				'variable2' => array(
					'type' => 'selectOne', 'default' => array('net'), 'table' => 'execs',
					'label' => 'Variable 2: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Exeuction time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps');

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable2']) ? $_GET['variable2'] : array('net');
						return array('currentChoice' => $value, 'whereClause' => "");
					},
				),
				'variable1' => array(
					'type' => 'selectOne', 'default' => array('maps'), 'table' => 'execs',
					'label' => 'Variable 1: ',
					'generateChoices' => function() {
						return array('bench','net','disk','maps','iosf','replication',
							'iofilebuf','comp','blk_size','id_cluster','datanodes',
							'bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version',
							'provider','vm_OS','exe_time','pred_time','TOTAL_MAPS');
					},
					'beautifier' => function($value) {
						$labels = array('bench' => 'Benchmark','net' => 'Network','disk' => 'Disk',
							'maps' => 'Maps', 'iosf' => 'I/O Sort Factor','replication' => 'Replication',
							'iofilebuf' => 'I/O File Buffer','comp' => 'Compression','blk_size' => 'Block size',
							'id_cluster' => 'Cluster','datanodes' => 'Datanodes',
							'bench_type' => 'Benchmark Suite','vm_size' => 'VM Size','vm_cores' => 'VM cores',
							'vm_RAM' => 'VM RAM','type' => 'Cluster type','hadoop_version' => 'Hadoop Version',
							'provider' => 'Provider','vm_OS' => 'VM OS','exe_time' => 'Exeuction time',
							'pred_time' => 'Prediction time','TOTAL_MAPS' => 'Total execution maps',
						);

						return $labels[$value];
					},
					'parseFunction' => function() {
						$value = isset($_GET['variable1']) ? $_GET['variable1'] : array('maps');
						return array('currentChoice' => $value, 'whereClause' => "");
					},
				),
				'current_model' => array(
					'type' => 'selectOne',
					'default' => null,
					'label' => 'Model to use: ',
					'generateChoices' => function() {
						return array();
					},
					'parseFunction' => function() {
						$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning'
				),
				'unseen' => array(
					'type' => 'checkbox',
					'default' => 1,
					'label' => 'Predict with unseen atributes &#9888;',
					'parseFunction' => function() {
						$choice = (isset($_GET['unseen']) && !isset($_GET['unseen'])) ? 0 : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'filterGroup' => 'MLearning'
				), 'minexetime' => array(
					'default' => 0
				), 'valid' => array(
					'default' => 0
				), 'filter' => array(
					'default' => 0
				), 'prepares' => array(
					'default' => 1
				)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','unseen'))));
			$where_configs = $this->filters->getWhereClause();

			$model_html = '';
			$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
			foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$variables = $this->filters->getFiltersSelectedChoices(array('variable1','variable2','current_model','unseen'));
			$cross_var1 = $variables['variable1'];
			$cross_var2 = $variables['variable2'];

			$param_current_model = $variables['current_model'];
			$unseen = ($variables['unseen']) ? true : false;

			$where_configs = str_replace("AND .","AND ",$where_configs);
			$cross_var1 = str_replace("id_cluster","e.id_cluster",$cross_var1);
			$cross_var2 = str_replace("id_cluster","e.id_cluster",$cross_var2);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			// Model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);
			$current_model = (in_array($param_current_model,$possible_models_id))?$param_current_model:'';

			// Other models for filling
			$where_models = '';
			if (!empty($possible_models_id)) $where_models = " WHERE id_learner NOT IN ('".implode("','",$possible_models_id)."')";
			$result = $dbml->query("SELECT id_learner FROM aloja_ml.learners".$where_models);
			foreach ($result as $row) $other_models[] = $row['id_learner'];

			// Call to MLPrediction, to create a model
			if (empty($possible_models_id))
			{
				$_GET['pass'] = 1;
				$mltc1 = new MLPredictionController(); // FIXME - Choose the default modeling algorithm
				$mltc1->container = $this->container;
				$ret_learn = $mltc1->mlpredictionAction();

				$rows = null;
				if ($ret_data == 1)
				{
					$must_wait = "YES";
					throw new \Exception("WAIT");
				}
				else if ($ret_data == -1)
				{
					throw new \Exception("There was an error when creating a model for [".$instance."]");
				}
			}

			// Call to MLFindAttributes, to generate data
			if ($current_model != '')
			{
				$_GET['pass'] = 2;
				$mlfa1 = new MLFindAttributesController();
				$mlfa1->container = $this->container;
				$ret_data = $mlfa1->mlfindattributesAction();

				$rows = null;
				if ($ret_data == 1)
				{
					$must_wait = "YES";
					throw new \Exception("WAIT");
				}
				else if ($ret_data == -1)
				{
					throw new \Exception("There was an error when creating predictions for [".$instance."]");
				}
			}

			// Get stuff from the DB
			$query="SELECT ".$cross_var1." AS V1, ".$cross_var2." AS V2, AVG(e.pred_time) as V3, e.instance
				FROM aloja_ml.predictions as e
				WHERE e.id_learner ".(($current_model != '')?"='".$current_model."'":"IN (SELECT id_learner FROM aloja_ml.trees WHERE model='".$model_info."')").$where_configs."
				GROUP BY e.instance
				ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
	  	  	$rows = $db->get_rows($query);
			if (empty($rows))
			{
				if ($current_model == '') throw new \Exception('No data matches with your critteria. Try to select a specific model to generate data.');
				else throw new \Exception('No data matches with your critteria.');
			}

			// Show the results
			$map_var1 = $map_var2 = array();
			$count_var1 = $count_var2 = 0;
			$categories1 = $categories2 = '';

			$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));
			$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type","bench_type"));
			foreach ($rows as $row)
			{
				$entry = array();

				if ($var1_categorical)
				{
					if (!array_key_exists($row['V1'],$map_var1))
					{
						$map_var1[$row['V1']] = $count_var1++;
						$categories1 = $categories1.(($categories1!='')?",":"")."\"".$row['V1']."\"";
					}
					$entry['y'] = $map_var1[$row['V1']]*(rand(990,1010)/1000);
				}
				else $entry['y'] = (int)$row['V1']*(rand(990,1010)/1000);
				if ($entry['y'] > $maxy) $maxy = $entry['y'];
				if ($entry['y'] < $miny) $miny = $entry['y'];

				if ($var2_categorical)
				{
					if (!array_key_exists($row['V2'],$map_var2))
					{
						$map_var2[$row['V2']] = $count_var2++;
						$categories2 = $categories2.(($categories2!='')?",":"")."\"".$row['V2']."\"";
					}
					$entry['x'] = $map_var2[$row['V2']]*(rand(990,1010)/1000);
				}
				else $entry['x'] = (int)$row['V2']*(rand(990,1010)/1000);
				if ($entry['x'] > $maxx) $maxx = $entry['x'];
				if ($entry['x'] < $minx) $minx = $entry['x'];

				$entry['z'] = (int)$row['V3']*(rand(990,1010)/1000);
				if ($entry['z'] > $maxz) $maxz = $entry['z'];
				if ($entry['z'] < $minz) $minz = $entry['z'];

				$entry['name'] = $row['instance']; //$row['V1']." - ".$row['V2']." - ".max(100,(int)$row['V3']);
				$jsonData[] = $entry;
			}

			$jsonData = json_encode($jsonData);
			if ($categories1 != '') $categories1 = "[".$categories1."]"; else $categories1 = "''";
			if ($categories2 != '') $categories2 = "[".$categories2."]"; else $categories2 = "''";
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonData = '[]';
		}
		$dbml = null;
		$return_params = array(
			'jsonData' => $jsonData,
			'variable1' => str_replace("e.id_cluster","id_cluster",$cross_var1),
			'variable2' => str_replace("e.id_cluster","id_cluster",$cross_var2),
			'categories1' => $categories1,
			'categories2' => $categories2,
			'maxx' => $maxx, 'minx' => $minx,
			'maxy' => $maxy, 'miny' => $miny,
			'maxz' => $maxz, 'minz' => $minz,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
			'must_wait' => $must_wait,
			'models' => $model_html,
			'current_model' => $current_model
		);
		$this->filters->setCurrentChoices('current_model',array_merge(array("Aggregation of Models"),$possible_models_id,((!empty($other_models))?array('---Other models---'):array()),$other_models));

		return $this->render('mltemplate/mlcrossvar3dfa.html.twig', $return_params);
	}
}
