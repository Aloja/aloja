<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLPrecisionController extends AbstractController
{
	public function mlprecisionAction()
	{
		$jsonDiversity = $jsonPrecisions = $jsonDiscvars = $jsonHeaderDiv = $jsonPrecisionHeader = '[]';
		$instance = $error_stats = '';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

		    	$db = $this->container->getDBUtils();
		    	
		    	$where_configs = "";

			$dump = null;
			$pass = null;
			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists("dump",$_GET))
			|| (count($_GET) == 2 && array_key_exists("pass",$_GET))
			|| (count($_GET) == 3 && array_key_exists("dump",$_GET) && array_key_exists("pass",$_GET)))
 			{
				$pass = (isset($_GET["pass"])) ? $_GET["pass"] : null;
				$dump =  (isset($_GET["dump"])) ? $_GET["dump"] : null;
				unset($_GET["pass"]);
				unset($_GET["dump"]);
 			}
			$this->buildFilters();
			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);
			$where_configs = str_replace("AND .","AND ",$where_configs);

			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','bench_type','vm_size','vm_cores','vm_RAM','type','hadoop_version','provider','vm_OS'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$slice_info."-precision";
			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.precisions WHERE id_precision = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$eval_names = array('Cl.Name','Datanodes','Headnodes','VM.OS','VM.Cores','VM.RAM','Provider','VM.Size','Type','Bench.Type','Hadoop.Version');

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/query/'.md5($config).'.fin');

			if (!$is_cached && !$in_process && !$finished_process)
			{
				// get headers for csv
				$header_names = array(
					'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster','name' => 'Cl.Name',
					'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
					'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type','bench_type' => 'Bench.Type','hadoop_version'=>'Hadoop.Version'
				);
				$headers = array_keys($header_names);
				$names = array_values($header_names);

			    	// dump the result to csv
			    	$query = "SELECT ".implode(",",$headers)." FROM aloja2.execs e LEFT JOIN aloja2.clusters c ON e.id_cluster = c.id_cluster WHERE hadoop_version IS NOT NULL".$where_configs.";";
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
				$count = 1;
				foreach ($eval_names as $name)
				{
					exec(getcwd().'/resources/queue -d -c "cd '.getcwd().'/cache/query ; ../../resources/aloja_cli.r -d '.md5($config).'-cache.csv -m aloja_diversity -p vdisc="'.$name.'":noout=1:json=1 -v > '.md5($config).'-D-'.$name.'.tmp 2>/dev/null; touch '.md5($config).'-'.($count++).'.lock" >/dev/null 2>&1 &');
					exec(getcwd().'/resources/queue -d -c "cd '.getcwd().'/cache/query ; ../../resources/aloja_cli.r -d '.md5($config).'-cache.csv -m aloja_precision_split -p vdisc="'.$name.'":noout=1:json=1 -v > '.md5($config).'-P-'.$name.'.tmp 2>/dev/null; touch '.md5($config).'-'.($count++).'.lock" >/dev/null 2>&1 &');
				}

			}
			$finished_process = ((int)shell_exec('ls '.getcwd().'/cache/query/'.md5($config).'-*.lock | wc -w ') == 2*count($eval_names));

			if ($finished_process && !$is_cached)
			{
				$token = 0;
				$token_i = 0;
				$query = "INSERT IGNORE INTO aloja_ml.precisions (id_precision,model,instance,dataslice,diversity,precisions,discvar) VALUES ";
				foreach ($eval_names as $name)
				{
					$treated_line_d = "";
					$treated_line_p = "";
					if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-D-'.$name.'.tmp', "r")) !== FALSE)
					{
						$line = fgets($handle, 1000000);
						$treated_line_d = substr($line,5);
						$treated_line_d = substr($treated_line_d,0,-2);
						$treated_line_d = preg_replace('/,Cmp(\d+),/',',${1},',$treated_line_d);
						$treated_line_d = preg_replace('/,Cl(\d+),/',',${1},',$treated_line_d);
						$treated_line_d = str_replace("'","\"",$treated_line_d);
					}
					fclose($handle);

					if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-P-'.$name.'.tmp', "r")) !== FALSE)
					{
						$line = fgets($handle, 1000000);
						$treated_line_p = substr($line,5);
						$treated_line_p = substr($treated_line_p,0,-2);
						$treated_line_p = preg_replace('/,Cmp(\d+),/',',${1},',$treated_line_p);
						$treated_line_p = preg_replace('/,Cl(\d+),/',',${1},',$treated_line_p);
						$treated_line_p = str_replace("'","\"",$treated_line_p);
					}
					fclose($handle);

					if ($token > 0) { $query = $query.","; } $token = 1;
					$query = $query."('".md5($config)."','".substr($model_info,1)."','".$instance."','".$slice_info."','".$treated_line_d."','".$treated_line_p."','".$name."') ";

					$token_i = 1;
				}
				if ($token_i > 0)
				{
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
				}

				// remove remaining locks
				shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.lock'); 

				// Remove temporal files
				shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.tmp');
				shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'*.csv');
				
				$is_cached = true;
			}

			if (!$is_cached)
			{
				$jsonDiversity = $jsonPrecisions = $jsonDiscvars = $jsonHeaderDiv = $jsonPrecisionHeader = '[]';
				$must_wait = 'YES';
			}
			else
			{
				$must_wait = 'NO';

				$discvars = array();
				$diversity = array();
				$precisions = array();

				$query = "SELECT id_precision,model,instance,dataslice,diversity,precisions,discvar FROM aloja_ml.precisions WHERE id_precision = '".md5($config)."'";
				$result = $dbml->query($query);
				foreach ($result as $row)
				{
					$discvars[] = $row['discvar'];
					$diversity[] = $row['diversity'];
					$precisions[] = $row['precisions'];
				}

				$jsonDiscvars = "['".implode("','",$discvars)."']";
				$jsonDiversity = "[".implode(",",$diversity)."]";
				$jsonPrecisions = "[".implode(",",$precisions)."]";

				$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Target','Exe.Time','Support');
				$jsonHeaderDiv = '[';
				foreach ($header as $title)
				{
					if ($jsonHeaderDiv!='[') $jsonHeaderDiv = $jsonHeaderDiv.',';
					$jsonHeaderDiv = $jsonHeaderDiv.'{"title":"'.$title.'"}';
				}
				$jsonHeaderDiv = $jsonHeaderDiv.']';

				$jsonPrecisionHeader = '[{"title":"Target"},{"title":"Diversity"},{"title":"# Executions"},{"title":"Deviation (UnPrecision)"},{"title":"Mean [Stats]"},{"title":"StDev [Stats]"},{"title":"Max [Stats]"},{"title":"Min [Stats]"}]';
			}

			$dbml = null;
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonDiversity = $jsonPrecisions = $jsonDiscvars = $jsonHeaderDiv = $jsonPrecisionHeader = '[]';
			$must_wait = 'NO';
			$dbml = null;
		}

		$return_params = array(
			'discvars' => $jsonDiscvars,
			'diversity' => $jsonDiversity,
			'precisions' => $jsonPrecisions,
			'diversityHeader' => $jsonHeaderDiv,
			'precisionHeader' => $jsonPrecisionHeader,
			'must_wait' => $must_wait,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'id_precision' => md5($config),
			'error_stats' => $error_stats
		);
		return $this->render('mltemplate/mlprecision.html.twig', $return_params);
	}
}
?>
