<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class MLTemplatesController extends AbstractController
{
	public function mlpredictionAction()
	{
		$jsonExecs = array();
		$instance = '';
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

			$filter_options = Utils::getFilterOptions($db);
			$paramAllOptions = $tokens = array();
 			$model_info = '';
			foreach ($param_names as $p) 
			{
				if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
				if ($unrestricted) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
				else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	

				$tokens[$p] = '';
				if ($unrestricted && empty($params[$p])) { $tokens[$p] = '*'; }
				elseif (!$unrestricted && empty($params[$p])) { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
				else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
				$instance = $instance.(($instance=='')?'':',').$tokens[$p];
 			}

			$config = $model_info.' '.$learn_param;
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';
			$in_process = shell_exec('ps aux | grep "'.(str_replace('*','\*',$learn_method.' -p '.$learn_options)).'" | grep -v grep');

			if (file_exists($cache_ds) && $in_process == NULL)
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
				if (empty($rows)) throw new Exception('No data matches with your critteria.');
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

				// run the R processor
				$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null &';
				exec($command);

				// update cache record (for human reading)
				$register = md5($config).' :'.$config."\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			$in_process = shell_exec('ps aux | grep "'.(str_replace('*','\*',$learn_method.' -p '.$learn_options)).'" | grep -v grep');
			$must_wait = "NO";

			if ($in_process != NULL)
			{
				$jsonExecs = "[]";
				$must_wait = "YES";
				$max_x = $max_y = 0;
			}
			else
			{
				// read results of the CSV
				$count = 0;
				$max_x = $max_y = 0;
				foreach (array("tt", "tv", "tr") as &$value)
				{
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
				'options' => Utils::getFilterOptions($db)
			)
		);
	}

	public function mldatacollapseAction()
	{
		$instance = '';
		try
		{
		    	$db = $this->container->getDBUtils();
		    	
		    	$configurations = array();	// Useless here
		    	$where_configs = '';
		    	$concat_config = "";		// Useless here

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,$configurations,$concat_config); sort($params[$p]); }

			$unseen = (array_key_exists('unseen',$_GET) && $_GET['unseen'] == 1);

			if (count($_GET) <= 1 || (count($_GET) == 2 && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('65536','131072'); $where_configs .= ' AND iofilebuf IN ("65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$unseen = FALSE;
			}

			$dims1 = ((empty($params['nets']))?'':'Net,').((empty($params['disks']))?'':'Disk,').((empty($params['blk_sizes']))?'':'Blk.size,').((empty($params['comps']))?'':'Comp,');
			$dims1 = $dims1.((empty($params['id_clusters']))?'':'Cluster,').((empty($params['mapss']))?'':'Maps,').((empty($params['replications']))?'':'Rep,').((empty($params['iosfs']))?'':'IO.SFac,').((empty($params['iofilebufs']))?'':'IO.FBuf');
			if (substr($dims1, -1) == ',') $dims1 = substr($dims1,0,-1);

			$dims2 = "Benchmark";
			$dname1 = "Configuration";
			$dname2 = "Benchmark";

			// compose instance
			$filter_options = Utils::getFilterOptions($db);
			$paramAllOptions = $tokens = array();
 			$model_info = '';
			foreach ($param_names as $p) 
			{
				if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
				if ($unseen) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
				else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
 			
 				$tokens[$p] = '';
				if ($unseen && empty($params[$p])) { $tokens[$p] = '*'; }
				elseif (!$unseen && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
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

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			if ($current_model != "") $model = $current_model;
			else $current_model = $model = $possible_models_id[0];

			$learning_model = '';
			if (file_exists(getcwd().'/cache/query/'.$model.'-object.rds')) $learning_model = ':model_name='.$model.':inst_general="'.$instance.'"';

			$config = $dims1.'-'.$dims2.'-'.$dname1.'-'.$dname2."-".$model.'-'.$model_info;
			$options = 'dimension1="'.$dims1.'":dimension2="'.$dims2.'":dimname1="'.$dname1.'":dimname2="'.$dname2.'":saveall='.md5($config).$learning_model;

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';
			$in_process = shell_exec('ps aux | grep "'.(str_replace(array('*','"'),array('\*',''),'aloja_dataset_collapse_expand -d '.$cache_ds.' -p '.$options)).'" | grep -v grep');

			if (file_exists($cache_ds) && $in_process == NULL)
			{
				$keep_cache = TRUE;
				foreach (array("ids.csv", "matrix.csv", "object.rds") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config).'-'.$value);
				}
				if (!$keep_cache)
				{
					unlink($cache_ds);
					shell_exec("sed -i '/".md5($config)." : ".$config."/d' ".getcwd()."/cache/query/record.data");
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

				// prepare collapse
				$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_dataset_collapse_expand -d '.$cache_ds.' -p '.$options.' > /dev/null &';
				exec($command);

				// update cache record (for human reading)
				$register = md5($config).' : '.$config."\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			$in_process = shell_exec('ps aux | grep "'.(str_replace(array('*','"'),array('\*',''),'aloja_dataset_collapse_expand -d '.$cache_ds.' -p '.$options)).'" | grep -v grep');
			$must_wait = 'NO';

			if ($in_process != NULL)
			{
				$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
				$must_wait = 'YES';
			}
			else
			{
				// read results of the CSV
				if (	($handle = fopen(getcwd().'/cache/query/'.md5($config).'-cmatrix.csv', 'r')) !== FALSE
				&&	($handid = fopen(getcwd().'/cache/query/'.md5($config).'-cids.csv', 'r')) !== FALSE )
				{
					$header = fgetcsv($handle, 1000, ",");
					$headid = fgetcsv($handid, 1000, ",");

					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					$jsonColumns = '[';
					for ($i = 1; $i <= count($header); $i++)
					{
						if ($jsonColumns != '[') $jsonColumns = $jsonColumns.',';
						$jsonColumns = $jsonColumns.$i;
					}
					$jsonColumns = $jsonColumns.']';

					$jsonData = '[';
					$jsonColor = '[';
					while (	($data = fgetcsv($handle, 1000, ",")) !== FALSE
					&&	($daid = fgetcsv($handid, 1000, ",")) !== FALSE )
					{
						$data = str_replace('NA','',$data);
						if ($jsonData!='[') $jsonData = $jsonData.',';
						$jsonData = $jsonData.'[\''.implode("','",$data).'\']';


						$aux = array();
						for ($j = 0; $j < count($daid); $j++) $aux[$j] = ($daid[$j] == 'NA')?0:1;
						if ($jsonColor!='[') $jsonColor = $jsonColor.',';
						$jsonColor = $jsonColor.'[\''.implode("','",$aux).'\']';
					}
					$jsonColor = $jsonColor.']';
					$jsonData = $jsonData.']';
					fclose($handle);

					// negative prediction values (errors) are considered by default 100 as the minimal value...
					$jsonData = preg_replace('/(\-\d+\.\d+)/','100.0',$jsonData);
				}
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
			$possible_models = array();
			$possible_models_id = '';
		}
		echo $this->container->getTwig()->render('mltemplate/mldatacollapse.html.twig',
			array(
				'selected' => 'mldatacollapse',
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
				'jsonEncoded' => $jsonData,
				'jsonHeader' => $jsonHeader,
				'jsonColumns' => $jsonColumns,
				'jsonColor' => $jsonColor,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => '[\''.implode("','",$possible_models_id).'\']',
				'unseen' => $unseen,
				'current_model' => $current_model,
				'instance' => $instance,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}

	public function mlfindattributesAction()
	{
		$instance = '';
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

			if (count($_GET) <= 1 || (count($_GET) == 2 && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('wordcount'); $where_configs .= ' AND bench IN ("wordcount")';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('65536','131072'); $where_configs .= ' AND iofilebuf IN ("65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$unseen = FALSE;
			}

			$jsonData = $jsonHeader = "[]";
			$message = $instance = "";
			$possible_models = $possible_models_id = array();
			$mae = $rae = $count_preds = 0;

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			// compose instance
			$filter_options = Utils::getFilterOptions($db);
			$paramAllOptions = $tokens = array();
 			$model_info = '';
			foreach ($param_names as $p) 
			{
				if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
				if ($unseen) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
				else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
 			
 				$tokens[$p] = '';
				if ($unseen && empty($params[$p])) { $tokens[$p] = '*'; }
				elseif (!$unseen && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
 				else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
 				$instance = $instance.(($instance=='')?'':',').$tokens[$p];
 			}
			$varin = ":vin=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster";

			// find possible models to predict
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
				$in_process = shell_exec('ps aux | grep "'.(str_replace(array('*','"'),array('\*',''),'aloja_predict_instance -l '.$model.' -p inst_predict="'.$instance)).$varin.'" | grep -v grep');

				$tmp_file = getcwd().'/cache/query/'.md5($instance.'-'.$model).'.tmp';

				if (!file_exists($cache_filename) && $in_process == NULL && (!file_exists($tmp_file) || filesize($tmp_file) == 0))
				{
					// drop query
					$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict="'.$instance.$varin.'" -v | grep -v "WARNING" > '.$tmp_file.' &';
					exec($command);
				}

				if (!file_exists($cache_filename) && (file_exists($tmp_file) && filesize($tmp_file) > 0))
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
							if ($count_aux < 1 || $count_aux > 10) { $count_aux++; continue; } #FIXME - Indexes hardcoded for file-dsorig.csv
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
								$realexecval = $realexecval + (int)$attributes2[1];
								$count_sols++;
							}
							$realexecval = $realexecval / $count_sols;
							$mae = $mae + abs((int)$attributes[11] - $realexecval); #FIXME - Indexes hardcoded for file-dsorig.csv
							$rae = $rae + abs(((float)$attributes[11] - $realexecval) / $realexecval); #FIXME - Indexes hardcoded for file-dsorig.csv
							$count_preds++;
						}
						// END - Fetch Real Value

						if ($jsonData!='[') $jsonData = $jsonData.',';
						$jsonData = $jsonData.'[\''.implode("','",explode(',',$parsed)).'\',\''.$realexecval.'\']';
						$i++;
					}
					$jsonData = $jsonData.']';
					$mae = number_format($mae / $count_preds,3);
					$rae = number_format($rae / $count_preds,5);

					$jsonData = str_replace(array('Cl1','Cl2'),array('Local','Azure'),$jsonData);
					foreach (array(0,1,2,3) as $value) $jsonData = str_replace('Cmp'.$value,Utils::getCompressionName($value),$jsonData);

					$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Prediction','Observed');
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
				}
				$in_process = shell_exec('ps aux | grep "'.(str_replace(array('*','"'),array('\*',''),'aloja_predict_instance -l '.$model.' -p inst_predict="'.$instance)).'" | grep -v grep');

				if (!file_exists($cache_filename) && $in_process != NULL)
				{
					$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
					$must_wait = 'YES';
				}

				if (file_exists($cache_filename))
				{
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
			$instance = $possible_models_id = "";
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
