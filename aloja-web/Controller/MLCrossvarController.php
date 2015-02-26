<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class MLCrossvarController extends AbstractController
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

	/* CONTROLLER FUNCTIONS */

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

			if (count($_GET) <= 1 || (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('wordcount'); $where_configs .= ' AND bench IN ("wordcount")';
				$params['disks'] = array('SSD','HDD'); $where_configs .= ' AND disk IN ("SSD","HDD")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")'; 			
			}

			// compose instance
			$instance = $this->generateSimpleInstance($param_names, $params, true);
			$model_info = $this->generateModelInfo($param_names, $params, true);

			$cache_ds = getcwd().'/cache/query/'.md5($model_info.$cross_var1.$cross_var2).'-cross.csv';
			$is_cached = file_exists($cache_ds);

			if (!$is_cached)
			{
				// dump the result to csv
			    	$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2 FROM execs e LEFT JOIN clusters c ON e.id_cluster = c.id_cluster WHERE e.valid = TRUE AND e.exe_time > 100".$where_configs.";";
			    	$rows = $db->get_rows ( $query );

				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				$fp = fopen($cache_ds, 'w');
			    	foreach($rows as $row) fputcsv($fp, array_values($row),',','"');

/*				// launch query
				$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_outlier_dataset -d '.$cache_ds.' -l '.$model.' -p sigma=3:hdistance=3:saveall='.md5($model_info.'-'.$model).' > /dev/null &';
				exec($command);
*/
				// update cache record (for human reading)
				$register = md5($model_info.$cross_var1.$cross_var2).' : '.$model_info.'-'.$cross_var1."-".$cross_var2."\n";
				shell_exec("sed -i '/".$register."/d' ".getcwd()."/cache/query/record.data");
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			// read results of the CSV
			if (($handle = fopen(getcwd().'/cache/query/'.md5($model_info.$cross_var1.$cross_var2).'-cross.csv', 'r')) !== FALSE)
			{
				$map_var1 = $map_var2 = array();
				$count_var1 = $count_var2 = 0;
				$categories1 = $categories2 = '';
				$count = 0;
				while (($data = fgetcsv($handle, 1000, ",")) !== FALSE && $count < 5000) // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
				{
					if (in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type")))
					{
						if (!array_key_exists($data[0],$map_var1))
						{
							$map_var1[$data[0]] = $count_var1++;
							$categories1 = $categories1.(($categories1!='')?",":"")."\"".$data[0]."\"";
						}
						$jsonData[$count]['y'] = $map_var1[$data[0]]*(rand(990,1010)/1000);
					}
					else $jsonData[$count]['y'] = (int)$data[0]*(rand(990,1010)/1000);

					if (in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type")))
					{
						if (!array_key_exists($data[1],$map_var2))
						{
							$map_var2[$data[1]] = $count_var2++;
							$categories2 = $categories2.(($categories2!='')?",":"")."\"".$data[1]."\"";
						}
						$jsonData[$count]['x'] = $map_var2[$data[1]]*(rand(990,1010)/1000);
					}
					else $jsonData[$count]['x'] = (int)$data[1]*(rand(990,1010)/1000);

					$jsonData[$count++]['name'] = $data[0]." - ".$data[1];
				}
				fclose($handle);

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
