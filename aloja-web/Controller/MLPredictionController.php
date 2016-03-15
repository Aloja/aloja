<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLPredictionController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier','money'));
	}

	public function mlpredictionAction()
	{
		$jsonExecs = $jsonLearners = $jsonLearningHeader = '[]';
		$message = $instance = $error_stats = $config = $model_info = $slice_info = '';
		$max_x = $max_y = 0;
		$min_x = $min_y = 9E10;
		$must_wait = 'NO';
		$is_legacy = 0;
		try
		{
			$dbml = MLUtils::getMLDBConnection($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$db = $this->container->getDBUtils();

			$reference_cluster = $this->container->get('config')['ml_refcluster'];

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			if (array_key_exists('dump',$_GET)) { $dump = $_GET["dump"]; unset($_GET["dump"]); }
			if (array_key_exists('pass',$_GET)) { $pass = $_GET["pass"]; unset($_GET["pass"]); }

			$this->buildFilters(array('learn' => array(
				'type' => 'selectOne',
				'default' => array('regtree'),
				'label' => 'Learning method: ',
				'generateChoices' => function() {
					return array('regtree','nneighbours','nnet','polyreg','supportvms');
				},
				'beautifier' => function($value) {
					$labels = array('regtree' => 'Regression Tree','nneighbours' => 'k-NN',
						'nnet' => 'NNets','polyreg' => 'PolyReg-3','supportvms' => 'Support Vector Machines');
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

			if ($instructions)
			{
				MLUtils::getIndexModels ($jsonLearners, $jsonLearningHeader, $dbml);
				return $this->render('mltemplate/mlprediction.html.twig', array('jsonExecs' => $jsonExecs, 'learners' => $jsonLearners, 'header_learners' => $jsonLearningHeader, 'instructions' => 'YES'));
			}

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$learnParams = $this->filters->getFiltersSelectedChoices(array('learn','umodel'));
			$learn_param = $learnParams['learn'];
			$unrestricted = ($learnParams['umodel']) ? true : false;

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, $unrestricted);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, $unrestricted);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$learn_param.' '.(($unrestricted)?'U':'R').' '.$slice_info;
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3'; }
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }
			else if ($learn_param == 'supportvms') { $learn_method = 'aloja_supportvms'; $learn_options .= ':prange=0,20000'; }

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

			if (!$is_cached && !$in_process && !$finished_process)
			{
			    	// dump the result to csv
				$file_header = "";
				$query = MLUtils::getQuery($file_header,$reference_cluster,$where_configs);
			    	$rows = $db->get_rows ( $query );
				if (empty($rows))
				{
					// Try legacy
					$query = MLUtils::getLegacyQuery ($file_header,$where_configs);
					$learn_options .= ':vin=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor';
				    	$rows = $db->get_rows ( $query );
					if (empty($rows))
					{
						throw new \Exception('No data matches with your critteria.');
					}
					$is_legacy = 1;
				}

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp,$file_header,',','"');
			    	foreach($rows as $row) fputcsv($fp, array_values($row),',','"');

				// Check we have enough values
				if (count($rows) < 10) throw new \Exception('WARNING: Too many few samples selected to learn ('.count($rows).'). Change your filter to use a wider data slice.');

				// run the R processor
				exec('cd '.getcwd().'/cache/ml ; touch '.getcwd().'/cache/ml/'.md5($config).'.lock');
				if ($is_legacy == 1) exec('touch '.getcwd().'/cache/ml/'.md5($config).'.legacy');
				exec('cd '.getcwd().'/cache/ml ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null 2>&1; rm -f '.getcwd().'/cache/ml/'.md5($config).'.lock; touch '.md5($config).'.fin" > /dev/null 2>&1 -p 1 &');
			}

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');

			if ($in_process)
			{
				$must_wait = "YES";
				if (isset($dump)) { echo "1"; exit(0); }
				if (isset($pass)) { return 1; }
				throw new \Exception('WAIT');
			}

			// Retrieve / Process the Learning
			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			if (!$is_cached) 
			{
				if (file_exists(getcwd().'/cache/ml/'.md5($config).'.legacy')) $is_legacy = 1;

				// register model to DB
				$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice,legacy)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."','".$is_legacy."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

				// read results of the CSV and dump to DB
				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-predictions.csv', 'r')) !== FALSE)
				{
					$header = fgetcsv($handle, 5000, ",");
					while (($data = fgetcsv($handle, 5000, ",")) !== FALSE)
					{
						// INSERT INTO DB <INSTANCE>
						$selected = array_merge(array_slice($data,1,10),array_slice($data,18,4));
						$selected_inst = implode("','",$selected);
						$selected_inst = preg_replace('/,\'Cmp(\d+)\',/',',\'${1}\',',$selected_inst);
						$selected_inst = preg_replace('/,\'Cl(\d+)\',/',',\'${1}\',',$selected_inst);
						$query_i = "INSERT IGNORE INTO aloja_ml.pred_execs (bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,bench_type,hadoop_version,datasize,scale_factor,start_time,end_time) VALUES ";
						$query_i = $query_i."('".$selected_inst."',now(),now())";
						if ($dbml->query($query_i) === FALSE) throw new \Exception('Error when saving into DB');

						// GET REFERENCE IDs
						$where_clauses = '1=1';
						$where_names = array("bench","net","disk","maps","iosf","replication","iofilebuf","comp","blk_size","id_cluster","bench_type","hadoop_version","datasize","scale_factor");
						$selcount = 0;
						foreach($where_names as $wn) $where_clauses = $where_clauses.' AND '.$wn.' = \''.$selected[$selcount++].'\'';
						$where_clauses = preg_replace('/\'Cmp(\d+)\'/','\'${1}\'',$where_clauses);
						$where_clauses = preg_replace('/\'Cl(\d+)\'/','\'${1}\'',$where_clauses);

						$query = "SELECT id_prediction FROM aloja_ml.pred_execs WHERE ".$where_clauses.' LIMIT 1';
						$result = $dbml->query($query);
						$row = $result->fetch();
						$predid = (is_null($row['id_prediction']))?0:$row['id_prediction'];

						// INSERT INTO DB <PREDICTIONS>
						$id_exec = $data[0];
						$exe_time = $data[2];
						$pred_time = $data[key(array_slice($data,-2,1,TRUE))];
						$code = $data[key(array_slice($data,-1,1,TRUE))];
						$full_instance = implode(",",array_slice($data,1,-1));
						$specific_instance = array_merge(array($data[1]),array_slice($data, 3, 21));
						$specific_instance = implode(",",$specific_instance);

						$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,id_pred_exec,exe_time,pred_time,id_learner,instance,full_instance,predict_code) VALUES ";
						$query = $query."('".$id_exec."','".$predid."','".$exe_time."','".$pred_time."','".md5($config)."','".$specific_instance."','".$full_instance."','".(($code=='tt')?3:(($code=='tv')?2:1))."') ";								
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
					}
					fclose($handle);
				}
				else throw new \Exception('Error on R processing. Result file '.md5($config).'-predictions.csv not present');

				// Store file model to DB
				$filemodel = getcwd().'/cache/ml/'.md5($config).'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config)."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.fin');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.dat');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.legacy');
			}

			// Retrieve results from DB
			$count = 0;
			$error_stats = '';
			$jsonExecs = array();

			$query = "SELECT exe_time, pred_time, instance FROM aloja_ml.predictions WHERE id_learner='".md5($config)."' AND exe_time > 100 LIMIT 5000"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LIMIT WHEN THE BUG IS SOLVED
			$result = $dbml->query($query);
			foreach ($result as $row)
			{
				$jsonExecs[$count]['y'] = (int)$row['exe_time'];
				$jsonExecs[$count]['x'] = (int)$row['pred_time'];
				$jsonExecs[$count]['mydata'] = implode(",",array_slice(explode(",",$row['instance']),0,21));

				if ((int)$row['exe_time'] > $max_y) $max_y = (int)$row['exe_time'];
				if ((int)$row['pred_time'] > $max_x) $max_x = (int)$row['pred_time'];
				if ((int)$row['exe_time'] < $min_y) $min_y = (int)$row['exe_time'];
				if ((int)$row['pred_time'] < $min_x) $min_x = (int)$row['pred_time'];
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
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonExecs = '[]';
		}
		$dbml = null;

		$return_params = array(
			'jsonExecs' => json_encode($jsonExecs),
			'learners' => $jsonLearners,
			'header_learners' => $jsonLearningHeader,
			'max_p' => min(array($max_x,$max_y)),
			'min_p' => max(array($min_x,$min_y)),
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
