<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLOutliersController extends AbstractController
{
	public function __construct($container)
	{
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function mloutliersAction()
	{
		$jsonData = $jsonWarns = $jsonOuts = array();
		$message = $instance = $jsonHeader = $jsonTable = $model_html = $config = $model_info = '';
		$possible_models = $possible_models_id = $other_models = array();
		$jsonResolutions = $jsonResolutionsHeader = '[]';
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;
		    	
			if (array_key_exists('dump',$_GET))
			{
				$dump = $_GET["dump"];
				unset($_GET["dump"]);
			}

			if (array_key_exists('register',$_GET))
			{
				$register = $_GET["register"];
				unset($_GET["register"]);
			}

			$this->buildFilters(
				array('current_model' => array(
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
					'filterGroup' => 'MLearning',
				),
				'sigma' => array(
					'type' => 'inputNumber',
					'default' => 1,
					'label' => 'Sigmas: ',
					'parseFunction' => function() {
						$choice = isset($_GET['sigma']) ? $_GET['sigma'] : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
					'max' => 3,
					'min' => 1,
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
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','sigma'))));

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$param_variables = $this->filters->getFiltersSelectedChoices(array('current_model','sigma'));
			$param_current_model = $param_variables['current_model'];
			$sigma_param = $param_variables['sigma'];

			$where_configs = $this->filters->getWhereclause();
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

			if ($instructions)
			{
				$result = $dbml->query("SELECT id_learner, model, algorithm FROM aloja_ml.learners");
				foreach ($result as $row) $model_html = $model_html."<li>".$row['id_learner']." => ".$row['algorithm']." : ".$row['model']."</li>";

				MLUtils::getIndexOutExps ($jsonResolutions, $jsonResolutionsHeader, $dbml);

				$this->filters->setCurrentChoices('current_model',array_merge($possible_models_id,array('---Other models---'),$other_models));
				return $this->render('mltemplate/mloutliers.html.twig', array('outexps' => $jsonResolutions, 'header_outexps' => $jsonResolutionsHeader, 'jsonData' => '[]','jsonWarns' => '[]','jsonOuts' => '[]','jsonHeader' => '[]','jsonTable' => '[]','max_p' => 0,'models' => $model_html,'instructions' => 'YES'));
			}

			if (!empty($possible_models_id))
			{
				$result = $dbml->query("SELECT id_learner, model, algorithm, CASE WHEN `id_learner` IN ('".implode("','",$possible_models_id)."') THEN 'COMPATIBLE' ELSE 'NOT MATCHED' END AS compatible FROM aloja_ml.learners");
				foreach ($result as $row) $model_html = $model_html."<li>".$row['id_learner']." => ".$row['algorithm']." : ".$row['compatible']." : ".$row['model']."</li>";

				if ($current_model == "")
				{
					$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, p.id_learner FROM aloja_ml.predictions p, aloja_ml.learners l WHERE l.id_learner = p.id_learner AND p.id_learner IN ('".implode("','",$possible_models_id)."') AND predict_code > 0 ORDER BY MAE LIMIT 1";
					$result = $dbml->query($query);
					$row = $result->fetch();	
					$current_model = $row['id_learner'];
				}
				$config = $instance.'-'.$current_model.'-'.$sigma_param.' '.$slice_info.'-outliers';

				$is_cached_mysql = $dbml->query("SELECT count(*) as total FROM aloja_ml.resolutions WHERE id_resolution = '".md5($config)."'");
				$tmp_result = $is_cached_mysql->fetch();
				$is_cached = ($tmp_result['total'] > 0);

				$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';
				$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
				$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'-resolutions.csv');

				if (!$is_cached && !$in_process && !$finished_process)
				{
					// get headers for csv
	 				$header_names = array(
						'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','e.net' => 'Net','e.disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
						'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster',
						'datanodes' => 'Datanodes','c.vm_OS' => 'VM.OS','c.vm_cores' => 'VM.Cores','c.vm_RAM' => 'VM.RAM','c.provider' => 'Provider','c.vm_size' => 'VM.Size',
						'type' => 'Type','bench_type' => 'Bench.Type','hadoop_version'=>'Hadoop.Version','IFNULL(datasize,0)' =>'Datasize','scale_factor' => 'Scale.Factor'
					);
					$added_names = array(
						'maxtxkbs' => 'Net.maxtxKB.s','maxrxkbs' => 'Net.maxrxKB.s','maxtxpcks' => 'Net.maxtxPck.s','maxrxpcks' => 'Net.maxrxPck.s',
						'maxtxcmps' => 'Net.maxtxCmp.s','maxrxcmps' => 'Net.maxrxCmp.s','maxrxmscts' => 'Net.maxrxmsct.s',
						'maxtps' => 'Disk.maxtps','maxsvctm' => 'Disk.maxsvctm','maxrds' => 'Disk.maxrd.s','maxwrs' => 'Disk.maxwr.s',
						'maxrqsz' => 'Disk.maxrqsz','maxqusz' => 'Disk.maxqusz','maxawait' => 'Disk.maxawait','maxutil' => 'Disk.maxutil'
	 				);

					// dump the result to csv
					$query = "SELECT ".implode(",",array_keys($header_names)).",
						n.maxtxkbs, n.maxrxkbs, n.maxtxpcks, n.maxrxpcks, n.maxtxcmps, n.maxrxcmps, n.maxrxmscts,
						d.maxtps, d.maxsvctm, d.maxrds, d.maxwrs, d.maxrqsz, d.maxqusz, d.maxawait, d.maxutil
						FROM aloja2.execs AS e LEFT JOIN aloja2.clusters AS c ON e.id_cluster = c.id_cluster,
						(
						    SELECT  MAX(n1.`maxtxkB/s`) AS maxtxkbs, MAX(n1.`maxrxkB/s`) AS maxrxkbs,
						    MAX(n1.`maxtxpck/s`) AS maxtxpcks, MAX(n1.`maxrxpck/s`) AS maxrxpcks,
						    MAX(n1.`maxtxcmp/s`) AS maxtxcmps, MAX(n1.`maxrxcmp/s`) AS maxrxcmps,
						    MAX(n1.`maxrxmcst/s`) AS maxrxmscts,
						    e1.net AS net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
						    FROM aloja2.precal_network_metrics AS n1,
						    aloja2.execs AS e1 LEFT JOIN aloja2.clusters AS c1 ON e1.id_cluster = c1.id_cluster
						    WHERE e1.id_exec = n1.id_exec
						    GROUP BY e1.net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
						) AS n,
						(
						    SELECT MAX(d1.maxtps) AS maxtps, MAX(d1.maxsvctm) as maxsvctm,
						    MAX(d1.`maxrd_sec/s`) as maxrds, MAX(d1.`maxwr_sec/s`) as maxwrs,
						    MAX(d1.maxrq_sz) as maxrqsz, MAX(d1.maxqu_sz) as maxqusz,
						    MAX(d1.maxawait) as maxawait, MAX(d1.`max%util`) as maxutil,
						    e2.disk AS disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
						    FROM aloja2.precal_disk_metrics AS d1,
						    aloja2.execs AS e2 LEFT JOIN aloja2.clusters AS c1 ON e2.id_cluster = c1.id_cluster
						    WHERE e2.id_exec = d1.id_exec
						    GROUP BY e2.disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
						) AS d
						WHERE e.net = n.net AND c.vm_cores = n.vm_cores AND c.vm_RAM = n.vm_RAM AND c.vm_size = n.vm_size
						AND c.vm_OS = n.vm_OS AND c.provider = n.provider AND e.disk = d.disk AND c.vm_cores = d.vm_cores
						AND c.vm_RAM = d.vm_RAM AND c.vm_size = d.vm_size AND c.vm_OS = d.vm_OS AND c.provider = d.provider
						AND hadoop_version IS NOT NULL".$where_configs.";";
				    	$rows = $db->get_rows($query);
					if (empty($rows)) throw new \Exception('No data matches with your critteria.');

					$fp = fopen($cache_ds, 'w');
					fputcsv($fp,array_values(array_merge($header_names,$added_names)),',','"');
				    	foreach($rows as $row)
					{
						$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
						$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
						fputcsv($fp, array_values($row),',','"');
					}

					// Retrieve file model from DB
					$query = "SELECT file FROM aloja_ml.model_storage WHERE id_hash='".$current_model."' AND type='learner';";
					$result = $dbml->query($query);
					$row = $result->fetch();
					$content = $row['file'];

					$filemodel = getcwd().'/cache/ml/'.$current_model.'-object.rds';
					$fp = fopen($filemodel, 'w');
					fwrite($fp,$content);
					fclose($fp);

					// launch query
					exec('cd '.getcwd().'/cache/ml ; touch '.md5($config).'.lock');
					exec(getcwd().'/resources/queue -c "cd '.getcwd().'/cache/ml ; '.getcwd().'/resources/aloja_cli.r -m aloja_outlier_dataset -d '.$cache_ds.' -l '.$current_model.' -p sigma='.$sigma_param.':hdistance=3:saveall='.md5($config).' > /dev/null 2>&1 ; rm -f '.md5($config).'.lock" > /dev/null 2>&1 &');
				}
				$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'-resolutions.csv');

				if ($finished_process && !$is_cached)
				{
					if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-resolutions.csv', 'r')) !== FALSE)
					{

						$header = fgetcsv($handle, 1000, ",");

						$token = 0;
						$query = "REPLACE INTO aloja_ml.resolutions (id_resolution,id_learner,id_exec,instance,model,dataslice,sigma,outlier_code,predicted,observed) VALUES ";
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$resolution = $data[0];
							$pred_value = ((int)$data[1] >= 100)?(int)$data[1]:100;
							$exec_value = (int)$data[2];
							$selected_instance_pre = preg_replace('/\\s+/','',$data[3]);
							$selected_instance_pre = str_replace(':',',',$selected_instance_pre);
							$specific_id = $data[4];

							if ($token > 0) { $query = $query.","; } $token = 1;
							$query = $query."('".md5($config)."','".$current_model."','".$specific_id."','".$selected_instance_pre."','".$model_info."','".$slice_info."','".$sigma_param."','".$resolution."','".$pred_value."','".$exec_value."') ";
						}
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving tree into DB');
					}

					// Store file model to DB
					$filemodel = getcwd().'/cache/ml/'.md5($config).'-object.rds';
					$fp = fopen($filemodel, 'r');
					$content = fread($fp, filesize($filemodel));
					$content = addslashes($content);
					fclose($fp);

					$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config)."','resolution','".$content."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file resolution into DB');

					// Remove temporary files
					$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'-*.csv');

					$is_cached = true;
				}

				if (!$is_cached)
				{
					$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
					$must_wait = 'YES';
					if (isset($dump)) { echo "1"; exit(0); }
				}
				else
				{
					$must_wait = 'NO';

					$query = "SELECT predicted, observed, outlier_code, id_exec, instance FROM aloja_ml.resolutions WHERE id_resolution = '".md5($config)."' LIMIT 5000"; // FIXME - CLUMSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
					$result = $dbml->query($query);

					foreach ($result as $row)
					{
						$entry = array('x' => (int)$row['predicted'], 'y' => (int)$row['observed'], 'name' => implode(",",array_slice(explode(",",$row['instance']),0,21)), 'id' => (int)$row['id_exec']);

						if ($row['outlier_code'] == 0) $jsonData[] = $entry;
						if ($row['outlier_code'] == 1) $jsonWarns[] = $entry;
						if ($row['outlier_code'] == 2) $jsonOuts[] = $entry;

						$jsonTable .= (($jsonTable=='')?'':',').'["'.(($row['outlier_code'] == 0)?'Legitimate':(($row['outlier_code'] == 1)?'Warning':'Outlier')).'","'.$row['predicted'].'","'.$row['observed'].'","'.str_replace(",","\",\"",implode(",",array_slice(explode(",",$row['instance']),0,21))).'","'.$row['id_exec'].'"]';						
					}

					$query_var = "SELECT MAX(predicted) as max_x, MAX(observed) as max_y FROM aloja_ml.resolutions WHERE id_resolution = '".md5($config)."' LIMIT 5000";
					$result = $dbml->query($query_var);
					$row = $result->fetch();
					$max_x = $row['max_x'];
					$max_y = $row['max_y'];

					$header = array('Prediction','Observed','Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Datanodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Bench.Type','Version','Data.Size','Scale.Factor','ID');
					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					$jsonData = json_encode($jsonData);
					$jsonWarns = json_encode($jsonWarns);
					$jsonOuts = json_encode($jsonOuts);

					$jsonTable = '['.$jsonTable.']';

					// Dump case
					if (isset($dump))
					{
						echo str_replace(array("[","]","{title:\"","\"}"),array('','',''),$jsonHeader)."\n";
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonOuts);
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonWarns);
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonData);
						exit(0);
					}

					// Register case
					if (isset($register))
					{
						// Update the predictions table
						$query_var =   "UPDATE aloja_ml.predictions as p, aloja_ml.resolutions as r
								SET p.outlier = r.outlier_code
								WHERE r.id_exec = p.id_exec
									AND r.id_resolution = '".md5($config)."'
									AND p.id_learner = '".$current_model."'";
						if ($dbml->query($query_var) === FALSE) throw new \Exception('Error when updating aloja_ml.predictions in DB');
					}
				}
			}
			else throw new \Exception('There are no prediction models trained for such parameters. Train at least one model in "ML Prediction" section.');

			$dbml = null;
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () );
			$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
			$must_wait = "NO";
			$dbml = null;
		}

		$return_params = array(
			'jsonData' => $jsonData,
			'jsonWarns' => $jsonWarns,
			'jsonOuts' => $jsonOuts,
			'jsonHeader' => $jsonHeader,
			'jsonTable' => $jsonTable,
			'max_p' => min(array($max_x,$max_y)),
			'outexps' => $jsonResolutions,
			'header_outexps' => $jsonResolutionsHeader,
			'must_wait' => $must_wait,
			'models' => $model_html,
			'models_id' => $possible_models_id,
			'other_models_id' => $other_models,
			'current_model' => $current_model,
			'resolution_id' => md5($config),
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'sigma' => $sigma_param,
			'message' => $message,
			'instance' => $instance,
		);
		$this->filters->setCurrentChoices('current_model',array_merge($possible_models_id,array('---Other models---'),$other_models));
		return $this->render('mltemplate/mloutliers.html.twig', $return_params);
	}
}
?>
