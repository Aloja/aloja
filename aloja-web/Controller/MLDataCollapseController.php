<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLDataCollapseController extends AbstractController
{
	/* This function is half 'Shut Down' until some re-logics are done */
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

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('bayes','sort','terasort','wordcount'); $where_configs .= ' AND bench IN ("bayes","sort","terasort","wordcount")';
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
			$instance = MLUtils::generateSimpleInstance($param_names, $params, $unseen, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, $unseen, $db);
			
			// select model for filling 
			$current_model = '';
//			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model']; // FIXME - Needs re-think logic

			$possible_models = $possible_models_id = array();
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $db);
//			if (!empty($possible_models_id) && $current_model == "") $current_model = $possible_models_id[0]; // FIXME - Needs re-think logic

			$learning_model = '';
			if ($current_model != '' && file_exists(getcwd().'/cache/query/'.$current_model.'-object.rds')) $learning_model = ':model_name='.$current_model.':inst_general="'.$instance.'"';
 
			$config = $dims1.'-'.$dims2.'-'.$dname1.'-'.$dname2."-".$current_model.'-'.$model_info;
			$options = 'dimension1="'.$dims1.'":dimension2="'.$dims2.'":dimname1="'.$dname1.'":dimname2="'.$dname2.'":saveall='.md5($config).(($learning_model!='')?$learning_model:'');

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			$is_cached = file_exists($cache_ds);
			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');

			if ($is_cached && !$in_process)
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
			    	$rows = $db->get_rows($query);

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
				$command = '( cd '.getcwd().'/cache/query ; ';
				$command = $command.'touch '.getcwd().'/cache/query/'.md5($config).'.lock ; ';
				if ($learning_model != '') { $command = $command.getcwd().'/resources/aloja_cli.r -m aloja_dataset_collapse_expand -d '.$cache_ds.' -p '.$options.' > /dev/null 2>&1 ; '; }
				else { $command = $command.getcwd().'/resources/aloja_cli.r -m aloja_dataset_collapse -d '.$cache_ds.' -p '.$options.' > /dev/null 2>&1 ; '; }
				$command = $command.'rm -f '.getcwd().'/cache/query/'.md5($config).'.lock ; ) > /dev/null 2>&1 &';
				exec($command);

				// update cache record (for human reading)
				$register = md5($config).' : '.$config."\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			$in_process = file_exists(getcwd().'/cache/query/'.md5($config).'.lock');
			$must_wait = 'NO';

			if ($in_process)
			{
				$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
				$must_wait = 'YES';
			}
			else
			{
				// read results of the CSV
				if (	($handle = fopen(getcwd().'/cache/query/'.md5($config).'-matrix.csv', 'r')) !== FALSE // cmatrix.csv
				&&	($handid = fopen(getcwd().'/cache/query/'.md5($config).'-ids.csv', 'r')) !== FALSE )  // cids.csv
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
}
?>
