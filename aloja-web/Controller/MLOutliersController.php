<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLOutliersController extends AbstractController
{
	public function mloutliersAction()
	{
		$jsonData = $jsonWarns = $jsonOuts = array();
		$message = $instance = $jsonHeader = $jsonTable = $model_html = '';
		$possible_models = $possible_models_id = $other_models = array();
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	
		    	$where_configs = '';

		        $preset = null;
			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET))
			|| (count($_GET) == 2 && array_key_exists('dump',$_GET))
			|| (count($_GET) == 2 && array_key_exists('register',$_GET))
			|| (count($_GET) == 3 && array_key_exists('dump',$_GET) && array_key_exists('current_model',$_GET))
			|| (count($_GET) == 3 && array_key_exists('register',$_GET) && array_key_exists('current_model',$_GET)))
			{
				$preset = Utils::initDefaultPreset($db, 'mloutliers');
			}
		        $selPreset = (isset($_GET['presets'])) ? $_GET['presets'] : "none";

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters','datanodess','bench_types','vm_sizes','vm_coress','vm_RAMs','types','hadoop_versions'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,FALSE); sort($params[$p]); }

			$sigma_param = (array_key_exists('sigma',$_GET))?(int)$_GET['sigma']:1;

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db); // Used only as indicator for WEB
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);

			// model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);

			$current_model = "";
			if (array_key_exists('current_model',$_GET) && in_array($_GET['current_model'],$possible_models_id)) $current_model = $_GET['current_model'];

			// Other models for filling
			$where_models = '';
			if (!empty($possible_models_id))
			{
				$where_models = " WHERE id_learner NOT IN ('".implode("','",$possible_models_id)."')";
			}
			$result = $dbml->query("SELECT id_learner FROM learners".$where_models);
			foreach ($result as $row) $other_models[] = $row['id_learner'];

			if (!empty($possible_models_id))
			{
				$result = $dbml->query("SELECT id_learner, model, algorithm, CASE WHEN `id_learner` IN ('".implode("','",$possible_models_id)."') THEN 'COMPATIBLE' ELSE 'NOT MATCHED' END AS compatible FROM learners");
				foreach ($result as $row) $model_html = $model_html."<li>".$row['id_learner']." => ".$row['algorithm']." : ".$row['compatible']." : ".$row['model']."</li>";

				if ($current_model == "")
				{
					$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, p.id_learner FROM predictions p, learners l WHERE l.id_learner = p.id_learner AND p.id_learner IN ('".implode("','",$possible_models_id)."') AND predict_code > 0 ORDER BY MAE LIMIT 1";
					$result = $dbml->query($query);
					$row = $result->fetch();	
					$current_model = $row['id_learner'];
				}
				$config = $instance.'-'.$current_model.'-'.$sigma_param.'-outliers';

				$is_cached_mysql = $dbml->query("SELECT count(*) as total FROM resolutions WHERE id_resolution = '".md5($config)."'");
				$tmp_result = $is_cached_mysql->fetch();
				$is_cached = ($tmp_result['total'] > 0);

				$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';
				$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
				$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'-resolutions.csv');

				if (!$is_cached && !$in_process && !$finished_process)
				{
					// get headers for csv
					$header_names = array(
						'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
						'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster','name' => 'Cl.Name',
						'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
						'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type','bench_type' => 'Bench.Type','hadoop_version' => 'Hadoop.Version'
					);
					$headers = array_keys($header_names);
					$names = array_values($header_names);

					// dump the result to csv
					$query = "SELECT ".implode(",",$headers)." FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100 AND hadoop_version IS NOT NULL".$where_configs.";";
				    	$rows = $db->get_rows($query);
					if (empty($rows)) throw new \Exception('No data matches with your critteria.');

					$fp = fopen($cache_ds, 'w');
					fputcsv($fp, $names,',','"');
				    	foreach($rows as $row)
					{
						$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
						$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
						fputcsv($fp, array_values($row),',','"');
					}

					// Retrieve file model from DB
					$query = "SELECT file FROM model_storage WHERE id_hash='".$current_model."' AND type='learner';";
					$result = $dbml->query($query);
					$row = $result->fetch();
					$content = $row['file'];

					$filemodel = getcwd().'/cache/query/'.$current_model.'-object.rds';
					$fp = fopen($filemodel, 'w');
					fwrite($fp,$content);
					fclose($fp);

					// launch query
					exec('cd '.getcwd().'/cache/query ; touch '.md5($config).'.lock');
					exec(getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query ; '.getcwd().'/resources/aloja_cli.r -m aloja_outlier_dataset -d '.$cache_ds.' -l '.$current_model.' -p sigma='.$sigma_param.':hdistance=3:saveall='.md5($config).' > /dev/null 2>&1 ; rm -f '.md5($config).'.lock" > /dev/null 2>&1 &');
				}
				$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'-resolutions.csv');

				if ($finished_process && !$is_cached)
				{
					if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-resolutions.csv', 'r')) !== FALSE)
					{

						$header = fgetcsv($handle, 1000, ",");

						$token = 0;
						$query = "REPLACE INTO resolutions (id_resolution,id_learner,id_exec,instance,model,sigma,outlier_code,predicted,observed) VALUES ";
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$resolution = $data[0];
							$pred_value = ((int)$data[1] >= 100)?(int)$data[1]:100;
							$exec_value = (int)$data[2];
							$selected_instance_pre = preg_replace('/\\s+/','',$data[3]);
							$selected_instance_pre = str_replace(':',',',$selected_instance_pre);
							$specific_id = $data[4];

							if ($token > 0) { $query = $query.","; } $token = 1;
							$query = $query."('".md5($config)."','".$current_model."','".$specific_id."','".$selected_instance_pre."','".$model_info."','".$sigma_param."','".$resolution."','".$pred_value."','".$exec_value."') ";
						}
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving tree into DB');
					}

					// Store file model to DB
					$filemodel = getcwd().'/cache/query/'.md5($config).'-object.rds';
					$fp = fopen($filemodel, 'r');
					$content = fread($fp, filesize($filemodel));
					$content = addslashes($content);
					fclose($fp);

					$query = "INSERT INTO model_storage (id_hash,type,file) VALUES ('".md5($config)."','resolution','".$content."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file resolution into DB');

					// Remove temporary files
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'-*.csv');

					$is_cached = true;
				}

				if (!$is_cached)
				{
					$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
					$must_wait = 'YES';
					if (isset($_GET['dump'])) { echo "1"; exit(0); }
				}
				else
				{
					$must_wait = 'NO';

					$query = "SELECT predicted, observed, outlier_code, id_exec, instance FROM resolutions WHERE id_resolution = '".md5($config)."' LIMIT 5000"; // FIXME - CLUMSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
					$result = $dbml->query($query);

					foreach ($result as $row)
					{
						$entry = array('x' => (int)$row['predicted'], 'y' => (int)$row['observed'], 'name' => $row['instance'], 'id' => (int)$row['id_exec']);

						if ($row['outlier_code'] == 0) $jsonData[] = $entry;
						if ($row['outlier_code'] == 1) $jsonWarns[] = $entry;
						if ($row['outlier_code'] == 2) $jsonOuts[] = $entry;

						$jsonTable .= (($jsonTable=='')?'':',').'["'.(($row['outlier_code'] == 0)?'Legitimate':(($row['outlier_code'] == 1)?'Warning':'Outlier')).'","'.$row['predicted'].'","'.$row['observed'].'","'.str_replace(",","\",\"",$row['instance']).'","'.$row['id_exec'].'"]';						
					}

					$query_var = "SELECT MAX(predicted) as max_x, MAX(observed) as max_y FROM resolutions WHERE id_resolution = '".md5($config)."' LIMIT 5000";
					$result = $dbml->query($query_var);
					$row = $result->fetch();
					$max_x = $row['max_x'];
					$max_y = $row['max_y'];

					$header = array('Prediction','Observed','Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Cl.Name','Datanodes','Headnodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Bench.Type','Version','ID');
					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					$jsonData = json_encode($jsonData);
					$jsonWarns = json_encode($jsonWarns);
					$jsonOuts = json_encode($jsonOuts);

					$jsonTable = '['.$jsonTable.']';

					// Dump case
					if (isset($_GET['dump']))
					{
						echo str_replace(array("[","]","{title:\"","\"}"),array('','',''),$jsonHeader)."\n";
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonOuts);
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonWarns);
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonData);
						exit(0);
					}

					// Register case
					if (isset($_GET['register']))
					{
						// Update the predictions table
						$query_var =   "UPDATE predictions as p, resolutions as r
								SET p.outlier = r.outlier_code
								WHERE r.id_exec = p.id_exec
									AND r.id_resolution = '".md5($config)."'
									AND p.id_learner = '".$current_model."'";
						if ($dbml->query($query_var) === FALSE) throw new \Exception('Error when updating predictions in DB');
					}
				}
			}
			else
			{
				$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section.";
				$must_wait = "NO";
			}
			$dbml = null;
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
			$model = '';

			$dbml = null;
		}
		echo $this->container->getTwig()->render('mltemplate/mloutliers.html.twig',
			array(
				'selected' => 'mloutliers',
				'jsonData' => $jsonData,
				'jsonWarns' => $jsonWarns,
				'jsonOuts' => $jsonOuts,
				'jsonHeader' => $jsonHeader,
				'jsonTable' => $jsonTable,
				'max_p' => min(array($max_x,$max_y)),
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
				'hadoop_versions' => $params['hadoop_versions'],
				'must_wait' => $must_wait,
				'models' => $model_html,
				'models_id' => $possible_models_id,
				'other_models_id' => $other_models,
				'current_model' => $current_model,
				'resolution_id' => md5($config),
				'sigma' => $sigma_param,
				'message' => $message,
				'instance' => $instance,
				'preset' => $preset,
				'selPreset' => $selPreset,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}
}
?>
