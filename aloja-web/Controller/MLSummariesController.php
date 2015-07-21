<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLSummariesController extends AbstractController
{
	public function mlsummariesAction()
	{
		$displaydata = $message = '';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();
		    	
		    	$where_configs = '';
		    	
		        $preset = null;
			if (count($_GET) <= 1)
			{
				$preset = Utils::getDefaultPreset($db, 'mlsummaries');
 			}
		        $selPreset = (isset($_GET['presets'])) ? $_GET['presets'] : "none";

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters','datanodess','bench_types','vm_sizes','vm_coress','vm_RAMs','types','hadoop_versions'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,FALSE); sort($params[$p]); }

			$separate_feat = 'joined';
			if (array_key_exists('feature',$_GET)) $separate_feat = $_GET['feature'];

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true,$db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true,$db);

			$config = $model_info.' '.$separate_feat.' SUMMARY';

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM summaries WHERE id_summaries = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			if (!$is_cached)
			{
				// get headers for csv
				$header_names = array(
					'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
					'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster','name' => 'Cl.Name',
					'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
					'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type','bench_type' => 'Bench.Type','hadoop_version' => 'Hadoop.Version'
				);
			    	$headers = array_keys($header_names);
				$names = array_values($header_names);

				// dump the result to csv
			    	$query="SELECT ".implode(",",$headers)." FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100 AND hadoop_version IS NOT NULL".$where_configs.";";
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

				// launch query
				$command = 'cd '.getcwd().'/cache/query; ../../resources/aloja_cli.r -m aloja_print_summaries -d '.$cache_ds.' -p '.(($separate_feat!='joined')?'sname='.$separate_feat.':':'').'fprint='.md5($config).':fwidth=1000:html=1'; #fwidth=135
				$output = shell_exec($command);

				// Save to DB
				if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-summary.data', 'r')) !== FALSE)
				{
					$displaydata = "";
					while (($data = fgets($handle)) !== FALSE)
					{
						$displaydata = $displaydata.$data;
					}
					fclose($handle);

					$displaydata = str_replace('\'','\\\'',$displaydata);

					// register model to DB
					$query = "INSERT INTO summaries (id_summaries,instance,model,summary)";
					$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$displaydata."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');
				}

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'-summary.data');
				$output = shell_exec('rm -f '.getcwd().'/cache/query/'.md5($config).'-cache.csv');
			}

			// Read results of the DB
			$is_cached_mysql = $dbml->query("SELECT summary FROM summaries WHERE id_summaries = '".md5($config)."' LIMIT 1");
			$tmp_result = $is_cached_mysql->fetch();
			$displaydata = $tmp_result['summary'];
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$displaydata = $separate_feat = '';
		}
		echo $this->container->getTwig()->render('mltemplate/mlsummaries.html.twig',
			array(
				'selected' => 'mlsummaries',
				'displaydata' => $displaydata,
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
				'datanodess' => $params['datanodess'],
				'bench_types' => $params['bench_types'],
				'vm_sizes' => $params['vm_sizes'],
				'vm_coress' => $params['vm_coress'],
				'vm_RAMs' => $params['vm_RAMs'],
				'types' => $params['types'],
				'hadoop_versions' => $params['hadoop_versions'],
				'feature' => $separate_feat,
				'message' => $message,
				'preset' => $preset,
				'selPreset' => $selPreset,
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
?>
