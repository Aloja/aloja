<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLNewconfigsController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function read_params($item_name)
	{
		if (isset($_GET[$item_name]))
		{
			$items = $_GET[$item_name];
			if (($key = array_search('None', $items)) !== false) unset ($items[$key]);
		}
		else $items = array();
	
		return $items;
	}

	public function add_where_configs($item_name, &$where_configs)
	{
		$items = MLNewconfigsController::read_params($item_name);
		if ($items) $where_configs .= ' AND '.$item_name.' IN ("'.join('","', $items).'")';
		return;	
	}

	public function getFilterOptions($dbUtils)
	{
		$options['bench'] = $dbUtils->get_rows("SELECT DISTINCT bench FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
		$options['net'] = $dbUtils->get_rows("SELECT DISTINCT net FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY net ASC");
		$options['disk'] = $dbUtils->get_rows("SELECT DISTINCT disk FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY disk ASC");
		$options['blk_size'] = $dbUtils->get_rows("SELECT DISTINCT blk_size FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY blk_size ASC");
		$options['comp'] = $dbUtils->get_rows("SELECT DISTINCT comp FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY comp ASC");
		$options['id_cluster'] = $dbUtils->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name from aloja2.execs e JOIN aloja2.clusters c using (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
		$options['maps'] = $dbUtils->get_rows("SELECT DISTINCT maps FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY maps ASC");
		$options['replication'] = $dbUtils->get_rows("SELECT DISTINCT replication FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY replication ASC");
		$options['iosf'] = $dbUtils->get_rows("SELECT DISTINCT iosf FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iosf ASC");
		$options['iofilebuf'] = $dbUtils->get_rows("SELECT DISTINCT iofilebuf FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iofilebuf ASC");
		$options['datanodes'] = $dbUtils->get_rows("SELECT DISTINCT datanodes FROM aloja2.execs e JOIN aloja2.clusters USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datanodes ASC");
		$options['benchtype'] = $dbUtils->get_rows("SELECT DISTINCT bench_type FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench_type ASC");
		$options['vm_size'] = $dbUtils->get_rows("SELECT DISTINCT vm_size FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_size ASC");
		$options['vm_cores'] = $dbUtils->get_rows("SELECT DISTINCT vm_cores FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_cores ASC");
		$options['vm_RAM'] = $dbUtils->get_rows("SELECT DISTINCT vm_RAM FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_RAM ASC");
		$options['hadoop_version'] = $dbUtils->get_rows("SELECT DISTINCT hadoop_version FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY hadoop_version ASC");
		$options['type'] = $dbUtils->get_rows("SELECT DISTINCT type FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY type ASC");
		$options['presets'] = $dbUtils->get_rows("SELECT * FROM aloja2.filter_presets ORDER BY short_name DESC");
		$options['provider'] = $dbUtils->get_rows("SELECT DISTINCT provider FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY provider DESC;");
		$options['vm_OS'] = $dbUtils->get_rows("SELECT DISTINCT vm_OS FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_OS DESC;");
		return $options;
	}

	public function mlnewconfigsAction()
	{
		$jsonData = $jsonHeader = $configs = '[]';
		$message = $instance = $config = $model_info = '';
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	$where_configs = '';

			// Where_Configs and Manual Presets
			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('learn',$_GET)))
			{
				$_GET['id_cluster'] = $params['id_cluster'] = array('3','5','8'); $where_configs .= ' AND id_cluster IN (3,5,8)';
				//$_GET['bench'] = $params['bench'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				//$_GET['disk'] = $params['disk'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$_GET['blk_size'] = $params['blk_size'] = array('64','128','256'); $where_configs .= ' AND blk_size IN ("64","128","256")';
				$_GET['iofilebuf'] = $params['iofilebuf'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$_GET['comp'] = $params['comp'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$_GET['replication'] = $params['replication'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				//$_GET['hadoop_version'] = $params['hadoop_version'] = array('1','1.03','2'); $where_configs .= ' AND hadoop_version IN ("1","1.03","2")';
				//$_GET['bench_type'] = $params['bench_type'] = array('HiBench'); $where_configs .= ' AND bench_type IN ("HiBench")';

				$_GET['datanodes'] = $params['datanodes'] = array('3');// $where_configs .= ' AND datanodes = 3';
				$_GET['vm_OS'] = $params['vm_OS'] = array('linux');// $where_configs .= ' AND vm_OS = "linux"';				
				$_GET['vm_size'] = $params['vm_size'] = array('SYS-6027R-72RF');// $where_configs .= ' AND vm_size = "SYS-6027R-72RF"';
				$_GET['vm_cores'] = $params['vm_cores'] = array('12');// $where_configs .= ' AND vm_cores = 12';
				$_GET['vm_RAM'] = $params['vm_RAM'] = array('128');// $where_configs .= ' AND vm_RAM = 128';
				$_GET['type'] = $params['type'] = array('On-premise');// $where_configs .= ' AND type = "On-premise"';
				$_GET['provider'] = $params['provider'] = array('on-premise');// $where_configs .= ' AND provider = "on-premise"';
			}
			else
			{
				$param_names_whereconfig = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','bench_type','hadoop_version');
				foreach ($param_names_whereconfig as $p) MLNewconfigsController::add_where_configs($p,$where_configs);
			}

			// Real fetching of parameters
			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version'); // Order is important
			foreach ($param_names as $p) { $params[$p] = MLNewconfigsController::read_params($p); sort($params[$p]); }

			$learn_param = (array_key_exists('learn',$_GET))?$_GET['learn']:'regtree';
			$param_id_cluster = $params['id_cluster']; unset($params['id_cluster']); // Exclude the param from now on

			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// Semi-Dummy Filters (For ModelInfo and SimpleInstance)
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
			)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('learn'))));

			// compose instance
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true, true);
			$param_names_aux = array_diff($param_names, array('id_cluster'));
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names_aux, $params, true, true);

			$config = $model_info.' '.$learn_param.' newminconfs';

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options ='kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options = 'ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config."M")."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."' AND id_learner = '".md5($config."M")."'");
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
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size',
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
					//$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
					fputcsv($fp, array_values($row),',','"');
				}

				// run the R processor
				exec('cd '.getcwd().'/cache/query; touch '.md5($config).'.lock');
				$command = getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query; ../../resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."F").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_predict_instance -l '.md5($config."F").' -p inst_predict=\''.$instance.'\':saveall='.md5($config."D").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -d '.md5($config."D").'-dataset.data -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."M").':vin=\'Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version\' >/dev/null 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config."M").' -p saveall='.md5($config.'R').':kmax=200 >/dev/null 2>&1; rm -f '.md5($config).'.lock; touch '.md5($config).'.fin" >debug4.tmp 2>&1 &';
				exec($command);

				sleep(2);
			}
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($in_process)
			{
				$must_wait = "YES";
				throw new \Exception('WAIT');
			}

			$learners = array();
			$learners[] = md5($config."F");
			$learners[] = md5($config."M");
			foreach ($learners as $learner_1)
			{
				// Save learning model to DB, with predictions
				$is_cached_mysql = $dbml->query("SELECT id_learner FROM aloja_ml.learners WHERE id_learner = '".$learner_1."'");
				$tmp_result = $is_cached_mysql->fetch();
				if ($tmp_result['id_learner'] != $learner_1) 
				{
					// register model to DB
					$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm)";
					$query = $query." VALUES ('".$learner_1."','".$instance."','".substr($model_info,1)."','".$learn_param."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

					// read results of the CSV and dump to DB
					foreach (array("tt", "tv", "tr") as $value)
					{
						if (($handle = fopen(getcwd().'/cache/query/'.$learner_1.'-'.$value.'.csv', 'r')) !== FALSE)
						{
							$header = fgetcsv($handle, 1000, ",");

							$token = 0;
							$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,datanodes,headnodes,vm_OS,vm_cores,vm_RAM,provider,vm_size,type,bench_type,pred_time,id_learner,instance,predict_code) VALUES ";
							while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
							{
								$specific_instance = implode(",",array_slice($data, 2, 20));
								$specific_data = implode(",",$data);
								$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
								$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
								$specific_data = str_replace(",","','",$specific_data);

								$query_var = "SELECT count(*) as num FROM aloja_ml.predictions WHERE instance = '".$specific_instance."' AND id_learner = '".$learner_1."'";
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
			$is_cached_mysql = $dbml->query("SELECT id_minconfigs FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."'");
			$tmp_result = $is_cached_mysql->fetch();
			if ($tmp_result['id_minconfigs'] != md5($config.'R')) 
			{
				// register minconfigs to DB
				$query = "INSERT IGNORE INTO aloja_ml.minconfigs (id_minconfigs,id_learner,instance,model,is_new)";
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
						$query = "INSERT INTO aloja_ml.minconfigs_centers (id_minconfigs,cluster,id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,bench_type,support)";
						$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$specific_data."','".$sizes[$i++]."');";
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving centers into DB');
					}
					fclose($handle);
				}
				fclose($handle_sizes);

				// Store file model to DB
				$filemodel = getcwd().'/cache/query/'.md5($config.'F').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'F')."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				$filemodel = getcwd().'/cache/query/'.md5($config.'M').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'M')."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				$filemodel = getcwd().'/cache/query/'.md5($config.'R').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'R')."','minconf','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file minconf into DB');

				// Remove temporal files
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.rds');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.dat');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'R').'*.csv');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'D').'*.csv');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'D').'*.dat');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'D').'*.data');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'F').'*.rds');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'F').'*.csv');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'F').'*.dat');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'M').'*.rds');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'M').'*.csv');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config.'M').'*.dat');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.csv');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.dat');
				exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.fin');
			}

			// Retrieve minconfig progression results from DB
			$header = "id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,bench_type,support";
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
			$jsonHeader = '[{title:""},{title:"Est.Time"},{title:"Benchmark"},{title:"Network"},{title:"Disk"},{title:"Maps"},{title:"IO.SF"},{title:"Replicas"},{title:"IO.FBuf"},{title:"Compression"},{title:"Blk.Size"},{title:"Bench.Type"},{title:"Support"}]';

			$query = "SELECT MAX(cluster) as mcluster, MAX(MAE) as mmae, MAX(RAE) as mrae FROM aloja_ml.minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'";
			$is_cached_mysql = $dbml->query($query);

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

		$params['id_cluster'] = $param_id_cluster;
		$return_params = array(
			'selected' => 'mlnewconfigs',
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'configs' => $configs,
			'max_p' => min(array($max_x,$max_y)),
			'instance' => $instance,
			'id_newconf' => md5($config),
			'id_newconf_first' => md5($config.'F'),
			'id_newconf_dataset' => md5($config.'D'),
			'id_newconf_model' => md5($config.'M'),
			'id_newconf_result' => md5($config.'R'),
			'model_info' => $model_info,
			'learn' => $learn_param,
			'must_wait' => $must_wait,
			'options' => MLNewconfigsController::getFilterOptions($db)
		);
		foreach ($param_names as $p) $return_params[$p] = $params[$p];
		echo $this->container->getTwig()->render('mltemplate/mlnewconfigs.html.twig', $return_params);	
	}
}
