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
		$message = $instance = $jsonHeader = $jsonTable = '';
		$max_x = $max_y = 0;
		try
		{
			$db = $this->container->getDBUtils();
		    	
		    	$configurations = array ();	// Useless here
		    	$where_configs = '';
		    	$concat_config = "";		// Useless here
		    	
			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			$learn_param = (array_key_exists('learn',$_GET))?$_GET['learn']:'regtree';

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET))
			|| (count($_GET) == 2 && array_key_exists('dump',$_GET))
			|| (count($_GET) == 3 && array_key_exists('dump',$_GET) && array_key_exists('current_model',$_GET)))
			{
				$where_configs = '';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
			}

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db); // Used only as indicator for WEB
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);

			// model for filling
			$possible_models = $possible_models_id = array();
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $db);

			$model = '';
			if (!empty($possible_models_id))
			{
				if (array_key_exists('current_model',$_GET)) $model = $_GET['current_model'];
				else $model = $possible_models_id[0];

				$cache_ds = getcwd().'/cache/query/'.md5($model_info.'-'.$model).'-cache.csv';

				$is_cached = file_exists($cache_ds);
				$in_process = file_exists(getcwd().'/cache/query/'.md5($model_info.'-'.$model).'.lock');

				if ($is_cached && !$in_process)
				{
					$keep_cache = TRUE;
					foreach (array("cause.csv", "resolutions.csv", "object.rds") as &$value)
					{
						$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($model_info.'-'.$model).'-'.$value);
					}
					if (!$keep_cache)
					{
						unlink($cache_ds);
						shell_exec("sed -i '/".md5($model_info.'-'.$model)." : ".$model_info.'-'.$model."/d' ".getcwd()."/cache/query/record.data");
					}
				}

				if (!$is_cached && !$in_process)
				{
					// get headers for csv
					$header_names = array(
						'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
						'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster','name' => 'Cl.Name',
						'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
						'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type'
					);
					$headers = array_keys($header_names);
					$names = array_values($header_names);

					// dump the result to csv
				    	$query="SELECT ".implode(",",$headers)." FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100".$where_configs.";";
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

					// launch query
					$command = '( cd '.getcwd().'/cache/query ; ';
					$command = $command.'touch '.getcwd().'/cache/query/'.md5($model_info.'-'.$model).'.lock ; ';
					$command = $command.getcwd().'/resources/aloja_cli.r -m aloja_outlier_dataset -d '.$cache_ds.' -l '.$model.' -p sigma=3:hdistance=3:saveall='.md5($model_info.'-'.$model).' > /dev/null 2>&1 ; ';
					$command = $command.'rm -f '.getcwd().'/cache/query/'.md5($model_info.'-'.$model).'.lock ; ) > /dev/null 2>&1 &';
					exec($command);

					// update cache record (for human reading)
					$register = md5($model_info.'-'.$model).' : '.$model_info.'-'.$model."\n";
					shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
					file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
				}
				$in_process = file_exists(getcwd().'/cache/query/'.md5($model_info.'-'.$model).'.lock');

				if ($in_process)
				{
					$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
					$must_wait = 'YES';
				}
				else
				{
					$must_wait = 'NO';
					if (isset($_GET['dump']))
					{
						try
						{
							if (($handle = @fopen(getcwd().'/cache/query/'.md5($model_info.'-'.$model).'-resolutions.csv', 'r')) !== FALSE)
							{
								while (($data = fgets($handle, 1000)) !== FALSE) echo str_replace("\"","",$data)."\n";
								fclose($handle);
							}
						}
						catch(\Exception $e) { }
						exit(0);
					}

					// read results of the CSV
					if (($handle = fopen(getcwd().'/cache/query/'.md5($model_info.'-'.$model).'-resolutions.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 1000, ",");
						$count = 0;
						$count_ind = array(0,0,0);
						$max_x = $max_y = 0;
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE && $count < 5000) // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
						{
							if ((int)$data[0] == 0)
							{
								$jsonData[$count_ind[0]]['x'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonData[$count_ind[0]]['y'] = (int)$data[2];
								$jsonData[$count_ind[0]]['name'] = $data[3];							
								$jsonData[$count_ind[0]++]['id'] = $data[4];							
							}
							else if ((int)$data[0] == 1)
							{
								$jsonWarns[$count_ind[1]]['x'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonWarns[$count_ind[1]]['y'] = (int)$data[2];
								$jsonWarns[$count_ind[1]]['name'] = $data[3];
								$jsonWarns[$count_ind[1]++]['id'] = $data[4];
							}
							else
							{
								$jsonOuts[$count_ind[2]]['x'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonOuts[$count_ind[2]]['y'] = (int)$data[2];
								$jsonOuts[$count_ind[2]]['name'] = $data[3];
								$jsonOuts[$count_ind[2]++]['id'] = $data[4];							
							}
							$jsonTable .= (($jsonTable=='')?'':',').'["'.(((int)$data[0] == 0)?'Legitimate':(((int)$data[0] == 1)?'Warning':'Outlier')).'","'.(((int)$data[1] >= 100)?(int)$data[1]:100).'","'.((int)$data[2]).'","'.implode('","',explode(":",$data[3])).'","'.$data[4].'"]';
							$count++;

							if ((int)$data[1] > $max_y) $max_y = (int)$data[1];
							if ((int)$data[2] > $max_x) $max_x = (int)$data[2];
						}
						fclose($handle);

						$jsonHeader = '[';
						for ($i = 0; $i < count($header); $i++)
						{
							$jsonHeader .= (($jsonHeader=='[')?'':',').'{title:"'.implode('"},{title:"',explode(":",$header[$i])).'"}';
						}
						$jsonHeader .= ']';

						$jsonData = json_encode($jsonData);
						$jsonWarns = json_encode($jsonWarns);
						$jsonOuts = json_encode($jsonOuts);

						$jsonTable = '['.$jsonTable.']';
					}
				}
			}
			else
			{
				$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section.";
				$must_wait = "NO";
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = $jsonOuts = $jsonWarns = $jsonHeader = $jsonTable = '[]';
			$model = '';
			$possible_models_id = $possible_models = array();
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
				'must_wait' => $must_wait,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => '[\''.implode("','",$possible_models_id).'\']',
				'current_model' => $model,
				'message' => $message,
				'instance' => $instance,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}
}
?>
