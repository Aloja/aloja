<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLWeightController extends AbstractController
{
	public function __construct($container)
	{
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier','money'));
	}

	public function mlvariableweightAction()
	{
		$config = $instance = $model_info = $slice_info = '';
		$jsonData = $jsonHeader = $jsonLinreg = $jsonRegtree = '[]';
		$jsonVarweightsExps = $jsonVarweightsExpsHeader = '[]';
		$must_wait = "NO";
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);
			$dbml->setAttribute(\PDO::MYSQL_ATTR_MAX_BUFFER_SIZE, 1024*1024*50);

			$reference_cluster = $this->container->get('config')['ml_refcluster'];

			$db = $this->container->getDBUtils();

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			$this->buildFilters();

			if ($instructions)
			{
				MLUtils::getIndexVarweightsExps ($jsonVarweightsExps, $jsonVarweightsExpsHeader, $dbml);
				return $this->render('mltemplate/mlvariableweight.html.twig', array('varweightsexps' => $jsonVarweightsExps, 'header_varweightsexps' => $jsonVarweightsExpsHeader,'jsonData' => '[]','jsonLinreg' => '[]','jsonRegtree' => '[]','jsonHeader' => '[]','instructions' => 'YES'));
			}

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters, $param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters, $param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters, $param_names_additional, $params_additional);

			$config = $model_info.' '.$slice_info.' vars';

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.variable_weights WHERE id_varweights = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

			if (!$is_cached && !$in_process && !$finished_process)
			{
				// dump the result to csv
				$file_header = "";
				$learn_options = "";
				$query = MLUtils::getQuery($file_header,$reference_cluster,$where_configs);
			    	$rows = $db->get_rows ( $query );
				if (empty($rows))
				{
					// Try legacy
					$query = MLUtils::getLegacyQuery ($file_header,$where_configs);
					$learn_options .= ':vin=Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor';
				    	$rows = $db->get_rows ( $query );
					if (empty($rows))
					{
						throw new \Exception('No data matches with your critteria.');
					}
					$is_legacy = 1;
				}

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp,$file_header,',','"');
			    	foreach($rows as $row) fputcsv($fp, array_values($row),',','"');

				// run the R processor
				exec('cd '.getcwd().'/cache/ml ; touch '.getcwd().'/cache/ml/'.md5($config).'.lock');
				exec('cd '.getcwd().'/cache/ml ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m aloja_variable_relations -p saveall="'.md5($config).'-vr"'.$learn_options.' >/dev/null 2>&1; '.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m  aloja_variable_quicklm -p saveall="'.md5($config).'-lm":sample=1'.$learn_options.' >/dev/null 2>&1; '.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m  aloja_variable_quickrt -p saveall="'.md5($config).'-rt":sample=1'.$learn_options.' >/dev/null 2>&1; rm -f '.getcwd().'/cache/ml/'.md5($config).'.lock; touch '.md5($config).'.fin" > /dev/null 2>&1 -p 1 &');
			}

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

			if ($in_process)
			{
				$must_wait = "YES";
				throw new \Exception("WAIT");
			}

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.variable_weights WHERE id_varweights = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			if (!$is_cached) 
			{
				// read results of the CSV and dump to DB
				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-vr-json.dat', 'r')) !== FALSE)
				{
					$jsonData = fgets($handle, 5000);
					$jsonData = trim(preg_replace('/\s+/', ' ', $jsonData));
					fclose($handle);
				}
				else throw new \Exception("R result files [vr-json] not found. Check if R is working properly");

				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-lm-json.dat', 'r')) !== FALSE)
				{
					$jsonLinreg = fgets($handle, 5000);
					$jsonLinreg = trim(preg_replace('/\s+/', ' ', $jsonLinreg));
					fclose($handle);
				}
				else throw new \Exception("R result files [lm-json] not found. Check if R is working properly");

				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-rt-json.dat', 'r')) !== FALSE)
				{
					$jsonRegtree = fgets($handle, 20000);
					$jsonRegtree = trim(preg_replace('/\s+/', ' ', $jsonRegtree));
					fclose($handle);
				}
				else throw new \Exception("R result files [rt-json] not found. Check if R is working properly");

				// register model to DB
				$query = "INSERT IGNORE INTO aloja_ml.variable_weights (id_varweights,instance,model,dataslice,varweight_code,linreg_code,regtree_code)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$slice_info."','".$jsonData."','".$jsonLinreg."','".$jsonRegtree."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving rules into DB');

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.fin');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.dat');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.rds');
			}
			else
			{
				$cached_result = $dbml->query("SELECT varweight_code, linreg_code, regtree_code FROM aloja_ml.variable_weights WHERE id_varweights = '".md5($config)."'");
				$tmp_result = $cached_result->fetch();
				$jsonData = $tmp_result['varweight_code'];
				$jsonLinreg = $tmp_result['linreg_code'];
				$jsonRegtree = $tmp_result['regtree_code'];
			}
			$jsonHeader = '[{title:"Description"},{title:"Reference"},{title:"Intercept"},{title:"Relations"},{title:"Message"}]';
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
		}
		$dbml = null;

		$return_params = array(
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'jsonLinreg' => $jsonLinreg,
			'jsonRegtree' => $jsonRegtree,
			'varweightsexps' => $jsonVarweightsExps,
			'header_varweightsexps' => $jsonVarweightsExpsHeader,
			'must_wait' => $must_wait,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'id_variableweight' => md5($config)
		);
		return $this->render('mltemplate/mlvariableweight.html.twig', $return_params);
	}
}
?>
