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
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

		    	$db = $this->container->getDBUtils();
		    	
		    	$where_configs = '';

		        $preset = null;	
			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists("current_model",$_GET)))
			{
				$preset = Utils::initDefaultPreset($db, 'mldatacollapse');
			}
		        $selPreset = (isset($_GET['presets'])) ? $_GET['presets'] : "none";

			$params = array();
			$param_names = array('benchs','nets','disks','mapss','iosfs','replications','iofilebufs','comps','blk_sizes','id_clusters','datanodess','bench_types','vm_sizes','vm_coress','vm_RAMs','types','hadoop_versions'); // Order is important
			foreach ($param_names as $p) { $params[$p] = Utils::read_params($p,$where_configs,FALSE); sort($params[$p]); }

			$unseen = (array_key_exists('unseen',$_GET) && $_GET['unseen'] == 1);

			// FIXME PATCH FOR PARAM LIBRARIES WITHOUT LEGACY
			$where_configs = str_replace("AND .","AND ",$where_configs);

			$dims1 = ((empty($params['nets']))?'':'Net,').((empty($params['disks']))?'':'Disk,').((empty($params['blk_sizes']))?'':'Blk.size,').((empty($params['comps']))?'':'Comp,');
			$dims1 = $dims1.((empty($params['id_clusters']))?'':'Cluster,').((empty($params['mapss']))?'':'Maps,').((empty($params['replications']))?'':'Rep,').((empty($params['iosfs']))?'':'IO.SFac,').((empty($params['iofilebufs']))?'':'IO.FBuf,');
			$dims1 = $dims1.((empty($params['hadoop_versionss']))?'':'Version,').((empty($params['bench_types']))?'':'Bench.Type');
			if (substr($dims1, -1) == ',') $dims1 = substr($dims1,0,-1);

			$dims2 = "Benchmark";

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, $unseen, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, $unseen, $db);
			
			// select model for filling 
			$possible_models = $possible_models_id = array();
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);

			$current_model = '';
/*			if (array_key_exists('current_model',$_GET) && in_array($_GET['current_model'],$possible_models_id)) $current_model = $_GET['current_model']; // FIXME - Needs re-think logic

			if ($current_model == '')
			{
				$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, p.id_learner FROM predictions p, learners l WHERE l.id_learner = p.id_learner AND p.id_learner IN ('".implode("','",$possible_models_id)."') AND predict_code > 0 ORDER BY MAE LIMIT 1";
				$result = $dbml->query($query);
				$row = $result->fetch();	
				$current_model = $row['id_learner'];
			}
*/
			$config = $instance.'-'.$current_model;

			$learning_model = '';
			if ($current_model != '' && file_exists(getcwd().'/cache/query/'.$current_model.'-object.rds')) $learning_model = ':model_name='.$current_model.':inst_general="'.$instance.'"';
 
			$config = $dims1.'-'.$dims2.'-'.$current_model.'-'.$model_info;

			// get headers for csv
			$header_names = array(
				'id_exec' => 'ID','bench' => 'Benchmark','exe_time' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosf' => 'IO.SFac',
				'replication' => 'Rep','iofilebuf' => 'IO.FBuf','comp' => 'Comp','blk_size' => 'Blk.size','e.id_cluster' => 'Cluster','name' => 'Cl.Name',
				'datanodes' => 'Datanodes','headnodes' => 'Headnodes','vm_OS' => 'VM.OS','vm_cores' => 'VM.Cores','vm_RAM' => 'VM.RAM',
				'provider' => 'Provider','vm_size' => 'VM.Size','type' => 'Type','bench_type' => 'Bench.Type','hadoop_version' => 'Hadoop.Version'
			);
			$headers = array_keys($header_names);
			$names = array_values($header_names);

			$dims1_array = explode(",",$dims1);
			$dims1_query = '';
			$dims1_title = $dims1_concat = '';
			foreach ($dims1_array as $d1value)
			{
				$dims1_query = $dims1_query.(($dims1_query=='')?'':',').array_search($d1value, $header_names);
				$dims1_title = $dims1_title.(($dims1_title=='')?'':':').array_search($d1value, $header_names);
				$dims1_concat = $dims1_concat.(($dims1_concat=='')?'':',":",').array_search($d1value, $header_names);
			}

			$query = "SELECT distinct bench FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100 AND hadoop_version IS NOT NULL".$where_configs." ORDER BY bench;";
			$rows = $db->get_rows($query);
			if (empty($rows)) throw new \Exception('No data matches with your critteria.');

			$table = array();

			$jsonHeader = '[{title:"'.$dims1_title.'"}';
			foreach ($rows as $row)
			{
				$jsonHeader = $jsonHeader.',{title:"'.$row['bench'].'"}';
				$table[$row['bench']] = array();
			}
			$jsonHeader = $jsonHeader.']';


			$query = "SELECT CONCAT(".$dims1_concat.") as dim1, bench, avg(exe_time) as avg_exe_time FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100 AND hadoop_version IS NOT NULL".$where_configs." GROUP BY bench,".$dims1_query." ORDER BY dim1,bench;";
			$rows = $db->get_rows($query);
			if (empty($rows)) throw new \Exception('No data matches with your critteria.');

			foreach ($rows as $row) $table[$row['bench']][$row['dim1']] = (int)$row['avg_exe_time'];

			$row_ids = array();
			foreach ($table as $bmk) foreach ($bmk as $key => $value) $row_ids[] = $key;
			$row_ids = array_unique($row_ids);

			$tableColor = array();
			foreach ($table as $bmk => $values)
			{
				$tableColor[$bmk] = array();
				foreach ($row_ids as $rid)
					if (!array_key_exists($rid,$table[$bmk])) { $table[$bmk][$rid] = 0; $tableColor[$bmk][$rid] = 0; }
					else { $tableColor[$bmk][$rid] = 1; }
			}

			$jsonData = '[';
			$jsonColor = '[';
			foreach ($row_ids as $rid)
			{
				$jsonData = $jsonData.(($jsonData=='[')?'':',').'[\''.$rid.'\'';
				$jsonColor = $jsonColor.(($jsonColor=='[')?'':',').'[1';
				foreach ($table as $bmk => $values)
				{
					$jsonData = $jsonData.','.$table[$bmk][$rid];
					$jsonColor = $jsonColor.','.$tableColor[$bmk][$rid];
				}
				$jsonData = $jsonData.']';
				$jsonColor = $jsonColor.']';
			}
			$jsonData = $jsonData.']';
			$jsonColor = $jsonColor.']';

			$jsonColumns = '[';
			for ($i = 1; $i <= count($table); $i++)
			{
				if ($jsonColumns != '[') $jsonColumns = $jsonColumns.',';
				$jsonColumns = $jsonColumns.$i;
			}
			$jsonColumns = $jsonColumns.']';
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
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
				'datanodess' => $params['datanodess'],
				'bench_types' => $params['bench_types'],
				'vm_sizes' => $params['vm_sizes'],
				'vm_coress' => $params['vm_coress'],
				'vm_RAMs' => $params['vm_RAMs'],
				'types' => $params['types'],
				'hadoop_versions' => $params['hadoop_versions'],
				'jsonEncoded' => $jsonData,
				'jsonHeader' => $jsonHeader,
				'jsonColumns' => $jsonColumns,
				'jsonColor' => $jsonColor,
				'instance' => $instance,
				'instance' => $instance,
				'model_info' => $model_info,
				'preset' => $preset,
				'selPreset' => $selPreset,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}
}
?>
