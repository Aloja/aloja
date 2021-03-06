<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLFindAttributesController extends AbstractController
{
	public function __construct($container)
	{
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier','money'));
	}

	public function mlfindattributesAction()
	{
		$current_model = $model_info = $instance = $instances = $message = $tree_descriptor = $model_html = $config = '';
		$possible_models = $possible_models_id = $other_models = array();
		$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
		$jsonFAttrs = $jsonFAttrsHeader = '[]';
		$mae = $rae = 0;
		$must_wait = 'NO';
		$legacy_params = "";
		$is_legacy = 0;
		try
		{
			$dbml = MLUtils::getMLDBConnection($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		    	$db = $this->container->getDBUtils();

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			if (array_key_exists('dump',$_GET)) { $dump = $_GET["dump"]; unset($_GET["dump"]); }
			if (array_key_exists('pass',$_GET)) { $pass = $_GET["pass"]; unset($_GET["pass"]); }

			$this->buildFilters(array(
				'bench_type' => array('default' => array('HiBench'), 'type' => 'selectOne'),
				'current_model' => array(
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
					'filterGroup' => 'MLearning'
				), 'unseen' => array(
					'type' => 'checkbox',
					'default' => 1,
					'label' => 'Predict with unseen atributes &#9888;',
					'parseFunction' => function() {
						$choice = (isset($_GET['unseen']) && !isset($_GET['unseen'])) ? 0 : 1;
						return array('whereClause' => '', 'currentChoice' => $choice);
					},
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
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','unseen'))));

			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$learnParams = $this->filters->getFiltersSelectedChoices(array('current_model','unseen'));
			$param_current_model = $learnParams['current_model'];
			$unseen = ($learnParams['unseen']) ? true : false;

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, $unseen);
			if (!$instructions)
			{
				$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, $unseen);
				$instances = MLUtils::generateInstances($this->filters,$param_names, $params, $unseen, $db);
			}

			// Model for filling
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

				MLUtils::getIndexFAttrs ($jsonFAttrs, $jsonFAttrsHeader, $dbml);

				$this->filters->setCurrentChoices('current_model',array_merge($possible_models_id,array('---Other models---'),$other_models));
				return $this->render('mltemplate/mlfindattributes.html.twig', array('fattrs' => $jsonFAttrs, 'header_fattrs' => $jsonFAttrsHeader, 'models' => $model_html,'instructions' => 'YES'));
			}

			if (!empty($possible_models_id) || $current_model != "")
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
				$config = $instance.'-'.$current_model.'-'.(($unseen)?'U':'R');

				$is_cached_mysql = $dbml->query("SELECT count(*) as total FROM aloja_ml.trees WHERE id_findattrs = '".md5($config)."'");
				$tmp_result = $is_cached_mysql->fetch();
				$is_cached = ($tmp_result['total'] > 0);

				$tmp_file = md5($config).'.tmp';

				$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
				$finished_process = $in_process && ((int)shell_exec('ls '.getcwd().'/cache/ml/'.md5($config).'-*.lock | wc -w ') == count($instances));

				if (!$in_process && !$finished_process && !$is_cached)
				{
					// Check for Legacy
					$query = "SELECT legacy FROM aloja_ml.learners WHERE id_learner='".$current_model."';";
					$result = $dbml->query($query);
					$row = $result->fetch();
					if ($row['legacy'] == 1) 
					{
						$legacy_params .= ':vin=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor';
						$legacy_params .= ':vinst=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor';
						$is_legacy = 1;
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

					// Run the predictor
					exec('cd '.getcwd().'/cache/ml ; touch '.md5($config).'.lock ; rm -f '.$tmp_file);
					if ($is_legacy == 1) exec('touch '.getcwd().'/cache/ml/'.md5($config).'.legacy');
					$count = 1;
					foreach ($instances as $inst)
					{
						exec(getcwd().'/resources/queue -d -c "cd '.getcwd().'/cache/ml ; ../../resources/aloja_cli.r -m aloja_predict_instance_slice -l '.$current_model.' -p inst_predict=\''.$inst.'\':saveall=\''.md5($config).'-'.($count).'\''.$legacy_params .' 2>/dev/null; touch '.md5($config).'-'.($count++).'.lock" >/dev/null 2>&1 &');
					}

				}
				$finished_process = ((int)shell_exec('ls '.getcwd().'/cache/ml/'.md5($config).'-*.lock | wc -w ') == count($instances));

				if ($finished_process && !$is_cached)
				{
					if (file_exists(getcwd().'/cache/ml/'.md5($config).'.legacy')) $is_legacy = 1;
					if ($is_legacy == 1) $legacy_params = ':vin=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor';

					shell_exec('cd '.getcwd().'/cache/ml/; head -n 1 '.md5($config).'-1-predictions.data > '.md5($config).'-predictions.data');
					for ($i = 0; $i < count($instances); $i++)
					{
						shell_exec('cd '.getcwd().'/cache/ml/; tail -n +2 '.md5($config).'-'.($i+1).'-predictions.data >> '.md5($config).'-predictions.data');
					}

					if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-predictions.data', "r")) !== FALSE)
					{
						$header = fgetcsv($handle, 5000, ",");
						while (($line = fgetcsv($handle, 5000, ",")) !== FALSE)
						{
							if ($line=='') break;

							// INSERT INTO DB <INSTANCE>
							$selected = array_merge(array_slice($line,1,10),array_slice($line,18,4));
							$selected_inst = implode("','",$selected);
							$selected_inst = preg_replace('/,\'Cmp(\d+)\',/',',\'${1}\',',$selected_inst);
							$selected_inst = preg_replace('/,\'Cl(\d+)\',/',',\'${1}\',',$selected_inst);
							$predicted = implode('',array_slice($line,-1,1));
							$query = "INSERT IGNORE INTO aloja_ml.pred_execs (bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,bench_type,hadoop_version,datasize,scale_factor,start_time,end_time) VALUES ";
							$query = $query."('".$selected_inst."',now(),now())";
							if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');

							// GET REFERENCE IDs
							$where_clauses = '1=1';
							$where_names = array("bench","net","disk","maps","iosf","replication","iofilebuf","comp","blk_size","id_cluster","bench_type","hadoop_version","datasize","scale_factor");
							$selcount = 0;
							foreach($where_names as $wn) $where_clauses = $where_clauses.' AND '.$wn.' = \''.$selected[$selcount++].'\'';
							$where_clauses = preg_replace('/\'Cmp(\d+)\'/','\'${1}\'',$where_clauses);
							$where_clauses = preg_replace('/\'Cl(\d+)\'/','\'${1}\'',$where_clauses);

							$query = "SELECT id_prediction FROM aloja_ml.pred_execs WHERE ".$where_clauses.' LIMIT 1';
							$result = $dbml->query($query);
							$row = $result->fetch();
							$predid = (is_null($row['id_prediction']))?0:$row['id_prediction'];

							$query = "SELECT id_exec, AVG(exe_time) as AVG FROM aloja2.execs WHERE ".$where_clauses.' GROUP BY id_exec LIMIT 1';
							$result = $dbml->query($query);
							$row = $result->fetch();
							$execid = (is_null($row['id_exec']))?0:$row['id_exec'];
							$exectime = (is_null($row['AVG']))?0:$row['AVG'];
							
							// INSERT INTO DB <PREDICTION>
							$full_instance = implode(",",array_slice($line,1,-1));
							$current_instance = implode(",",array_slice($line,1,21));
							$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,id_pred_exec,exe_time,pred_time,id_learner,instance,full_instance,predict_code) VALUES ";
							$query = $query."('".$execid."','".$predid."','".$exectime."','".$predicted."','".$current_model."','".$current_instance."','".$full_instance."',0) ";
							if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
						}
						fclose($handle);

						// Descriptive Tree
						$tree_descriptor = shell_exec(getcwd().'/resources/aloja_cli.r -m aloja_representative_tree -p method=ordered:pred_file="'.getcwd().'/cache/ml/'.md5($config).'":output=nodejson:vout="Prediction"'.$legacy_params.' -v 2> /dev/null');
						$tree_descriptor = substr($tree_descriptor, 5, -2);
						$tree_descriptor = str_replace("\\\"","\"",$tree_descriptor);
						$tree_descriptor = str_replace("desc:\"\"","desc:\"---\"",$tree_descriptor);
						$query = "INSERT IGNORE INTO aloja_ml.trees (id_findattrs,id_learner,instance,model,tree_code) VALUES ('".md5($config)."','".$current_model."','".$instance."','".$model_info."','".$tree_descriptor."')";

						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving tree into DB');
					}

					// remove remaining locks and temporal files
					shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.lock'); 
					shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.data');
					shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.legacy');

					$is_cached = true;
				}

				if (!$is_cached)
				{
					$must_wait = 'YES';
					if (isset($dump)) { $dbml = null; echo "1"; exit(0); }
					if (isset($pass)) { $dbml = null; return "1"; }
					throw new \Exception('WAIT');
				}

				if (isset($pass) && $pass == 2) { $dbml = null; return "2"; }

				// Fetch results and compose JSON
				$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Datanodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Bench.Type','Version','Datasize','Scale.Factor','Prediction','Observed');
				$jsonHeader = '[{title:""}';
				foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
				$jsonHeader = $jsonHeader.']';

				$query = "SELECT @i:=@i+1 as num, p.instance, AVG(p.pred_time) as pred_time, AVG(p.exe_time) as exe_time
					  FROM aloja_ml.predictions AS p, aloja_ml.pred_execs as e, (SELECT @i:=0) AS d
					  WHERE p.id_pred_exec = e.id_prediction AND p.id_learner='".$current_model."' ".$where_configs."
					  GROUP BY p.instance";

				$result = $dbml->query($query);
				$jsonData = '[';
				foreach ($result as $row)
				{
					if ($jsonData!='[') $jsonData = $jsonData.',';
					$jsonData = $jsonData."['".$row['num']."','".implode("','",array_slice(explode(",",$row['instance']),0,21))."','".$row['pred_time']."','".$row['exe_time']."']";
				}
				$jsonData = $jsonData.']';

				foreach (range(1,33) as $value) $jsonData = str_replace('Cmp'.$value,Utils::getCompressionName($value),$jsonData);

				// Fetch MAE & RAE values
				$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE FROM aloja_ml.predictions AS e WHERE id_learner='".md5($config)."' AND predict_code > 0";
				$result = $dbml->query($query);
				$row = $result->fetch();
				$mae = $row['MAE'];
				$rae = $row['RAE'];

				// Dump case
				if (isset($dump))
				{
					echo "ID".str_replace(array("[","]","{title:\"","\"}"),array('','',''),$jsonHeader)."\n";
					echo str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonData);

					$dbml = null;
					exit(0);
				}
				if (isset($pass) && $pass == 1)
				{
					$retval = "ID".str_replace(array("[","]","{title:\"","\"}"),array('','',''),$jsonHeader)."\n";
					$retval .= str_replace(array('],[','[[',']]'),array("\n",'',''),$jsonData);

					$dbml = null;
					return $retval;
				}

				// Display Descriptive Tree
				$query = "SELECT tree_code FROM aloja_ml.trees WHERE id_findattrs = '".md5($config)."'";
				$result = $dbml->query($query);
				$row = $result->fetch();
				$tree_descriptor = $row['tree_code'];			
			}
			else
			{
				if (isset($dump)) { echo "-1"; exit(0); }
				if (isset($pass)) { return "-1"; }
				throw new \Exception("There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section.");
			}
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}

			$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
			$instances = array();
			if (isset($pass)) { return "-2"; }
		}
		$dbml = null;

		$return_params = array(
			'instance' => $instance,
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'fattrs' => $jsonFAttrs,
			'header_fattrs' => $jsonFAttrsHeader,
			'models' => $model_html,
			'models_id' => $possible_models_id,
			'other_models_id' => $other_models,
			'current_model' => $current_model,
			'mae' => $mae,
			'rae' => $rae,
			'must_wait' => $must_wait,
			'instance' => $instance,
			'instances' => implode("<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;",$instances),
			'model_info' => $model_info,
			'id_findattr' => md5($config),
			'tree_descriptor' => $tree_descriptor,
		);
		$this->filters->setCurrentChoices('current_model',array_merge($possible_models_id,array('---Other models---'),$other_models));
		return $this->render('mltemplate/mlfindattributes.html.twig', $return_params);
	}

	public function mlobservedtreesAction()
	{
		$model_info = $instance = $slice_info = $message = $config = $tree_descriptor_ordered = $tree_descriptor_gini = '';
		$jsonData = $jsonHeader = '[]';
		$jsonObstrees = $jsonObstreesHeader = '[]';
		$must_wait = 'NO';
		try
		{
			$dbml = MLUtils::getMLDBConnection($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		    	$db = $this->container->getDBUtils();

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			$this->buildFilters(array(
				'bench_type' => array('default' => array('HiBench'), 'type' => 'selectOne'),
				'minexetime' => array('default' => 0),
				'valid' => array('default' => 0),
				'filter' => array('default' => 0),
				'prepares' => array('default' => 1)
			));

			if ($instructions)
			{
				MLUtils::getIndexObsTrees ($jsonObstrees, $jsonObstreesHeader, $dbml);
				return $this->render('mltemplate/mlobstrees.html.twig', array('obstrees' => $jsonObstrees, 'header_obstrees' => $jsonObstreesHeader,'jsonData' => '[]','jsonHeader' => '[]', 'instructions' => 'YES'));
			}

			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, TRUE);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, TRUE);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);
			$config = $instance.'-'.$slice_info.'-obstree';

			$is_cached_mysql = $dbml->query("SELECT count(*) as total FROM aloja_ml.observed_trees WHERE id_obstrees = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['total'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

			$tmp_file = getcwd().'/cache/ml/'.md5($config).'.tmp';

			// get headers for csv
			$header_names = array(
				'bench' => 'Benchmark','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
				'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster',
				'datanodes' => 'Datanodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
				'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Service.Type','bench_type' => 'Bench.Type','hadoop_version' => 'Hadoop.Version',
				'IFNULL(datasize,0)' =>'Datasize','scale_factor' => 'Scale.Factor'
			);
			$special_header_names = array('id_exec' => 'ID','exe_time' => 'Exe.Time');

			$headers = array_keys($header_names);
			$special_headers = array_keys($special_header_names);

			if (!$in_process && !$finished_process && !$is_cached)
			{
				// Dump the DB slice to csv
				$query = "SELECT ".implode(",",$headers).", ".implode(",",$special_headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";
			    	$rows = $db->get_rows($query);
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				if (($key = array_search('e.id_cluster', $headers)) !== false) $headers[$key] = 'id_cluster';

				$fp = fopen($tmp_file, 'w');
			    	foreach($rows as $row)
				{
					$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...

					$row['bench'] = str_replace(" ","_",$row['bench']);		// Problem with ADW and ADL with spaces in tags...

					$line = '';
					foreach ($headers as $hn) $line = $line.(($line != '')?',':'').$row[$hn];
					$line = $row['id_exec'].' '.$line.' '.$row['exe_time']."\n";
					fputs($fp, $line);
				}
				fclose($fp);

				if (($key = array_search('id_cluster', $headers)) !== false) $headers[$key] = 'e.id_cluster';

				// Execute R Engine
				$exe_query = 'cd '.getcwd().'/cache/ml;';
				$exe_query = $exe_query.' touch '.md5($config).'.lock;';
				$exe_query = $exe_query.' ../../resources/aloja_cli.r -m aloja_representative_tree -p method=ordered:dump_file='.$tmp_file.':output=nodejson -v >'.md5($config).'-split.dat 2>/dev/null;';
				$exe_query = $exe_query.' ../../resources/aloja_cli.r -m aloja_representative_tree -p method=gini:dump_file='.$tmp_file.':output=nodejson -v >'.md5($config).'-gini.dat 2>/dev/null;';
				$exe_query = $exe_query.' rm -f '.md5($config).'.lock; rm -f '.$tmp_file.'; touch '.md5($config).'.fin';
				exec(getcwd().'/resources/queue -d -c "'.$exe_query.'" >/dev/null 2>&1 &');
			}

			if (!$is_cached)
			{
				$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

				if ($finished_process)
				{
					// Read results and dump to DB	
					$tree_descriptor_ordered = '';
					try
					{
						$file = fopen(getcwd().'/cache/ml/'.md5($config).'-split.dat', "r");
						$tree_descriptor_ordered = fgets($file);
						$tree_descriptor_ordered = substr($tree_descriptor_ordered, 5, -2);
						$tree_descriptor_ordered = str_replace("\\\"","\"",$tree_descriptor_ordered);
						$tree_descriptor_ordered = str_replace("desc:\"\"","desc:\"---\"",$tree_descriptor_ordered);
						fclose($file);
					} catch (\Exception $e) { throw new \Exception ("Error on retrieving result file. Check that R is working properly."); }

					$tree_descriptor_gini = '';
/*					try
					{
						$file = fopen(getcwd().'/cache/ml/'.md5($config).'-gini.dat', "r");
						$tree_descriptor_gini = fgets($file);
						$tree_descriptor_gini = substr($tree_descriptor_gini, 5, -2);
						$tree_descriptor_gini = str_replace("\\\"","\"",$tree_descriptor_gini);
						fclose($file);
					} catch (\Exception $e) { throw new \Exception ("Error on retrieving result file. Check that R is working properly."); }
*/
					$query = "INSERT INTO aloja_ml.observed_trees (id_obstrees,instance,model,dataslice,tree_code_split,tree_code_gain) VALUES ";
					$query = $query."('".md5($config)."','".$instance."','".$model_info."','".$slice_info."','".$tree_descriptor_ordered."','".$tree_descriptor_gini."')";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving tree into DB');

					// Remove temporal files
					$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'-*.dat');
					$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'.fin');
				}
				else
				{
					$must_wait = 'YES';
					throw new \Exception('WAIT');
				}
			}

			// Fetch results and compose JSON
			$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Datanodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Bench.Type','Version','Datasize','Scale.Factor','Observed');
			$jsonHeader = '[{title:""}';
			foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
			$jsonHeader = $jsonHeader.']';

			// Fetch observed values
			$query = "SELECT ".implode(",",$headers).", ".implode(",",$special_headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";
		    	$rows = $db->get_rows($query);
			if (empty($rows)) throw new \Exception('No data matches with your critteria.');

			if (($key = array_search('e.id_cluster', $headers)) !== false) $headers[$key] = 'id_cluster';

			$jsonData = '[';
			foreach($rows as $row)
			{
				$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
				$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...

				$line = '';
				foreach ($headers as $hn) $line = $line.(($line != '')?',':'').$row[$hn];
				$line = $row['id_exec'].','.$line.','.$row['exe_time'];

				if ($jsonData!='[') $jsonData = $jsonData.',';
				$jsonData = $jsonData."['".str_replace(",","','",$line)."']";

			}
			$jsonData = $jsonData.']';
			foreach (range(1,32) as $value) $jsonData = str_replace('Cmp'.$value,Utils::getCompressionName($value),$jsonData);

			if ($tree_descriptor_ordered == '')
			{
				// Display Descriptive Tree, if not processed yet
				$query = "SELECT tree_code_split, tree_code_gain FROM aloja_ml.observed_trees WHERE id_obstrees = '".md5($config)."'";
				$result = $dbml->query($query);
				$row = $result->fetch();
				$tree_descriptor_ordered = $row['tree_code_split'];
				$tree_descriptor_gini = $row['tree_code_gain'];
			}
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonData = $jsonHeader = '[]';
		}
		$dbml = null;

		$return_params = array(
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'obstrees' => $jsonObstrees,
			'header_obstrees' => $jsonObstreesHeader,
			'must_wait' => $must_wait,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'id_obstrees' => md5($config),
			'tree_descriptor_ordered' => $tree_descriptor_ordered,
			'tree_descriptor_gini' => $tree_descriptor_gini,
		);
		return $this->render('mltemplate/mlobstrees.html.twig', $return_params);
	}
}
?>
