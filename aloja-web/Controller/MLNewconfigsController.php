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
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	
		    	$configurations = array ();	// Useless here
		    	$where_configs = '';
		    	$concat_config = "";		// Useless here

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes',
						'datanodess','bench_types','vm_OSs','vm_coress','vm_RAMs','vm_sizes','hadoop_versions','types'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('learn',$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('RR1'); $where_configs .= ' AND disk IN ("RR1")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('3'); $where_configs .= ' AND comp IN ("3")';
				$params['mapss'] = array('2','4'); $where_configs .= ' AND maps IN ("2","4")';
				$params['blk_sizes'] = array('134'); $where_configs .= ' AND blk_size IN ("134")';
				$params['iosfs'] = array('100'); $where_configs .= ' AND iosf IN ("100")';
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

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("`id_cluster`","e.`id_cluster`",$where_configs);
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);
			unset($params['id_clusters']); // Exclude the param from now on
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db); // Used only as indicator in the WEB

			$config = $model_info.' '.$learn_param.' newminconfs';

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options ='kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options = 'ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM learners WHERE id_learner = '".md5($config."M")."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'.fin');

			// Create Models and Predictions
			if (!$is_cached && !$in_process && !$finished_process)
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
				$command = $command.'../../resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config."M").' -p saveall='.md5($config.'R').':kmax=10 >/dev/null 2>&1; rm -f '.md5($config).'.lock; touch '.md5($config).'.fin" >/dev/null 2>&1 &';
				exec($command);
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

				$learners = array();
				$learners[] = md5($config."F");
				$learners[] = md5($config."M");
				foreach ($learners as $learner_1)
				{
					// Save learning model to DB, with predictions
					$is_cached_mysql = $dbml->query("SELECT id_learner FROM learners WHERE id_learner = '".$learner_1."'");
					$tmp_result = $is_cached_mysql->fetch();
					if ($tmp_result['id_learner'] != $learner_1) 
					{
						// register model to DB
						$query = "INSERT IGNORE INTO learners (id_learner,instance,model,algorithm)";
						$query = $query." VALUES ('".$learner_1."','".$instance."','".substr($model_info,1)."','".$learn_param."');";
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

						// read results of the CSV and dump to DB
						foreach (array("tt", "tv", "tr") as $value)
						{
							if (($handle = fopen(getcwd().'/cache/query/'.$learner_1.'-'.$value.'.csv', 'r')) !== FALSE)
							{
								$header = fgetcsv($handle, 1000, ",");

								$token = 0;
								$query = "INSERT IGNORE INTO predictions (id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,name,datanodes,headnodes,vm_OS,vm_cores,vm_RAM,provider,vm_size,type,pred_time,id_learner,instance,predict_code) VALUES ";
								while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
								{
									$specific_instance = implode(",",array_slice($data, 2, 19));
									$specific_data = implode(",",$data);
									$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
									$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
									$specific_data = str_replace(",","','",$specific_data);

									$query_var = "SELECT count(*) as num FROM predictions WHERE instance = '".$specific_instance."' AND id_learner = '".$learner_1."'";
									$result = $dbml->query($query_var);
									$row = $result->fetch();
						
									// Insert instance values
									if ($row['num'] == 0)
									{
										if ($token != 0) { $query = $query.","; } $token = 1;
										$query = $query."('".$specific_data."','".$learner_1."','".$specific_instance."','".(($value=='tt')?3:(($value=='tv')?2:1))."') ";								
									}
								}

								if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
								fclose($handle);
							}
						}

						// Remove temporal files
						$output = shell_exec('rm -f '.getcwd().'/cache/query/'.$learner_1.'*.{dat,csv}');
					}
				}

				// Save minconfigs to DB, with props and centers
				$is_cached_mysql = $dbml->query("SELECT id_minconfigs FROM minconfigs WHERE id_minconfigs = '".md5($config.'R')."'");
				$tmp_result = $is_cached_mysql->fetch();
				if ($tmp_result['id_minconfigs'] != md5($config.'R')) 
				{
					// register minconfigs to DB
					$query = "INSERT IGNORE INTO minconfigs (id_minconfigs,id_learner,instance,model,is_new)";
					$query = $query." VALUES ('".md5($config.'R')."','".md5($config.'M')."','".$instance."','".substr($model_info,1)."','1');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving minconfis into DB');

					$clusters = array();

					// Save results of the CSV - MAE or RAE
					if (file_exists(getcwd().'/cache/query/'.md5($config.'R').'-raes.csv')) $error_file = 'raes.csv'; else $error_file = 'maes.csv';
					$handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-'.$error_file, 'r');
					while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
					{
						$cluster = (int)$data[0];
						if ($error_file == 'raes.csv') { $error_mae = 'NULL'; $error_rae = (float)$data[1]; }
						if ($error_file == 'maes.csv') { $error_mae = (float)$data[1]; $error_rae = 'NULL'; }

						// register minconfigs_props to DB
						$query = "INSERT INTO minconfigs_props (id_minconfigs,cluster,MAE,RAE)";
						$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$error_mae."','".$error_rae."');";
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving minconfis into DB');

						$clusters[] = $cluster;
					}
					fclose($handle);

					// Save results of the CSV - Configs
					$handle_sizes = fopen(getcwd().'/cache/query/'.md5($config.'R').'-sizes.csv', 'r');
					foreach ($clusters as $cluster)
					{
						// Get supports from sizes
						$sizes = fgetcsv($handle_sizes, 1000, ",");

						// Get clusters
						$handle = fopen(getcwd().'/cache/query/'.md5($config.'R').'-dsk'.$cluster.'.csv', 'r');
						$header = fgetcsv($handle, 1000, ",");
						$i = 0;
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$subdata = array_slice($data, 0, 12);
							$specific_data = implode(',',$subdata);
							$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
							$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
							$specific_data = preg_replace('/,Cl(\d+)/',',${1}',$specific_data);
							$specific_data = str_replace(",","','",$specific_data);

							// register minconfigs_props to DB
							$query = "INSERT INTO minconfigs_centers (id_minconfigs,cluster,id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,support)";
							$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$specific_data."','".$sizes[$i++]."');";
							if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving centers into DB');
						}
						fclose($handle);
					}
					fclose($handle_sizes);

					// Remove temporal files
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.csv');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'D').'*.data');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'F').'*.{csv,dat}');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'M').'*.{csv,dat}');
					$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.{fin,csv,dat}');
				}

				// Retrieve minconfig progression results from DB
				$header = "id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,support";
				$header_array = explode(",",$header);

				$last_y = 9E15;
				$configs = '[';

				$query = "SELECT cluster, MAE, RAE FROM minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'";
				$result = $dbml->query($query);
				foreach ($result as $row)
				{
					// Retrieve minconfig progression results from DB
					if ((float)$row['MAE'] > 0) $error = (float)$row['MAE']; else $error = (float)$row['RAE'];
					$cluster = (int)$row['cluster'];

					$new_val = array();
					$new_val['x'] = $cluster;
					if ($error > $last_y) $new_val['y'] = $last_y;
					else $last_y = $new_val['y'] = $error;

					$jsonData[] = $new_val;

					// Retrieve minconfig centers from DB
					$query_2 = "SELECT ".$header." FROM minconfigs_centers WHERE id_minconfigs='".md5($config.'R')."' AND cluster='".$cluster."'";
					$result_2 = $dbml->query($query_2);

					$jsonConfig = '[';
					foreach ($result_2 as $row_2)
					{
						$values = '';
						foreach ($header_array as $ha) $values = $values.(($values!='')?',':'').'\''.$row_2[$ha].'\'';
						$jsonConfig = $jsonConfig.(($jsonConfig!='[')?',':'').'['.$values.']';
					}
					$jsonConfig = $jsonConfig.']';
					
					$configs = $configs.(($configs!='[')?',':'').$jsonConfig;
				}
				$configs = $configs.']';
				$jsonData = json_encode($jsonData);
				$jsonHeader = '[{title:""},{title:"Est.Time"},{title:"Benchmark"},{title:"Network"},{title:"Disk"},{title:"Maps"},{title:"IO.SF"},{title:"Replicas"},{title:"IO.FBuf"},{title:"Compression"},{title:"Blk.Size"},{title:"Main Ref. Cluster"},{title:"Support"}]';

				$is_cached_mysql = $dbml->query("SELECT MAX(cluster) as mcluster, MAX(MAE) as mmae, MAX(RAE) as mrae FROM minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'");
				$tmp_result = $is_cached_mysql->fetch();
				$max_x = ((float)$tmp_result['mmae'] > 0)?(float)$tmp_result['mmae']:(float)$tmp_result['mrae'];
				$max_y = (float)$tmp_result['mcluster'];
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
				'jsonData' => $jsonData,
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
