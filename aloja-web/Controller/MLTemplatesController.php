<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLTemplatesController extends AbstractController
{
	public function mlpredictionAction()
	{
		$jsonExecs = array();
		$instance = $error_stats = '';
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
			$unrestricted = (array_key_exists('umodel',$_GET) && $_GET['umodel'] == 1);

			if (count($_GET) <= 1)
 			{
				$where_configs = '';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$unrestricted = TRUE;			
 			}

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, $unrestricted,$db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, $unrestricted,$db);

			$config = $model_info.' '.$learn_param;
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached = file_exists($cache_ds);
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($is_cached && !$in_process)
			{
				$keep_cache = TRUE;
				foreach (array("tt", "tv", "tr") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv');
				}
				if (!$keep_cache)
				{
					unlink($cache_ds);
					shell_exec("sed -i '/".md5($config)." :".$config."/d' ".getcwd()."/cache/query/record.data");
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

				// run the R processor
				exec('cd '.getcwd().'/cache/query ; touch '.getcwd().'/cache/query/'.md5($config).'.lock');
				exec('cd '.getcwd().'/cache/query ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null 2>&1; rm -f '.getcwd().'/cache/query/'.md5($config).'.lock" > /dev/null 2>&1 -p 1 &');

				// update cache record (for human reading)
				$register = md5($config).' :'.$config."\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($in_process)
			{
				$jsonExecs = "[]";
				$must_wait = "YES";
				$max_x = $max_y = 0;
			}
			else
			{
				// read results of the CSV
				$must_wait = "NO";
				$count = 0;
				$max_x = $max_y = 0;
				$error_stats = '';
				foreach (array("tt", "tv", "tr") as $value)
				{
					$mae = 0;
					$rae = 0;
					$count_dataset = 0;

					if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 1000, ",");

						$key_exec = array_search('Exe.Time', array_values($header));
						$key_pexec = array_search('Pred.Exe.Time', array_values($header));

						$info_keys = array("ID","Cluster","Benchmark","Net","Disk","Maps","IO.SFac","Rep","IO.FBuf","Comp","Blk.size");
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE && $count < 5000) // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
						{
							$jsonExecs[$count]['y'] = (int)$data[$key_exec];
							$jsonExecs[$count]['x'] = (int)$data[$key_pexec];

							$mae += abs($jsonExecs[$count]['y'] - $jsonExecs[$count]['x']);
							$rae += (float)abs($jsonExecs[$count]['y'] - $jsonExecs[$count]['x']) / $jsonExecs[$count]['y'];
							$count_dataset = $count_dataset + 1;

							$extra_data = "";
							foreach(array_values($header) as &$value2)
							{
								$aux = array_search($value2, array_values($header));
								if (array_search($value2, array_values($info_keys)) > 0) $extra_data = $extra_data.$value2.":".$data[$aux]." ";
								else if (!array_search($value2, array('Exe.Time','Pred.Exe.Time')) > 0 && $data[$aux] == 1) $extra_data = $extra_data.$value2." "; // Binarized Data
							}
							$jsonExecs[$count++]['mydata'] = $extra_data;

							if ((int)$data[$key_exec] > $max_y) $max_y = (int)$data[$key_exec];
							if ((int)$data[$key_pexec] > $max_x) $max_x = (int)$data[$key_pexec];
						}
						fclose($handle);
					}
					$error_stats = $error_stats.'Dataset: '.$value.' => MAE: '.($mae / $count_dataset).' RAE: '.($rae / $count_dataset).'<br/>';
				}
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonExecs = '[]';
			$max_x = $max_y = 0;
			$must_wait = 'NO';
		}
		echo $this->container->getTwig()->render('mltemplate/mlprediction.html.twig',
			array(
				'selected' => 'mlprediction',
				'jsonExecs' => json_encode($jsonExecs),
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
				'unrestricted' => $unrestricted,
				'learn' => $learn_param,
				'must_wait' => $must_wait,
				'instance' => $instance,
				'error_stats' => $error_stats,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}

	public function mlfindattributesAction()
	{
		$instance = $message = '';
		$must_wait = 'NO';
		try
		{
		    	$db = $this->container->getDBUtils();
		    	
		    	$configurations = array ();	// Useless here
		    	$where_configs = '';
		    	$concat_config = "";		// Useless here
		    	
			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			$unseen = (array_key_exists('unseen',$_GET) && $_GET['unseen'] == 1);

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists("current_model",$_GET))
			|| (count($_GET) == 2 && array_key_exists("dump",$_GET))
			|| (count($_GET) == 3 && array_key_exists("dump",$_GET) && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('65536','131072'); $where_configs .= ' AND iofilebuf IN ("65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$params['id_clusters'] = array('1'); $where_configs .= ' AND id_cluster IN ("1")';
				$params['mapss'] = array('4'); $where_configs .= ' AND maps IN ("4")';
				$params['iosfs'] = array('10'); $where_configs .= ' AND iosf IN ("10")';
				$params['blk_sizes'] = array('128'); $where_configs .= ' AND blk_size IN ("128")';
				$unseen = FALSE;
			}

			$jsonData = $jsonHeader = "[]";
			$mae = $rae = $count_preds = 0;

			// compose instance
			$model_info = MLUtils::generateModelInfo($param_names, $params, $unseen, $db);
			$instance = MLUtils::generateSimpleInstance($param_names, $params, $unseen, $db);			
			$instances = MLUtils::generateInstances($param_names, $params, $unseen, $db);

			// Model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $db);

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			if (!empty($possible_models_id))
			{
				if ($current_model != "") $model = $current_model;
				else
				{
					$best_id = $possible_models_id[0];
					$best_mae = 9E15;
					foreach ($possible_models_id as $model_id)
					{
						$data_filename = getcwd().'/cache/query/'.md5($instance.'-'.$model_id).'-ipred.data';
						if (file_exists($data_filename))
						{
							$data = explode("\n",file_get_contents($data_filename));
							if ($data[0] < $best_mae)
							{
								$best_mae = $data[0];
								$best_id = $model_id;
							}
						}
					}
					$current_model = $model = $best_id;
				}

				$cache_filename = getcwd().'/cache/query/'.md5($instance.'-'.$model).'-ipred.csv';
				$tmp_file = getcwd().'/cache/query/'.md5($instance.'-'.$model).'.tmp';

				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$finished_process = $in_process && ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));
				$is_cached = file_exists($cache_filename);

				if (!$in_process && !$finished_process && !$is_cached)
				{
					exec('cd '.getcwd().'/cache/query ; touch '.md5($instance.'-'.$model).'.lock ; rm -f '.$tmp_file);
					foreach ($instances as $inst)
					{
						exec(getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query ; '.getcwd().'/resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict=\''.$inst.'\' -v | grep -v \'WARNING\' | grep -v \'Prediction\' >> '.$tmp_file.' 2> /dev/null; echo 1 >> '.md5($instance.'-'.$model).'.lock" > /dev/null 2>&1 &');
					}
				}

				$finished_process = ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));
				$is_cached = file_exists($cache_filename);

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

						// Fetch Real Value
						$realexecval = 0;

						$comp_instance = '';
						$attributes = explode(',',$parsed);
						$count_aux = 0;
						foreach ($attributes as $part)
						{
							if ($count_aux < 1 || $count_aux > 19) { $count_aux++; continue; }			#FIXME - Indexes hardcoded for file-tmp
							$comp_instance = $comp_instance.(($comp_instance!='')?",":"").((is_numeric($part))?$part:"\\\"".$part."\\\"");
							$count_aux++;
						}
						$output = shell_exec("grep \"".$comp_instance."\" ".getcwd().'/cache/query/'.$current_model.'-dsorig.csv');

						if (!is_null($output))
						{
							$solutions = explode("\n",$output);
							$count_sols = 0;
							foreach ($solutions as $solution)
							{
								if ($solution == '') continue;
								$attributes2 = explode(",",$solution);

								# Decide if the value is OUTLIER
								$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_outlier_instance -l '.$model.' -p instance="'.str_replace("\\\"","",$comp_instance).'":observed='.(int)$attributes2[1].':display=1 -v 2> /dev/null';
								$output = shell_exec($command);
								$isout = explode("\n",$output);

								if (strpos($isout[0],'[1] "2"') === false)
								{
									$realexecval = $realexecval + (int)$attributes2[1];
									$count_sols++;
								}
							}
							if ($count_sols > 0)
							{
								$realexecval = $realexecval / $count_sols;

								$mae = $mae + abs((int)$attributes[20] - $realexecval); 			#FIXME - Indexes hardcoded for file-tmp
								$rae = $rae + abs(((float)$attributes[20] - $realexecval) / $realexecval);	#FIXME - Indexes hardcoded for file-tmp
								$count_preds++;
							}
						}
						// END - Fetch Real Value

						if ($jsonData!='[') $jsonData = $jsonData.',';
						$jsonData = $jsonData.'[\''.implode("','",explode(',',$parsed)).'\',\''.$realexecval.'\']';
						$i++;
					}
					$jsonData = $jsonData.']';
					if ($count_preds > 0)
					{
						$mae = number_format($mae / $count_preds,3);
						$rae = number_format($rae / $count_preds,5);
					}

					//$jsonData = str_replace(array('Cl1','Cl2'),array('Local','Azure'),$jsonData); 			# FIXME - Un-hardcode in the future
					foreach (array(0,1,2,3) as $value) $jsonData = str_replace('Cmp'.$value,Utils::getCompressionName($value),$jsonData);

					$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Cl.Name','Datanodes','Headnodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Prediction','Observed'); #FIXME - Header hardcoded for file-dsorig.csv
					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					// save at cache
					file_put_contents($cache_filename, $jsonHeader."\n".$jsonData);
					file_put_contents(str_replace('.csv','.data',$cache_filename), $mae."\n".$rae);

					// update cache record (for human reading)
					$register = md5($instance.'-'.$model).' : '.$instance."-".$model."\n";
					shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
					file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);

					// remove remaining locks and readies
					shell_exec('rm -f '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				}

				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$is_cached = file_exists($cache_filename);

				if (!$is_cached)
				{
					$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
					$must_wait = 'YES';
					if (isset($_GET['dump'])) { echo "1"; exit(0); }
				}
				else
				{
					if (isset($_GET['dump']))
					{
						$data = explode("\n",file_get_contents($cache_filename));
						echo "ID".str_replace(array("[","]","{title:\"","\"}"),array('','',''),$data[0])."\n";
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$data[1]);
						exit(0);
					}

					// get cache
					$data = explode("\n",file_get_contents($cache_filename));
					$jsonHeader = $data[0];
					$jsonData = $data[1];

					$data = explode("\n",file_get_contents(str_replace('.csv','.data',$cache_filename)));
					$mae = $data[0];
					$rae = $data[1];
				}				
			}
			else
			{
				$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section.".$instance;
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );

			$jsonData = $jsonHeader = "[]";
			$instance = $instances = $possible_models_id = "";
			$possible_models = array();
			$must_wait = 'NO';
			$mae = $rae = 0;
		}
		echo $this->container->getTwig()->render('mltemplate/mlfindattributes.html.twig',
			array(
				'selected' => 'mlfindattributes',
				'instance' => $instance,
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
				'jsonData' => $jsonData,
				'jsonHeader' => $jsonHeader,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => '[\''.implode("','",$possible_models_id).'\']',
				'current_model' => $current_model,
				'message' => $message,
				'mae' => $mae,
				'rae' => $rae,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}

	public function mlclearcacheAction()
	{
		try
		{
			if (file_exists(getcwd().'/cache/query/record.data'))
			{
				$output = array();

				if (array_key_exists("ccache",$_GET))
				{
					if (($fh = fopen(getcwd().'/cache/query/record.data', 'r')) !== FALSE)
					{
						while (!feof($fh))
						{
							$line = fgets($fh, 4096);
							$fts = explode(" : ",$line);

							$command = 'rm '.getcwd().'/cache/query/'.$fts[0].'-*';
							$output[] = shell_exec($command);
						}
						fclose($fh);

						$command = 'rm '.getcwd().'/cache/query/record.data';
						$output[] = shell_exec($command);
					}
				}
			}
			else $this->container->getTwig ()->addGlobal ( 'message', "ML cache cleared.\n" );
		}
		catch(Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$output = array();
		}
		echo $this->container->getTwig()->render('mltemplate/mlclearcache.html.twig',
			array(
				'selected' => 'mlclearcache',
				'output' => '<li>'.implode("</li><li>",$output).'</li>'
			)
		);
	}
}
?>
