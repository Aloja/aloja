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
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier'));
	}

	public function mlpredictionAction()
	{
		$jsonExecs = $jsonLearners = $jsonLearningHeader = '[]';
		$message = $instance = $error_stats = $config = $model_info = $slice_info = '';
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

			if (array_key_exists('pass',$_GET))
			{
				$pass = $_GET["pass"];
				unset($_GET["pass"]);
			}

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
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

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
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp,array_values(array_merge($header_names,$added_names)),',','"');
			    	foreach($rows as $row)
				{
					$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
					fputcsv($fp, array_values($row),',','"');
				}

				// run the R processor
				exec('cd '.getcwd().'/cache/ml ; touch '.getcwd().'/cache/ml/'.md5($config).'.lock');
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
				// register model to DB
				$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

				// read results of the CSV and dump to DB
				foreach (array("tt", "tv", "tr") as $value)
				{
					if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-'.$value.'.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 1000, ",");

						$token = 0; $insertions = 0;
						$query = "INSERT IGNORE INTO aloja_ml.predictions (
							id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,
							id_cluster,datanodes,vm_OS,vm_cores,vm_RAM,provider,vm_size,type,bench_type,hadoop_version,
							datasize,scale_factor,
							net_maxtxkbs,net_maxrxkbs,net_maxtxpcks,net_maxrxpcks,net_maxtxcmps,net_maxrxcmps,net_maxrxmscts,
							disk_maxtps,disk_maxsvctm,disk_maxrds,disk_maxwrs,disk_maxrqsz,disk_maxqusz,disk_maxawait, disk_maxutil,
							pred_time,id_learner,instance,predict_code) VALUES ";
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							$specific_instance = implode(",",array_slice($data, 2, 36));
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
								if ($token != 0) { $query = $query.","; } $token = 1; $insertions = 1;
								$query = $query."('".$specific_data."','".md5($config)."','".$specific_instance."','".(($value=='tt')?3:(($value=='tv')?2:1))."') ";								
							}
						}
						if ($insertions > 0)
						{
							if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
 						}
						fclose($handle);
					}
					else throw new \Exception('Error on R processing. Result file '.md5($config).'-'.$value.'.csv not present');
				}

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
