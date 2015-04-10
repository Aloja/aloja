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
			$cross_var2 = (array_key_exists('variable2',$_GET))?$_GET['variable2']:'net';

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

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);
		
			// Get stuff from the DB
			$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2
				FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster
				WHERE e.valid = TRUE AND e.exe_time > 100".$where_configs."
				ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
		    	$rows = $db->get_rows ( $query );
			if (empty($rows)) throw new \Exception('No data matches with your critteria.');

			$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type"));
			$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type"));

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
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = '[]';
			$cross_var1 = $cross_var2 = '';
			$categories1 = $categories2 = '';
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
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
