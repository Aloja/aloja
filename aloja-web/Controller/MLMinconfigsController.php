<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLMinconfigsController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function mlminconfigsAction()
	{
		$jsonData = $jsonHeader = $configs = '[]';
		$model_info = $slice_info = $message = $instance = $config = '';
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	
			$this->buildFilters(array('learn' => array(
				'type' => 'selectOne',
				'default' => array('regtree'),
				'label' => 'Learning method: ',
				'generateChoices' => function() {
					return array('regtree','nneighbours','nnet','polyreg');
				},
				'beautifier' => function($value) {
					$labels = array('regtree' => 'Regression Tree','nneighbours' => 'k-NN',
						'nnet' => 'NNets','polyreg' => 'PolyReg-3');
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

			$where_configs = $this->filters->getWhereClause();

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$learnParams = $this->filters->getFiltersSelectedChoices(array('learn','umodel'));
			$learn_param = $learnParams['learn'];
			$unrestricted = ($learnParams['umodel']) ? true : false;

			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance

			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, $unrestricted, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, $unrestricted, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$learn_param.' '.(($unrestricted)?'U':'R').' '.$slice_info.' minconfs';
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."' AND id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = $is_cached && ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'.fin');

			// Create Models and Predictions
			if (!$is_cached && !$in_process && !$finished_process)
			{
				// get headers for csv
				$header_names = array(
					'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster',
					'datanodes' => 'Datanodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size',
					'type' => 'Type','bench_type' => 'Bench.Type','hadoop_version'=>'Hadoop.Version'
				);
				$headers = array_keys($header_names);
				$names = array_values($header_names);

			    	// dump the result to csv
			    	$query="SELECT ".implode(",",$headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";
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
				exec('cd '.getcwd().'/cache/query; touch '.md5($config).'.lock');
				$command = getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query; ../../resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config).' -p saveall='.md5($config.'R').':kmax=200 >/dev/null 2>&1; rm -f '.md5($config).'.lock; touch '.md5($config).'.fin" >/dev/null 2>&1 &';
				exec($command);
			}
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($in_process)
			{
				$must_wait = "YES";
				throw new \Exception('WAIT');
			}

			// Save learning model to DB, with predictions
			$is_cached_mysql = $dbml->query("SELECT id_learner FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			if ($tmp_result['id_learner'] != md5($config)) 
			{
				// register model to DB
				$query = "INSERT INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

				// read results of the CSV and dump to DB
				foreach (array("tt", "tv", "tr") as $value)
				{
					if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 1000, ",");

						$token = 0;
						$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,datanodes,vm_OS,vm_cores,vm_RAM,provider,vm_size,type,bench_type,hadoop_version,pred_time,id_learner,instance,predict_code) VALUES ";
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$specific_instance = implode(",",array_slice($data, 2, 21));
							$specific_data = implode(",",$data);
							$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
							$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
							$specific_data = str_replace(",","','",$specific_data);

							$query_var = "SELECT count(*) as num FROM aloja_ml.predictions WHERE instance = '".$specific_instance."' AND id_learner = '".md5($config)."'";
							$result = $dbml->query($query_var);
							$row = $result->fetch();
					
							// Insert instance values
							if ($row['num'] == 0)
							{
								if ($token != 0) { $query = $query.","; } $token = 1;
								$query = $query."('".$specific_data."','".md5($config)."','".$specific_instance."','".(($value=='tt')?3:(($value=='tv')?2:1))."') ";								
							}
						}

						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
						fclose($handle);
					}
					else throw new \Exception('Error on R processing. Result file '.md5($config).'-'.$value.'.csv not present');
				}

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.dat');
			}

			// Save minconfigs to DB, with props and centers
			$is_cached_mysql = $dbml->query("SELECT id_minconfigs FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."'");
			$tmp_result = $is_cached_mysql->fetch();
			if ($tmp_result['id_minconfigs'] != md5($config.'R')) 
			{
				// register minconfigs to DB
				$query = "INSERT INTO aloja_ml.minconfigs (id_minconfigs,id_learner,instance,model,dataslice)";
				$query = $query." VALUES ('".md5($config.'R')."','".md5($config)."','".$instance."','".substr($model_info,1)."','".$slice_info."');";
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
					$query = "INSERT INTO aloja_ml.minconfigs_props (id_minconfigs,cluster,MAE,RAE)";
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
						$query = "INSERT INTO aloja_ml.minconfigs_centers (id_minconfigs,cluster,id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,support)"; // FIXME - Bench_type and Hadoop Version NOT here yet
						$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$specific_data."','".$sizes[$i++]."');";
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving centers into DB');
					}
					fclose($handle);
				}
				fclose($handle_sizes);

				// Store file model to DB
				$filemodel = getcwd().'/cache/query/'.md5($config).'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config)."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				$filemodel = getcwd().'/cache/query/'.md5($config.'R').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file,reference) VALUES ('".md5($config.'R')."','minconf','".$content."','".md5($config)."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file minconf into DB');

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.rds');
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.rds');
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'.fin');
			}

			// Retrieve minconfig progression results from DB
			$header = "id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,support";
			$header_array = explode(",",$header);

			$last_y = 9E15;
			$configs = '[';

			$query = "SELECT cluster, MAE, RAE FROM aloja_ml.minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'";
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
				$query_2 = "SELECT ".$header." FROM aloja_ml.minconfigs_centers WHERE id_minconfigs='".md5($config.'R')."' AND cluster='".$cluster."'";
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

			$is_cached_mysql = $dbml->query("SELECT MAX(cluster) as mcluster, MAX(MAE) as mmae, MAX(RAE) as mrae FROM aloja_ml.minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'");
			$tmp_result = $is_cached_mysql->fetch();
			$max_x = ((float)$tmp_result['mmae'] > 0)?(float)$tmp_result['mmae']:(float)$tmp_result['mrae'];
			$max_y = (float)$tmp_result['mcluster'];
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonData = $jsonHeader = $configs = '[]';

		}
		$dbml = null;

		$return_params = array(
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'configs' => $configs,
			'max_p' => min(array($max_x,$max_y)),
			'instance' => $instance,
			'id_learner' => md5($config),
			'id_minconf' => md5($config.'R'),
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'must_wait' => $must_wait
		);
		return $this->render('mltemplate/mlminconfigs.html.twig', $return_params);
	}
}
