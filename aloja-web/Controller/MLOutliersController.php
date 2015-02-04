<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class MLOutliersController extends AbstractController
{
	public function mloutliersAction()
	{
		$jsonData = $jsonWarns = $jsonOuts = array();
		$message = $instance = '';
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

			if (count($_GET) <= 1 || (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$where_configs = '';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
			}

			$filter_options = Utils::getFilterOptions($db);
			$paramAllOptions = $tokens = array();
			$model_info = '';
			foreach ($param_names as $p) 
			{
				if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
				$model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
			
 				$tokens[$p] = '';
				if (empty($params[$p])) { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
 				else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
 				$instance = $instance.(($instance=='')?'':',').$tokens[$p];
 			}

			// Model for filling
			if (($fh = fopen(getcwd().'/cache/query/record.data', 'r')) !== FALSE)
			{
				while (!feof($fh))
				{
					$line = fgets($fh, 4096);
					if (preg_match("(((bench|net|disk|blk_size) (\(.+\)))( )?)", $line))
					{
						$fts = explode(" : ",$line);
						$parts = explode(" ",$fts[1]);
						$buffer = array();
						$last_part = "";
						foreach ($parts as $p)
						{
							if (preg_match("(\(.+\))", $p)) $buffer[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
							else $last_part = $p;
						}

						if ($model_info[0]==' ') $model_info = substr($model_info, 1);
						$parts_2 = explode(" ",$model_info);
						$buffer_2 = array();
						$last_part = "";
						foreach ($parts_2 as $p)
						{
							if (preg_match("(\(.+\))", $p)) $buffer_2[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
							else $last_part = $p;
						}

						$match = TRUE;
						foreach ($buffer_2 as $bk => $ba)
						{
							if (!array_key_exists($bk,$buffer)) { $match = FALSE; break; }
							if ($buffer[$bk][0] != "*" && array_intersect($ba, $buffer[$bk]) != $ba) { $match = FALSE; break; }
						}

						if ($match)
						{
							$possible_models[] = $line;
							$possible_models_id[] = $fts[0];
						}
					}
				}
				fclose($fh);
			}

			$model = '';
			if (!empty($possible_models_id))
			{
				if (array_key_exists('current_model',$_GET)) $model = $_GET['current_model'];
				else $model = $possible_models_id[0];

				$cache_ds = getcwd().'/cache/query/'.md5($model_info.'-'.$model).'-cache.csv';
				$in_process = shell_exec('ps aux | grep "aloja_outlier_dataset -d '.$cache_ds.' -l '.$model.'" | grep -v grep');

				if (file_exists($cache_ds) && $in_process == NULL)
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

				if (!file_exists($cache_ds) && $in_process == NULL)
				{
					// get headers for csv
					$header_names = array(
						'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe Time','exec' => 'Exec Conf','cost' => 'Running Cost $','net' => 'Net',
						'disk' => 'Disk','maps' => 'Maps','iosf' => 'IO SFac','replication' => 'Rep','iofilebuf' => 'IO FBuf','comp' => 'Comp',
						'blk_size' => 'Blk size','id_cluster' => 'Cluster','histogram' => 'Histogram','prv' => 'PARAVER','end_time' => 'End time',
					);

				    	$query="SHOW COLUMNS FROM execs;";
				    	$rows = $db->get_rows ($query);
					if (empty($rows)) throw new \Exception('No data matches with your critteria.');
					$headers = array();
					$names = array();
					$count = 0;
					foreach($rows as $row)
					{
						if (array_key_exists($row['Field'],$header_names))
						{
							$headers[$count] = $row['Field'];
							$names[$count++] = $header_names[$row['Field']];
						}
					}
					$headers[$count] = 0;	// FIXME - Costs are NOT in the database?! What sort of anarchy is this?!
					$names[$count++] = $header_names['cost'];

					// dump the result to csv
				    	$query="SELECT ".implode(",",$headers)." FROM execs WHERE valid = TRUE ".$where_configs.";";
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
					$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_outlier_dataset -d '.$cache_ds.' -l '.$model.' -p sigma=3:hdistance=3:saveall='.md5($model_info.'-'.$model).' > /dev/null &';
					exec($command);

					// update cache record (for human reading)
					$register = md5($model_info.'-'.$model).' : '.$model_info.'-'.$model."\n";
					shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
					file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
				}
				$in_process = shell_exec('ps aux | grep "aloja_outlier_dataset -d '.$cache_ds.' -l '.$model.'" | grep -v grep');
				$must_wait = 'NO';

				if ($in_process != NULL)
				{
					$jsonData = $jsonOuts = $jsonWarns = '[]';
					$must_wait = 'YES';
				}
				else
				{
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
								$jsonData[$count_ind[0]]['y'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonData[$count_ind[0]]['x'] = (int)$data[2];
								$jsonData[$count_ind[0]++]['name'] = $data[3];							
							}
							else if ((int)$data[0] == 1)
							{
								$jsonWarns[$count_ind[1]]['y'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonWarns[$count_ind[1]]['x'] = (int)$data[2];
								$jsonWarns[$count_ind[1]++]['name'] = $data[3];							
							}
							else
							{
								$jsonOuts[$count_ind[2]]['y'] = ((int)$data[1] >= 100)?(int)$data[1]:100;
								$jsonOuts[$count_ind[2]]['x'] = (int)$data[2];
								$jsonOuts[$count_ind[2]++]['name'] = $data[3];							
							}
							$count++;

							if ((int)$data[1] > $max_y) $max_y = (int)$data[1];
							if ((int)$data[2] > $max_x) $max_x = (int)$data[2];
						}
						fclose($handle);

						$jsonData = json_encode($jsonData);
						$jsonWarns = json_encode($jsonWarns);
						$jsonOuts = json_encode($jsonOuts);
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
			$jsonData = $jsonOuts = $jsonWarns = '[]';
			$model = '';
			$possible_models_id = $possible_models = array();
		}
		echo $this->container->getTwig()->render('mltemplate/mloutliers.html.twig',
			array(
				'selected' => 'mloutliers',
				'jsonData' => $jsonData,
				'jsonWarns' => $jsonWarns,
				'jsonOuts' => $jsonOuts,
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
