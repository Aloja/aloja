<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class MLMinconfigsController extends AbstractController
{
	/* GENERAL FUNCTIONS TO USE */

	private function generateModelInfo($param_names, $params, $condition)
	{
	    	$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$model_info = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));
			if ($condition) $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("*")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');	
			else $model_info = $model_info.((empty($params[$p]))?' '.substr($p,0,-1).' ("'.implode('","',$paramAllOptions[$p]).'")':' '.substr($p,0,-1).' ("'.implode('","',$params[$p]).'")');
		}
		return $model_info;
	}

	private function generateSimpleInstance($param_names, $params, $condition)
	{
	    	$db = $this->container->getDBUtils();
		$filter_options = Utils::getFilterOptions($db);
		$paramAllOptions = $tokens = array();
		$instance = '';
		foreach ($param_names as $p) 
		{
			if (array_key_exists(substr($p,0,-1),$filter_options)) $paramAllOptions[$p] = array_column($filter_options[substr($p,0,-1)],substr($p,0,-1));

			$tokens[$p] = '';
			if ($condition && empty($params[$p])) { $tokens[$p] = '*'; }
			elseif (!$condition && empty($params[$p]))  { foreach ($paramAllOptions[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			else { foreach ($params[$p] as $par) $tokens[$p] = $tokens[$p].(($tokens[$p] != '')?'|':'').(($p=='comps')?'Cmp':'').(($p=='id_clusters')?'Cl':'').$par; }
			$instance = $instance.(($instance=='')?'':',').$tokens[$p];
		}
		return $instance;
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

	public function mlminconfigsAction()
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
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters'); // Order is important
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
				$unrestricted = TRUE; 
			}

			$learn_param = (array_key_exists('learn',$_GET))?$_GET['learn']:'regtree';
			$unrestricted = (array_key_exists('umodel',$_GET) && $_GET['umodel'] == 1);

			// compose instance
			$instance = $this->generateSimpleInstance($param_names, $params, $unrestricted);
			$model_info = $this->generateModelInfo($param_names, $params, $unrestricted);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options ='kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options = 'ppoly=3:prange=0,20000'; }

			$config = $model_info.' '.$learn_param.' minconfs';

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached = file_exists($cache_ds);
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			// Find cache TODO - Check for prev models
			if ($is_cached && !$in_process)
			{
				$keep_cache = TRUE;
				foreach (array("tt", "tv", "tr") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv');
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
					shell_exec("sed -i '/".md5($config)." : ".$config."-model/d' ".getcwd()."/cache/query/record.data");
					shell_exec("sed -i '/".md5($config."R")." : ".$config."-result/d' ".getcwd()."/cache/query/record.data");
				}
			}

			// Create Models and Predictions
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
			    	$query="SELECT ".implode(",",$headers)." FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND bench_type = 'HiBench' AND bench NOT LIKE 'prep_%' AND e.exe_time > 100".$where_configs.";";
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
				$command = '( cd '.getcwd().'/cache/query; ';
				$command = $command.'touch '.getcwd().'/cache/query/'.md5($config).'.lock ; ';
				$command = $command.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config).' > /dev/null 2>&1 && ';
				$command = $command.getcwd().'/resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config).' -p saveall='.md5($config.'R').':kmax=200 > /dev/null 2>&1 ;';
				$command = $command.'rm -f '.getcwd().'/cache/query/'.md5($config).'.lock ; ) > /dev/null 2>&1 &';
				exec($command);

				// update cache record (for human reading)
				$register = md5($config).' :'.$config."-model\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);

				$register = md5($config."R").' :'.$config."-result\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
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
							$jsonHeader = '[{title:""}';
							foreach ($header as $title) if ($title != "ID") $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
							$jsonHeader = $jsonHeader.',{title:"Instances"}]';
						}

						$count = 0;
						$jsonConfig = '[';
						while (($data = fgetcsv($handle, 1000, ",")) !== FALSE)
						{
							if ($jsonConfig!='[') $jsonConfig = $jsonConfig.',';
							$jsonConfig = $jsonConfig.'[\''.implode("','",$data).'\',\''.$sizes[$count++].'\']';

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
		echo $this->container->getTwig()->render('mltemplate/mlminconfigs.html.twig',
			array(
				'selected' => 'mlminconfigs',
				'jsonData' => json_encode($jsonData),
				'jsonHeader' => $jsonHeader,
				'configs' => $configs,
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
				'message' => $message,
				'instance' => $instance,
				'unrestricted' => $unrestricted,
				'learn' => $learn_param,
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
