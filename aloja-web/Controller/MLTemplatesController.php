<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class MLTemplatesController extends AbstractController
{
	/* GENERAL FUNCTIONS TO USE */	

	private function generateModelInfo($param_names, $params, $unseen)
	{
	    	$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$model_info = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
			if ($unseen) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
			else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');
		}
		return $model_info;
	}

	private function generateSimpleInstance($param_names, $params, $unseen)
	{
	    	$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$instance = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));

			$tokens[$p] = '';
			if ($unseen && empty($params[$p])) { $tokens[$p] = '*'; }
			elseif (!$unseen && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			$instance = $instance.(($instance=='')?'':',').$tokens[$p];
		}
		return $instance;
	}

	private function generateInstances($param_names, $params, $unseen)
	{
	    	$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = $instances = array();

		// Get info from clusters (Part of header_names!)
		$cluster_header_names = array(
			'id_cluster' => 'Cluster','name' => 'Cl.Name','datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores',
			'vm_RAM' => 'VM.RAM','provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type'
		);
		$cluster_descriptor = array();
		$query = "select ".implode(",",array_keys($cluster_header_names))." from clusters;";
	    	$rows = $db->get_rows($query);
	    	foreach($rows as $row)
		{
			$cid = $row['id_cluster'];
			foreach(array_keys($cluster_header_names) as $cname)
			{
				$cluster_descriptor[$cid][$cname] = $row[$cname];
			}
		}

		// If "No Clusters" -> All clusters
		if (!$unseen && empty($params['id_clusters']))
		{
			$params['id_clusters'] = array();
			$paramAllOptions['id_clusters'] = array_column($filter_options['id_cluster'],'id_cluster');
			foreach ($paramAllOptions['id_clusters'] as $par) $params['id_clusters'][] = $par;
		}

		// For each cluster selected, launch an instance...
		foreach ($params['id_clusters'] as $cl) 
		{
			$cl_characteristics = "Cl".implode(",",$cluster_descriptor[$cl]);
			
			$instance = '';
			foreach ($param_names as $p) 
			{
				if ($p != "id_clusters")
				{
					if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));

					$tokens[$p] = '';
					if ($unseen && empty($params[$p])) { $tokens[$p] = '*'; }
					elseif (!$unseen && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
					else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
					$instance = $instance.(($instance=='')?'':',').$tokens[$p];
				}
				else
				{
					$instance = $instance.(($instance=='')?'':',').$cl_characteristics;
				}
			}
			$instances[] = $instance;

		}
		return $instances;
	}

	private function findMatchingModels ($model_info, &$possible_models, &$possible_models_id)
	{
		
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
	}

	/* CONTROLLER FUNCTIONS */

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

			// compose instance
			$instance = $this->generateSimpleInstance($param_names, $params, $unrestricted);
			$model_info = $this->generateModelInfo($param_names, $params, $unrestricted);

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
				$command = '( cd '.getcwd().'/cache/query ; ';
				$command = $command.'touch '.getcwd().'/cache/query/'.md5($config).'.lock ; ';
				$command = $command.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null 2>&1 ; ';
				$command = $command.'rm -f '.getcwd().'/cache/query/'.md5($config).'.lock ; ) > /dev/null 2>&1 &';
				exec($command);

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

	/* This function is Shut Down until some re-logics are done */
	public function mldatacollapseAction()
	{
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
			$instance = $this->generateSimpleInstance($param_names, $params, $unseen);
			$model_info = $this->generateModelInfo($param_names, $params, $unseen);
			
			// Model for filling
			$possible_models = $possible_models_id = array();
			$this->findMatchingModels($model_info, $possible_models, $possible_models_id);

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

			if (count($_GET) <= 1 || (count($_GET) == 2 && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('65536','131072'); $where_configs .= ' AND iofilebuf IN ("65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$params['id_clusters'] = array('1'); $where_configs .= ' AND id_cluster IN ("1")';
				$unseen = FALSE;
			}

			$jsonData = $jsonHeader = "[]";
			$mae = $rae = $count_preds = 0;

			// compose instance
			$model_info = $this->generateModelInfo($param_names, $params, $unseen);
			$instance = $this->generateSimpleInstance($param_names, $params, $unseen);			
			$instances = $this->generateInstances($param_names, $params, $unseen);

			// Model for filling
			$this->findMatchingModels($model_info, $possible_models, $possible_models_id);

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
				$finished_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.ready');
				$is_cached = file_exists($cache_filename);

				if (!$in_process && !$finished_process && !$is_cached)
				{
					$command = '( cd '.getcwd().'/cache/query; ';
					$command = $command.'touch '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock; ';
					$command = $command.'rm -f '.$tmp_file.' ';
					foreach ($instances as $inst)
					{
						$command = $command.'&& '.getcwd().'/resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict=\''.$inst.'\' -v | grep -v \'WARNING\' | grep -v \'Prediction\' >> '.$tmp_file.' ';
					}
					$command = $command.'&& touch  '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.ready; ';
					$command = $command.'rm -f '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock ; ) > /dev/null 2>&1 &';
					exec($command);
				}

				$finished_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.ready');
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
					shell_exec('rm -f '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.ready');
				}

				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$is_cached = file_exists($cache_filename);

				if (!$is_cached)
				{
					$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
					$must_wait = 'YES';
				}
				else
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
