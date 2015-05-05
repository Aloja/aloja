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
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('RR1'); $where_configs .= ' AND disk IN ("RR1")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('3'); $where_configs .= ' AND comp IN ("3")';
				$params['mapss'] = array('2','4'); $where_configs .= ' AND maps IN ("2","4")';
				$params['iosfs'] = array('100'); $where_configs .= ' AND iosf IN ("100")';
				$params['blk_sizes'] = array('134'); $where_configs .= ' AND blk_size IN ("134")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")'; 			
			}
			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);

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
					$categories1 = $categories2 = "''";
				}
				else if ($ret_data == -1)
				{
					$must_wait = "NO";
					$jsonData = '[]';
					$categories1 = $categories2 = "''";
					$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section. [".$instance."]";
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

				$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type"));
				$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type"));

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

	public function mlcrossvar3dAction()
	{
		$jsonData = array();
		$message = $instance = '';
		$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
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
			$cross_var2 = (array_key_exists('variable2',$_GET))?$_GET['variable2']:'net';
			$cross_var3 = 'exe_time';

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('current_model',$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('RR1'); $where_configs .= ' AND disk IN ("RR1")';
				$params['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = array('3'); $where_configs .= ' AND comp IN ("3")';
				$params['mapss'] = array('2','4'); $where_configs .= ' AND maps IN ("2","4")';
				$params['iosfs'] = array('100'); $where_configs .= ' AND iosf IN ("100")';
				$params['blk_sizes'] = array('134'); $where_configs .= ' AND blk_size IN ("134")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")'; 		
			}
			$where_configs = str_replace("AND .","AND ",$where_configs);
			$where_configs = str_replace("id_cluster","e.id_cluster",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, true, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, true, $db);

			$rows = null;
			if ($cross_var1 != 'pred_time' && $cross_var2 != 'pred_time')
			{		
				// Get stuff from the DB
				$query="SELECT ".$cross_var1." as V1,".$cross_var2." as V2,".$cross_var3." as V3
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
					$categories1 = $categories2 = "''";
				}
				else if ($ret_data == -1)
				{
					$must_wait = "NO";
					$jsonData = '[]';
					$categories1 = $categories2 = "''";
					$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section. [".$instance."]";
				}
				else
				{
					$other_var = $cross_var1;
					if ($cross_var1 == 'pred_time') $other_var = $cross_var2;
					$other_var = str_replace("id_cluster","e.id_cluster",$other_var);

					if ($cross_var1 == 'pred_time') { $var1 = 'p.'.$cross_var1; $var2 = 's.'.$cross_var2; }
					else { $var1 = 's.'.$cross_var1; $var2 = 'p.'.$cross_var2; }
					$var3 = 'e.'.$cross_var3;

					// Get stuff from the DB
					$query="SELECT ".$var1." as V1, ".$var2." as V2,".$cross_var3." as V3
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

				$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type"));
				$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type"));

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
					if ($entry['y'] > $maxy) $maxy = $entry['y'];
					if ($entry['y'] < $miny) $miny = $entry['y'];

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
					if ($entry['x'] > $maxx) $maxx = $entry['x'];
					if ($entry['x'] < $minx) $minx = $entry['x'];

					$entry['z'] = -1 * max(100,(int)$row['V3']*(rand(990,1010)/1000));
					if ($entry['z'] > $maxz) $maxz = $entry['z'];
					if ($entry['z'] < $minz) $minz = $entry['z'];

					$entry['name'] = $row['V1']." - ".$row['V2']." - ".max(100,(int)$row['V3']);

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
			$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
			$must_wait = "NO";
		}
		echo $this->container->getTwig()->render('mltemplate/mlcrossvar3d.html.twig',
			array(
				'selected' => 'mlcrossvar3d',
				'jsonData' => $jsonData,
				'variable1' => $cross_var1,
				'variable2' => $cross_var2,
				'categories1' => $categories1,
				'categories2' => $categories2,
				'maxx' => $maxx, 'minx' => $minx,
				'maxy' => $maxy, 'miny' => $miny,
				'maxz' => $maxz, 'minz' => $minz,
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

	public function mlcrossvar3dfaAction()
	{
		$jsonData = array();
		$message = $instance = $possible_models_id = '';
		$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain_ml'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
		        $dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
		        $dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

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
				$params['benchs'] = $_GET['benchs'] = array('terasort'); $where_configs = ' AND bench IN ("terasort")';
				$params['disks'] = $_GET['disks'] = array('RR1'); $where_configs .= ' AND disk IN ("RR1")';
				$params['iofilebufs'] = $_GET['iofilebufs'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$params['comps'] = $_GET['comps'] = array('3'); $where_configs .= ' AND comp IN ("3")';
				$params['replications'] = $_GET['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$params['id_clusters'] = $_GET['id_clusters'] = array('1'); $where_configs .= ' AND id_cluster IN ("1")';
				$params['mapss'] = $_GET['mapss'] = array('2','4'); $where_configs .= ' AND maps IN ("2","4")';
				$params['iosfs'] = $_GET['iosfs'] = array('100'); $where_configs .= ' AND iosf IN ("100")';
				$params['blk_sizes'] = $_GET['blk_sizes'] = array('134'); $where_configs .= ' AND blk_size IN ("134")';
			}
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($param_names, $params, false, $db);
			$model_info = MLUtils::generateModelInfo($param_names, $params, false, $db);

			// Model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $dbml);

			$current_model = "";
			if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

			// Call to MLFindAttributes, to fetch data
			$_GET['pass'] = 1;
			$_GET['unseen'] = FALSE;
			$mlfa1 = new MLFindAttributesController();
			$mlfa1->container = $this->container;
			$ret_data = $mlfa1->mlfindattributesAction();

			$rows = null;
			if ($ret_data == 1)
			{
				$must_wait = "YES";
				$jsonData = '[]';
				$categories1 = $categories2 = "''";
			}
			else if ($ret_data == -1)
			{
				$must_wait = "NO";
				$jsonData = '[]';
				$categories1 = $categories2 = "''";
				$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section. [".$instance."]";
			}
			else
			{
				// Get stuff from the DB
				$query="SELECT ".$cross_var1." AS V1, ".$cross_var2." AS V2, AVG(p.pred_time) as V3, p.instance
					FROM predictions as p
					WHERE p.id_learner ".(($current_model != '')?"='".$current_model."'":"IN (SELECT id_learner FROM trees WHERE model='".$model_info."')").$where_configs."
					GROUP BY p.instance
					ORDER BY RAND() LIMIT 5000;"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LINE WHEN THE BUG IS SOLVED
				$rows = $dbml->query($query);
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');
			}

			if ($must_wait == "NO")
			{
				$map_var1 = $map_var2 = array();
				$count_var1 = $count_var2 = 0;
				$categories1 = $categories2 = '';

				$var1_categorical = in_array($cross_var1, array("net","disk","bench","vm_OS","provider","vm_size","type"));
				$var2_categorical = in_array($cross_var2, array("net","disk","bench","vm_OS","provider","vm_size","type"));

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
					if ($entry['y'] > $maxy) $maxy = $entry['y'];
					if ($entry['y'] < $miny) $miny = $entry['y'];

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
					if ($entry['x'] > $maxx) $maxx = $entry['x'];
					if ($entry['x'] < $minx) $minx = $entry['x'];

					$entry['z'] = -1 * (int)$row['V3']*(rand(990,1010)/1000);
					if ($entry['z'] > $maxz) $maxz = $entry['z'];
					if ($entry['z'] < $minz) $minz = $entry['z'];

					$entry['name'] = $row['instance']; //$row['V1']." - ".$row['V2']." - ".max(100,(int)$row['V3']);
					$jsonData[] = $entry;
				}

				$jsonData = json_encode($jsonData);
				if ($categories1 != '') $categories1 = "[".$categories1."]"; else $categories1 = "''";
				if ($categories2 != '') $categories2 = "[".$categories2."]"; else $categories2 = "''";
			}

			$dbml = null;
		}
		catch(\Exception $e)
		{
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			$jsonData = '[]';
			$cross_var1 = $cross_var2 = '';
			$categories1 = $categories2 = '';
			$maxx = $minx = $maxy = $miny = $maxz = $minz = 0;
			$must_wait = "NO";
			$dbml = null;
			$possible_models = $possible_models_id = array();
		}
		echo $this->container->getTwig()->render('mltemplate/mlcrossvar3dfa.html.twig',
			array(
				'selected' => 'mlcrossvar3dfa',
				'jsonData' => $jsonData,
				'variable1' => $cross_var1,
				'variable2' => $cross_var2,
				'categories1' => $categories1,
				'categories2' => $categories2,
				'maxx' => $maxx, 'minx' => $minx,
				'maxy' => $maxy, 'miny' => $miny,
				'maxz' => $maxz, 'minz' => $minz,
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
				'current_model' => $current_model,
				'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
				'models_id' => '[\''.implode("','",$possible_models_id).'\']',
				'must_wait' => $must_wait,
				'options' => Utils::getFilterOptions($db)
			)
		);	
	}
}
