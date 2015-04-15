<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLCrossvarController extends AbstractController
{
	public function mlcrossvarAction()
	{
		$jsonData = array();
		$message = $instance = '';
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

			$cross_var1 = (array_key_exists('variable1',$_GET))?$_GET['variable1']:'maps';
			$cross_var2 = (array_key_exists('variable2',$_GET))?$_GET['variable2']:'exe_time';

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('wordcount'); $where_configs .= ' AND bench IN ("wordcount")';
				$params['disks'] = array('SSD','HDD'); $where_configs .= ' AND disk IN ("SSD","HDD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")'; 			
			}
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);

			$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type"));
			$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type"));

			$rows = null;
			if ($cross_var1 != 'pred_time' && $cross_var2 != 'pred_time')
			{		
				// Get stuff from the DB
				$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2
					FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster LEFT JOIN JOB_details j ON e.id_exec = j.id_exec
					WHERE e.valid = TRUE AND e.exe_time > 100".$where_configs."
					ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}
			else
			{
				$other_var = $cross_var1;
				if ($cross_var1 == 'pred_time') $other_var = $cross_var2;

				// Call to MLTemplates, to fetch/learn model
				$_GET['pass'] = 1;
				$mltc1 = new MLTemplatesController();
				$mltc1->container = $this->container;
				$ret_learn = $mltc1->mlpredictionAction();

				if ($ret_learn == 1)
				{
					$must_wait = "YES";
					$jsonData = '[]';
					$categories1 = $categories2 = '';
				}
				else
				{
					$other_var = $cross_var1;
					if ($cross_var1 == 'pred_time') $other_var = $cross_var2;
					$other_var = str_replace("id_cluster","e.id_cluster",$other_var);

					if ($cross_var1 == 'pred_time') { $var1 = 'p.'.$cross_var1; $var2 = 's.'.$cross_var2; }
					else { $var1 = 's.'.$cross_var1; $var2 = 'p.'.$cross_var2; }

					// Get stuff from the DB
					$query="SELECT ".$var1." as V1, ".$var2." as V2
						FROM (	SELECT ".$other_var.", e.id_exec
							FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster LEFT JOIN JOB_details j ON e.id_exec = j.id_exec
							WHERE e.valid = TRUE AND e.exe_time > 100".$where_configs."
						) AS s LEFT JOIN aloja_ml.predictions AS p ON s.id_exec = p.id_exec
						ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
			  	  	$rows = $db->get_rows ( $query );
					if (empty($rows)) throw new \Exception('No data matches with your critteria.');
				}
			}

			if ($must_wait == "NO")
			{
				$map_var1 = $map_var2 = array();
				$count_var1 = $count_var2 = 0;
				$categories1 = $categories2 = '';

				foreach ($rows as $row)
				{
					$entry = array();

					if ($var1_categorical)
					{
						if (!array_key_exists($row['V1'],$map_var1))
						{
							$map_var1[$row['V1']] = $count_var1++;
							$categories1 = $categories1.(($categories1!='')?",":"")."\"".$row['V1']."\"";
						}
						$entry['y'] = $map_var1[$row['V1']]*(rand(990,1010)/1000);
					}
					else $entry['y'] = (int)$row['V1']*(rand(990,1010)/1000);

					if ($var2_categorical)
					{
						if (!array_key_exists($row['V2'],$map_var2))
						{
							$map_var2[$row['V2']] = $count_var2++;
							$categories2 = $categories2.(($categories2!='')?",":"")."\"".$row['V2']."\"";
						}
						$entry['x'] = $map_var2[$row['V2']]*(rand(990,1010)/1000);
					}
					else $entry['x'] = (int)$row['V2']*(rand(990,1010)/1000);

					$entry['name'] = $row['V1']." - ".$row['V2'];
					$jsonData[] = $entry;
				}

				$jsonData = json_encode($jsonData);
				if ($categories1 != '') $categories1 = "[".$categories1."]"; else $categories1 = "''";
				if ($categories2 != '') $categories2 = "[".$categories2."]"; else $categories2 = "''";
			}
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = '[]';
			$cross_var1 = $cross_var2 = '';
			$categories1 = $categories2 = '';
			$must_wait = "NO";
		}
		echo $this->container->getTwig()->render('mltemplate/mlcrossvar.html.twig',
			array(
				'selected' => 'mlcrossvar',
				'jsonData' => $jsonData,
				'variable1' => $cross_var1,
				'variable2' => $cross_var2,
				'categories1' => $categories1,
				'categories2' => $categories2,
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
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
