<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLFindAttributesController extends AbstractController
{
	public function mlfindattributesAction()
	{
		$instance = $message = $tree_descriptor = '';
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

			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists("current_model",$_GET))
			|| (count($_GET) == 2 && array_key_exists("dump",$_GET))
			|| (count($_GET) == 2 && array_key_exists("tree",$_GET))
			|| (count($_GET) == 3 && array_key_exists("dump",$_GET) && array_key_exists("current_model",$_GET))
			|| (count($_GET) == 3 && array_key_exists("tree",$_GET) && array_key_exists("current_model",$_GET)))
			{
				$where_configs = '';
				$params['benchs'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				$params['disks'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$params['iofilebufs'] = array('65536','131072'); $where_configs .= ' AND iofilebuf IN ("65536","131072")';
				$params['comps'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$params['replications'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				$params['id_clusters'] = array('1'); $where_configs .= ' AND id_cluster IN ("1")';
				$params['mapss'] = array('4'); $where_configs .= ' AND maps IN ("4")';
				$params['iosfs'] = array('10'); $where_configs .= ' AND iosf IN ("10")';
				$params['blk_sizes'] = array('128'); $where_configs .= ' AND blk_size IN ("128")';
				$unseen = FALSE;
			}

			$jsonData = $jsonHeader = "[]";
			$mae = $rae = $count_preds = 0;

			// compose instance
			$model_info = MLUtils::generateModelInfo($param_names, $params, $unseen, $db);
			$instance = MLUtils::generateSimpleInstance($param_names, $params, $unseen, $db);			
			$instances = MLUtils::generateInstances($param_names, $params, $unseen, $db);

			// Model for filling
			MLUtils::findMatchingModels($model_info, $possible_models, $possible_models_id, $db);

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
				$finished_process = $in_process && ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));
				$is_cached = file_exists($cache_filename);

				if (!$in_process && !$finished_process && !$is_cached)
				{
					exec('cd '.getcwd().'/cache/query ; touch '.md5($instance.'-'.$model).'.lock ; rm -f '.$tmp_file);
					foreach ($instances as $inst)
					{
						exec(getcwd().'/resources/queue -c "cd '.getcwd().'/cache/query ; '.getcwd().'/resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict=\''.$inst.'\' -v | grep -v \'WARNING\' | grep -v \'Prediction\' >> '.$tmp_file.' 2> /dev/null; echo 1 >> '.md5($instance.'-'.$model).'.lock" > /dev/null 2>&1 &');
					}
				}

				$finished_process = ((int)shell_exec('wc -l '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock | awk \'{print $1}\'') == count($instances));
				$is_cached = file_exists($cache_filename);

				if ($finished_process && !$is_cached)
				{
					// read results
					$lines = explode("\n", file_get_contents($tmp_file));
					$jsonData = '[';
					$i = 0;
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
					shell_exec('rm -f '.getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				}

				$in_process = file_exists(getcwd().'/cache/query/'.md5($instance.'-'.$model).'.lock');
				$is_cached = file_exists($cache_filename);

				if (!$is_cached)
				{
					$jsonData = $jsonHeader = $jsonColumns = $jsonColor = '[]';
					$must_wait = 'YES';
					if (isset($_GET['dump'])) { echo "1"; exit(0); }
				}
				else
				{
					if (isset($_GET['dump']))
					{
						$data = explode("\n",file_get_contents($cache_filename));
						echo "ID".str_replace(array("[","]","{title:\"","\"}"),array('','',''),$data[0])."\n";
						echo str_replace(array('],[','[[',']]'),array("\n",'',''),$data[1]);
						exit(0);
					}

					// get cache
					$data = explode("\n",file_get_contents($cache_filename));
					$jsonHeader = $data[0];
					$jsonData = $data[1];

					$data = explode("\n",file_get_contents(str_replace('.csv','.data',$cache_filename)));
					$mae = $data[0];
					$rae = $data[1];

					$tree_descriptor = shell_exec(''.getcwd().'/resources/aloja_cli.r -m aloja_representative_tree -p method=ordered:dump_file="'.$tmp_file.'":output="html" -v 2> /dev/null');
					$tree_descriptor = substr($tree_descriptor, 5, -2);
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
				'tree' => (isset($_GET['tree'])?"true":"false"),
				'tree_descriptor' => $tree_descriptor,
				'options' => Utils::getFilterOptions($db)
			)
		);
	}

	public function mlattributestreeAction()
	{
		$_GET['tree'] = 1;
		$this->mlfindattributesAction();
	}
}
?>
