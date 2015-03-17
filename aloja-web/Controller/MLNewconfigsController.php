<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLNewconfigsController extends AbstractController
{
	public function mlnewconfigsAction()
	{
		$jsonData = array();
		$message = $instance = '';
		try
		{
			$db = $this->container->getDBUtils();
		    	
		    	$configurations = array ();	// Useless here
		    	$where_configs = '';
		    	$concat_config = "";		// Useless here

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes',
						'datanodess','bench_types','vm_OS','vm_coress','vm_RAMs','vm_sizes','hadoop_versions','types'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('learn',$_GET))
			|| (count($_GET) == 2 && array_key_exists('dump',$_GET))
			|| (count($_GET) == 3 && array_key_exists('dump',$_GET) && array_key_exists('learn',$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$params['datanodess'] = array('3');// $where_configs .= ' AND datanodes = 3';
				$params['bench_types'] = array('HiBench');// $where_configs .= ' AND bench_type = "HiBench"';
				$params['vm_OSs'] = array('linux');// $where_configs .= ' AND vm_OS = "linux"';				
				$params['vm_sizes'] = array('SYS-6027R-72RF');// $where_configs .= ' AND vm_size = "SYS-6027R-72RF"';
				$params['vm_coress'] = array('12');// $where_configs .= ' AND vm_cores = 12';
				$params['vm_RAMs'] = array('128');// $where_configs .= ' AND vm_RAM = 128';
				$params['hadoop_versions'] = array('1');// $where_configs .= ' AND hadoop_version = 1';
				$params['types'] = array('On-premise');// $where_configs .= ' AND type = "On-premise"';
			}
			$learn_param = (array_key_exists('learn',$_GET))?$_GET['learn']:'regtree';
			$params['id_clusters'] = Utils::read_params('id_clusters',$where_configs,$configurations,$concat_config); // This is excluded from all the process, except the initial DB query

			// compose instance
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);
			unset($params['id_clusters']); // Exclude the param from now on
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db); // Used only as indicator in the WEB

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options ='kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options = 'ppoly=3:prange=0,20000'; }

			$config = $model_info.' '.$learn_param.' newminconfs';

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached = file_exists($cache_ds);
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			// Find cache TODO - Check for prev models
			if ($is_cached && !$in_process)
			{
				$keep_cache = TRUE;
				foreach (array("tt.csv", "tv.csv", "tr.csv") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config."M").'-'.$value);
				}
				foreach (array("sizes.csv", "object.rds") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config.'R').'-'.$value);
				}
				$error_cache = FALSE;
				foreach (array("maes.csv", "raes.csv") as &$value)
				{
					$error_cache = $error_cache || file_exists(getcwd().'/cache/query/'.md5($config.'R').'-'.$value);
				}
				if (!($keep_cache && $error_cache))
				{
					unlink($cache_ds);
					shell_exec("sed -i '/".md5($config."F")." : ".$config." FA-model/d' ".getcwd()."/cache/query/record.data");
					shell_exec("sed -i '/".md5($config."D")." : ".$config." FA-dataset/d' ".getcwd()."/cache/query/record.data");
					shell_exec("sed -i '/".md5($config."M")." : ".$config." MC-model/d' ".getcwd()."/cache/query/record.data");
					shell_exec("sed -i '/".md5($config."R")." : ".$config." MC-result/d' ".getcwd()."/cache/query/record.data");
				}
			}

			// Create Models and Predictions
			if (!$is_cached && !$in_process)
			{
				// get headers for csv
				$header_names = array(
					'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','datanodes' => 'Datanodes','bench_type' => 'Bench.Type','vm_OS' => 'VM.OS',
					'vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM','vm_size' => 'VM.Size','hadoop_version' => 'Hadoop.Version','type' => 'Type'
				);

				$headers = array_keys($header_names);
				$names = array_values($header_names);

			    	// dump the result to csv
			    	$query="SELECT ".implode(",",$headers)." FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND bench NOT LIKE 'prep_%' AND e.exe_time > 100 AND hadoop_version IN ('1','2')".$where_configs.";";
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp, $names,',','"');
			    	foreach($rows as $row)
				{
					//$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
					fputcsv($fp, array_values($row),',','"');
				}

				// run the R processor
				exec('cd '.getcwd().'/cache/query; touch '.md5($config).'.lock');
				$command = getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query; ../../resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."F").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,Bench.Type,VM.OS,VM.Cores,VM.RAM,VM.Size,Hadoop.Version,Type\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_predict_instance -l '.md5($config."F").' -p inst_predict=\''.$instance.'\':saveall='.md5($config."D").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,Bench.Type,VM.OS,VM.Cores,VM.RAM,VM.Size,Hadoop.Version,Type\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -d '.md5($config."D").'-dataset.data -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."M").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,Bench.Type,VM.OS,VM.Cores,VM.RAM,VM.Size,Hadoop.Version,Type\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config."M").' -p saveall='.md5($config.'R').':kmax=200 >/dev/null 2>&1; rm -f '.md5($config).'.lock" >/dev/null 2>&1 &';
				exec($command);

				// update cache record (for human reading)
				$register = array();
				$register[] = md5($config."F").' :'.$config." FA-model\n";
				$register[] = md5($config."D").' :'.$config." FA-dataset\n";
				$register[] = md5($config."M").' :'.$config." MC-model\n";
				$register[] = md5($config."R").' :'.$config." MC-result\n";
				foreach ($register as $reg)
				{
					shell_exec("sed -i '/".$reg."/d' ".getcwd()."/cache/query/record.data");
					file_put_contents(getcwd().'/cache/query/record.data', $reg, FILE_APPEND | LOCK_EX);
				}
			}
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($in_process)
			{
				$jsonData = $jsonHeader = $configs = '[]';
				$must_wait = "YES";
				$max_x = $max_y = 0;
			}
			else
			{
				$must_wait = "NO";
				if (isset($_GET['dump']))
				{
					try
					{
						$sizes = NULL;
						if (($handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-sizes.csv', 'r')) !== FALSE)
						{
							while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
							{
								if (count($data) == (int)$_GET['dump']) $sizes = $data;
							}
							fclose($handle);
						}

						if (($handle = @fopen(getcwd().'/cache/query/'.md5($config.'R').'-dsk'.$_GET['dump'].'.csv', 'r')) !== FALSE)
						{
							$count = 0;
							echo str_replace(array("\"","\n"),"",fgets($handle, 1000)).",Instances\n";
							while (($data = fgets($handle, 1000)) !== FALSE)
							{
								echo str_replace(array("\"","\n"),"",$data).",".$sizes[$count++]."\n";
							}
							fclose($handle);
						}
					}
					catch(\Exception $e) { }
					exit(0);
				}

				// read results of the CSV - MAE or RAE
				if (file_exists(getcwd().'/cache/query/'.md5($config.'R').'-raes.csv')) $error_file = 'raes.csv'; else $error_file = 'maes.csv';
				if (($handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-'.$error_file, 'r')) !== FALSE)
				{
					$count = $max_x = $max_y = 0;
					$last_y = 9E15;
					while (($data = fgetcsv($handle, 1000, ",")) !== FALSE && $count < 5000) // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
					{
						$jsonData[$count]['x'] = (int)$data[0];
						if ((float)$data[1] > $last_y) $jsonData[$count++]['y'] = $last_y;
						else $last_y = $jsonData[$count++]['y'] = (float)$data[1];


						if ((int)$data[0] > $max_x) $max_x = (int)$data[0];
						if ((float)$data[1] > $max_y) $max_y = (float)$data[1];
					}
					fclose($handle);
				}

				// MAGIC TRICK BEGINS
/*				$illusion = array('id_cluster' => 'Cluster','name' => 'Cl.Name',
					'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
					'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type');
				$query="SELECT ".implode(",",array_keys($illusion))." FROM clusters";
				$rows = $db->get_rows($query);
				$clusters_info = array();
				foreach ($rows as $row)
				{
					$id_cl = $row['id_cluster'];
					unset($row['id_cluster']);
					$clusters_info[$id_cl] = $row;
				}
				// MAGIC TRICK ENDS
*/
				// read results of the CSV - Configs
				$configs = '[';
				$jsonHeader = '[]';
				foreach ($jsonData as $cluster)
				{
					$sizes = NULL;
					if (($handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-sizes.csv', 'r')) !== FALSE)
					{
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							if (count($data) == (int)$cluster['x']) $sizes = $data;
						}
						fclose($handle);
					}

					if (($handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-dsk'.$cluster['x'].'.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 1000, ",");
						if ($jsonHeader == '[]')
						{
							$header = array_slice($header, 0, 11);	// ANTI-MAGIC TRICK
							$jsonHeader = '[{title:""}';
							foreach ($header as $title) if ($title != "ID") $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
							$jsonHeader = $jsonHeader.',{title:"Instances"}]';
						}

						$count = 0;
						$jsonConfig = '[';
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$subdata = array_slice($data, 0, 11);
							//$subdata = array_merge($subdata,$clusters_info[(int)substr($data[11],2)]); // MAGIC TRICK

							if ($jsonConfig!='[') $jsonConfig = $jsonConfig.',';
							$jsonConfig = $jsonConfig.'[\''.implode("','",$subdata).'\',\''.$sizes[$count++].'\']';

						}
						$jsonConfig = $jsonConfig.']';
						fclose($handle);

						if ($configs!='[') $configs = $configs.',';
						$configs = $configs.$jsonConfig;
					}
				}
				$configs = $configs.']';
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = $jsonHeader = $configs = '[]';
			$max_x = $max_y = 0;
			$must_wait = 'NO';
		}
		echo $this->container->getTwig()->render('mltemplate/mlnewconfigs.html.twig',
			array(
				'selected' => 'mlnewconfigs',
				'jsonData' => json_encode($jsonData),
				'jsonHeader' => $jsonHeader,
				'configs' => $configs,
				'max_p' => min(array($max_x,$max_y)),
				'benchs' => $params['benchs'],
				'nets' => $params['nets'],
				'disks' => $params['disks'],
				'blk_sizes' => $params['blk_sizes'],
				'comps' => $params['comps'],
				'mapss' => $params['mapss'],
				'replications' => $params['replications'],
				'iosfs' => $params['iosfs'],
				'iofilebufs' => $params['iofilebufs'],
				'datanodess' => $params['datanodess'],
				'bench_types' => $params['bench_types'],
				'vm_sizes' => $params['vm_sizes'],
				'vm_coress' => $params['vm_coress'],
				'vm_RAMs' => $params['vm_RAMs'],
				'hadoop_versions' => $params['hadoop_versions'],
				'types' => $params['types'],
				'message' => $message,
				'instance' => $instance,
				'learn' => $learn_param,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
