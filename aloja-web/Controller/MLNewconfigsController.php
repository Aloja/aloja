<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLNewconfigsController extends AbstractController
{
	public function read_params($item_name)
	{
		if (isset($_GET[$item_name]) && $_GET[$item_name] != '')
		{
			$items = $_GET[$item_name];
			if (is_array($items))
			{
				if (($key = array_search('None', $items)) !== false) unset ($items[$key]);
			}
		}
		else $items = array();
	
		return $items;
	}

	public function add_where_configs($item_name, &$where_configs)
	{
		$items = MLNewconfigsController::read_params($item_name);
		if ($items) $where_configs .= ' AND e.'.$item_name.' IN ("'.join('","', $items).'")';
		return;	
	}

	public function getFilterOptions($dbUtils)
	{
		$options['bench'] = $dbUtils->get_rows("SELECT DISTINCT bench FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
		$options['net'] = $dbUtils->get_rows("SELECT DISTINCT net FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY net ASC");
		$options['disk'] = $dbUtils->get_rows("SELECT DISTINCT disk FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY disk ASC");
		$options['blk_size'] = $dbUtils->get_rows("SELECT DISTINCT blk_size FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY blk_size ASC");
		$options['comp'] = $dbUtils->get_rows("SELECT DISTINCT comp FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY comp ASC");
		$options['id_cluster'] = $dbUtils->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name from aloja2.execs e JOIN aloja2.clusters c using (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
		$options['maps'] = $dbUtils->get_rows("SELECT DISTINCT maps FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY maps ASC");
		$options['replication'] = $dbUtils->get_rows("SELECT DISTINCT replication FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY replication ASC");
		$options['iosf'] = $dbUtils->get_rows("SELECT DISTINCT iosf FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iosf ASC");
		$options['iofilebuf'] = $dbUtils->get_rows("SELECT DISTINCT iofilebuf FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iofilebuf ASC");
		$options['datanodes'] = $dbUtils->get_rows("SELECT DISTINCT datanodes FROM aloja2.execs e JOIN aloja2.clusters USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datanodes ASC");
		$options['benchtype'] = $dbUtils->get_rows("SELECT DISTINCT bench_type FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench_type ASC");
		$options['vm_size'] = $dbUtils->get_rows("SELECT DISTINCT vm_size FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_size ASC");
		$options['vm_cores'] = $dbUtils->get_rows("SELECT DISTINCT vm_cores FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_cores ASC");
		$options['vm_RAM'] = $dbUtils->get_rows("SELECT DISTINCT vm_RAM FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_RAM ASC");
		$options['hadoop_version'] = $dbUtils->get_rows("SELECT DISTINCT hadoop_version FROM aloja2.execs e WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY hadoop_version ASC");
		$options['type'] = $dbUtils->get_rows("SELECT DISTINCT type FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY type ASC");
		$options['presets'] = $dbUtils->get_rows("SELECT * FROM aloja2.filter_presets ORDER BY short_name DESC");
		$options['provider'] = $dbUtils->get_rows("SELECT DISTINCT provider FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY provider DESC;");
		$options['vm_OS'] = $dbUtils->get_rows("SELECT DISTINCT vm_OS FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_OS DESC;");
		$options['datasize'] = $dbUtils->get_rows("SELECT DISTINCT datasize FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datasize ASC;");
		$options['scale_factor'] = $dbUtils->get_rows("SELECT DISTINCT scale_factor FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY scale_factor ASC;");
		return $options;
	}

	public function mlnewconfigsAction()
	{
		$jsonData = $jsonHeader = $configs = $jsonNewconfs = $jsonNewconfsHeader = '[]';
		$message = $instance = $config = $model_info = $slice_info = '';
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$reference_cluster = $this->container->get('config')['ml_refcluster'];

			$db = $this->container->getDBUtils();
		    	$where_configs = '';

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			// Where_Configs and Manual Presets
			if (count($_GET) <= 1
			|| (count($_GET) == 2 && array_key_exists('learn',$_GET)))
			{
				$_GET['id_cluster'] = $params['id_cluster'] = array('3','5','8'); $where_configs .= ' AND id_cluster IN (3,5,8)';
				//$_GET['bench'] = $params['bench'] = array('terasort'); $where_configs .= ' AND bench IN ("terasort")';
				//$_GET['disk'] = $params['disk'] = array('HDD','SSD'); $where_configs .= ' AND disk IN ("HDD","SSD")';
				$_GET['blk_size'] = $params['blk_size'] = array('64','128','256'); $where_configs .= ' AND blk_size IN ("64","128","256")';
				$_GET['iofilebuf'] = $params['iofilebuf'] = array('32768','65536','131072'); $where_configs .= ' AND iofilebuf IN ("32768","65536","131072")';
				$_GET['comp'] = $params['comp'] = array('0'); $where_configs .= ' AND comp IN ("0")';
				$_GET['replication'] = $params['replication'] = array('1'); $where_configs .= ' AND replication IN ("1")';
				//$_GET['hadoop_version'] = $params['hadoop_version'] = array('1','1.03','2'); $where_configs .= ' AND hadoop_version IN ("1","1.03","2")';
				//$_GET['bench_type'] = $params['bench_type'] = array('HiBench'); $where_configs .= ' AND bench_type IN ("HiBench")';

				$_GET['datanodes'] = $params['datanodes'] = array('3');// $where_configs .= ' AND datanodes = 3';
				$_GET['vm_OS'] = $params['vm_OS'] = array('linux');// $where_configs .= ' AND vm_OS = "linux"';				
				$_GET['vm_size'] = $params['vm_size'] = array('SYS-6027R-72RF');// $where_configs .= ' AND vm_size = "SYS-6027R-72RF"';
				$_GET['vm_cores'] = $params['vm_cores'] = array('12');// $where_configs .= ' AND vm_cores = 12';
				$_GET['vm_RAM'] = $params['vm_RAM'] = array('128');// $where_configs .= ' AND vm_RAM = 128';
				$_GET['type'] = $params['type'] = array('On-premise');// $where_configs .= ' AND type = "On-premise"';
				$_GET['provider'] = $params['provider'] = array('on-premise');// $where_configs .= ' AND provider = "on-premise"';

				$_GET['datefrom'] = $params['datefrom'] = '';
				$_GET['dateto'] = $params['dateto'] = '';
				$_GET['maxexetime'] = $params['maxexetime'] = 20000;
				$_GET['minexetime'] = $params['minexetime'] = 1;
			}
			else
			{
				$param_names_whereconfig = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','bench_type','hadoop_version','datasize','scale_factor');
				foreach ($param_names_whereconfig as $p) MLNewconfigsController::add_where_configs($p,$where_configs);

				$where_configs .= ((isset($_GET['datefrom']) && $_GET['datefrom'] != '')?' AND start_time >= '.$_GET['datefrom']:'').
						  ((isset($_GET['dateto']) && $_GET['dateto'] != '')?' AND end_time <= '.$_GET['dateto']:'').
						  ((isset($_GET['minexetime']) && $_GET['minexetime'] != '')?' AND exe_time >= '.$_GET['minexetime']:'').
						  ((isset($_GET['maxexetime']) && $_GET['maxexetime'] != '')?' AND exe_time <= '.$_GET['maxexetime']:'').
						  ((isset($_GET['valid']))?' AND valid = '.$_GET['valid']:'').
						  ((isset($_GET['filter']))?' AND filter = '.$_GET['filter']:'');
			}

			// Real fetching of parameters
			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			foreach ($param_names as $p) { $params[$p] = MLNewconfigsController::read_params($p); sort($params[$p]); }

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			foreach ($param_names_additional as $p) { $params_additional[$p] = MLNewconfigsController::read_params($p); }

			$learn_param = (array_key_exists('learn',$_GET))?$_GET['learn']:'regtree';
			$param_id_cluster = $params['id_cluster']; unset($params['id_cluster']); // Exclude the param from now on

			$where_configs = str_replace("AND .","AND ",$where_configs);

			// Semi-Dummy Filters (For ModelInfo and SimpleInstance)
			$this->buildFilters(array('learn' => array(
				'type' => 'selectOne',
				'default' => array('regtree'),
				'label' => 'Learning method: ',
				'generateChoices' => function() {
					return array('regtree','nneighbours','nnet','polyreg');
				},
				'beautifier' => function($value) {
					$labels = array('regtree' => 'Regression Tree','nneighbours' => 'k-NN',
						'nnet' => 'NNets','polyreg' => 'PolyReg-3');
					return $labels[$value];
				},
				'parseFunction' => function() {
					$choice = isset($_GET['learn']) ? $_GET['learn'] : array('regtree');
					return array('whereClause' => '', 'currentChoice' => $choice);
				},
				'filterGroup' => 'MLearning'
			),
			'minexetime' => array('default' => 1),
			'maxexetime' => array('default' => 20000),
			'datefrom' => array('default' => ''),
			'dateto' => array('default' => ''),
			'valid' => array('default' => 1),
			'filter' => array('default' => 1),
			'prepares' => array('default' => 0)
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('learn'))));

			if ($instructions)
			{
				MLUtils::getIndexNewconfs ($jsonNewconfs, $jsonNewconfsHeader, $dbml);
				$params['id_cluster'] = $param_id_cluster;
				$return_params = array(
					'selected' => 'mlnewconfigs',
					'instructions' => 'YES',
					'jsonData' => $jsonData,
					'jsonHeader' => $jsonHeader,
					'configs' => $configs,
					'newconfs' => $jsonNewconfs,
					'header_newconfs' => $jsonNewconfsHeader,
					'must_wait' => $must_wait,
					'options' => MLNewconfigsController::getFilterOptions($db)
				);
				foreach ($param_names as $p) $return_params[$p] = $params[$p];
				foreach ($param_names_additional as $p) $return_params[$p] = $params_additional[$p];
				echo $this->container->getTwig()->render('mltemplate/mlnewconfigs.html.twig', $return_params);
				return;
			}

			// compose instance
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, true, true);
			$param_names_aux = array_diff($param_names, array('id_cluster'));
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names_aux, $params, true, true);
			$instances = MLUtils::completeInstances($this->filters,array($instance), $param_names, $params, $db);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$learn_param.' '.$slice_info.' newminconfs';

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options ='kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options = 'prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options = 'ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config."M")."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."' AND id_learner = '".md5($config."M")."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = $is_cached && ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

			// Create Models and Predictions
			if (!$is_cached && !$in_process && !$finished_process)
			{
				$exec_names = array(
					'idexec' => 'ID','benchmark' => 'Benchmark','exetime' => 'Exe.Time','net' => 'Net','disk' => 'Disk','maps' => 'Maps','iosfac' => 'IO.SFac',
					'rep' => 'Rep','iofbuf' => 'IO.FBuf','comp' => 'Comp','blksize' => 'Blk.size','idcluster' => 'ID.Cluster', 'clname' => 'Cl.Name',
					'datanodes' => 'Datanodes','vmos' => 'VM.OS','vmcores' => 'VM.Cores','vmram' => 'VM.RAM','provider' => 'Provider','vmsize' => 'VM.Size',
					'type' => 'Service.Type','benchtype' => 'Bench.Type','hadoopversion'=>'Hadoop.Version','datasize' =>'Datasize','scalefactor' => 'Scale.Factor'
				);
				$exec_query = array(
					'e.id_exec' => 'idexec','e.bench' => 'benchmark','e.exe_time' => 'exetime','e.net' => 'net','e.disk' => 'disk','e.maps' => 'maps','e.iosf' => 'iosfac',
					'e.replication' => 'rep','e.iofilebuf' => 'iofbuf','CONCAT("Cmp",e.comp)' => 'comp','e.blk_size' => 'blksize','CONCAT("Cl",e.id_cluster)' => 'idcluster', 'c.name' => 'clname',
					'c.datanodes' => 'datanodes','c.vm_OS' => 'vmos','c.vm_cores' => 'vmcores','c.vm_RAM' => 'vmram','c.provider' => 'provider','c.vm_size' => 'vmsize',
					'c.type' => 'type','e.bench_type' => 'benchtype','CONCAT("V",LEFT(REPLACE(e.hadoop_version,"-",""),1))'=>'hadoopversion','IFNULL(e.datasize,0)' =>'datasize','e.scale_factor' => 'scalefactor'
				); #FIXME - Make hadoop.version standard
				$net_names = array(
					'maxtxkbs' => 'Net.maxtxKB.s','maxrxkbs' => 'Net.maxrxKB.s','maxtxpcks' => 'Net.maxtxPck.s','maxrxpcks' => 'Net.maxrxPck.s',
					'maxtxcmps' => 'Net.maxtxCmp.s','maxrxcmps' => 'Net.maxrxCmp.s','maxrxmscts' => 'Net.maxrxmsct.s'
				);
				$net_query = array(
					'n1.`maxtxkB/s`' => 'maxtxkbs','n1.`maxrxkB/s`' => 'maxrxkbs','n1.`maxtxpck/s`' => 'maxtxpcks','n1.`maxrxpck/s`' => 'maxrxpcks',
					'n1.`maxtxcmp/s`' => 'maxtxcmps', 'n1.`maxrxcmp/s`' => 'maxrxcmps', 'n1.`maxrxmcst/s`' => 'maxrxmscts',
				);
				$disk_names = array(
					'maxtps' => 'Disk.maxtps','maxsvctm' => 'Disk.maxsvctm','maxrds' => 'Disk.maxrd.s','maxwrs' => 'Disk.maxwr.s',
					'maxrqsz' => 'Disk.maxrqsz','maxqusz' => 'Disk.maxqusz','maxawait' => 'Disk.maxawait','maxutil' => 'Disk.maxutil'
				);
				$disk_query = array(
					'd1.maxtps' => 'maxtps', 'd1.maxsvctm' => 'maxsvctm','d1.`maxrd_sec/s`' => 'maxrds', 'd1.`maxwr_sec/s`' => 'maxwrs',
					'd1.maxrq_sz' => 'maxrqsz', 'd1.maxqu_sz' => 'maxqusz','d1.maxawait' => 'maxawait', 'd1.`max%util`' => 'maxutil',
				);
				$bench_names = array(
					'pcavguser' => 'BMK.CPU.avguser','pcmaxuser' => 'BMK.CPU.maxuser','pcminuser' => 'BMK.CPU.minuser','pcstddevpopuser' => 'BMK.CPU.sdpopuser','pcvarpopuser' => 'BMK.CPU.varpopuser','pcavgnice' => 'BMK.CPU.avgnice','pcmaxnice' => 'BMK.CPU.maxnice','pcminnice' => 'BMK.CPU.minnice','pcstddevpopnice' => 'BMK.CPU.sdpopnice','pcvarpopnice' => 'BMK.CPU.varpopnice','pcavgsystem' => 'BMK.CPU.avgsystem','pcmaxsystem' => 'BMK.CPU.maxsystem','pcminsystem' => 'BMK.CPU.minsystem','pcstddevpopsystem' => 'BMK.CPU.sdpopsystem','pcvarpopsystem' => 'BMK.CPU.varpopsystem','pcavgiowait' => 'BMK.CPU.avgiowait','pcmaxiowait' => 'BMK.CPU.maxiowait','pcminiowait' => 'BMK.CPU.miniowait','pcstddevpopiowait' => 'BMK.CPU.sdpopiowait','pcvarpopiowait' => 'BMK.CPU.varpopiowait','pcavgsteal' => 'BMK.CPU.avgsteal','pcmaxsteal' => 'BMK.CPU.maxsteal','pcminsteal' => 'BMK.CPU.minsteal','pcstddevpopsteal' => 'BMK.CPU.sdpopsteal','pcvarpopsteal' => 'BMK.CPU.varpopsteal','pcavgidle' => 'BMK.CPU.avgidle','pcmaxidle' => 'BMK.CPU.maxidle','pcminidle' => 'BMK.CPU.minidle','pcstddevpopidle' => 'BMK.CPU.sdpopidle','pcvarpopidle' => 'BMK.CPU.varpopidle',
					'pmavgkbmemfree' => 'BMK.MEM.avgKBmemfree','pmmaxkbmemfree' => 'BMK.MEM.maxKBmemfree','pmminkbmemfree' => 'BMK.MEM.minKBmemfree','pmstddevpopkbmemfree' => 'BMK.MEM.sdpopKBmemfree','pmvarpopkbmemfree' => 'BMK.MEM.varpopKBmemfree','pmavgkbmemused' => 'BMK.MEM.avgKBmemused','pmmaxkbmemused' => 'BMK.MEM.maxKBmemused','pmminkbmemused' => 'BMK.MEM.minKBmemused','pmstddevpopkbmemused' => 'BMK.MEM.sdpopKBmemused','pmvarpopkbmemused' => 'BMK.MEM.varpopKBmemused','pmavgmemused' => 'BMK.MEM.avgmemused','pmmaxmemused' => 'BMK.MEM.maxmemused','pmminmemused' => 'BMK.MEM.minmemused','pmstddevpopmemused' => 'BMK.MEM.sdpopmemused','pmvarpopmemused' => 'BMK.MEM.varpopmemused','pmavgkbbuffers' => 'BMK.MEM.avgKBbuffers','pmmaxkbbuffers' => 'BMK.MEM.maxKBbuffers','pmminkbbuffers' => 'BMK.MEM.minKBbuffers','pmstddevpopkbbuffers' => 'BMK.MEM.sdpopKBbuffers','pmvarpopkbbuffers' => 'BMK.MEM.varpopKBbuffers','pmavgkbcached' => 'BMK.MEM.avgKBcached','pmmaxkbcached' => 'BMK.MEM.maxKBcached','pmminkbcached' => 'BMK.MEM.minKBcached','pmstddevpopkbcached' => 'BMK.MEM.sdpopKBcached','pmvarpopkbcached' => 'BMK.MEM.varpopKBcached','pmavgkbcommit' => 'BMK.MEM.avgKBcommit','pmmaxkbcommit' => 'BMK.MEM.maxKBcommit','pmminkbcommit' => 'BMK.MEM.minKBcommit','pmstddevpopkbcommit' => 'BMK.MEM.sdpopKBcommit','pmvarpopkbcommit' => 'BMK.MEM.varpopKBcommit','pmavgcommit' => 'BMK.MEM.avgcommit','pmmaxcommit' => 'BMK.MEM.maxcommit','pmmincommit' => 'BMK.MEM.mincommit','pmstddevpopcommit' => 'BMK.MEM.sdpopcommit','pmvarpopcommit' => 'BMK.MEM.varpopcommit','pmavgkbactive' => 'BMK.MEM.avgKBactive','pmmaxkbactive' => 'BMK.MEM.maxKBactive','pmminkbactive' => 'BMK.MEM.minKBactive','pmstddevpopkbactive' => 'BMK.MEM.sdpopKBactive','pmvarpopkbactive' => 'BMK.MEM.varpopKBactive','pmavgkbinact' => 'BMK.MEM.avgKBinact','pmmaxkbinact' => 'BMK.MEM.maxKBinact','pmminkbinact' => 'BMK.MEM.minKBinact','pmstddevpopkbinact' => 'BMK.MEM.sdpopKBinact','pmvarpopkbinact' => 'BMK.MEM.varpopKBinact',
					'pnavgrxpcks' => 'BMK.NET.avgRXpcks','pnmaxrxpcks' => 'BMK.NET.maxRXpcks','pnminrxpcks' => 'BMK.NET.minRXpcks','pnstddevpoprxpcks' => 'BMK.NET.sdpopRXpcks','pnvarpoprxpcks' => 'BMK.NET.varpopRXpcks','pnsumrxpcks' => 'BMK.NET.sumRXpcks','pnavgtxpcks' => 'BMK.NET.avgTXpcks','pnmaxtxpcks' => 'BMK.NET.maxTXpcks','pnmintxpcks' => 'BMK.NET.minTXpcks','pnstddevpoptxpcks' => 'BMK.NET.sdpopTXpcks','pnvarpoptxpcks' => 'BMK.NET.varpopTXpcks','pnsumtxpcks' => 'BMK.NET.sumTXpcks','pnavgrxkBs' => 'BMK.NET.avgRXKBs','pnmaxrxkBs' => 'BMK.NET.maxRXKBs','pnminrxkBs' => 'BMK.NET.minRXKBs','pnstddevpoprxkBs' => 'BMK.NET.sdpopRXKBs','pnvarpoprxkBs' => 'BMK.NET.varpopRXKBs','pnsumrxkBs' => 'BMK.NET.sumRXKBs','pnavgtxkBs' => 'BMK.NET.avgTXKBs','pnmaxtxkBs' => 'BMK.NET.maxTXKBs','pnmintxkBs' => 'BMK.NET.minTXKBs','pnstddevpoptxkBs' => 'BMK.NET.sdpopTXKBs','pnvarpoptxkBs' => 'BMK.NET.varpopTXKBs','pnsumtxkBs' => 'BMK.NET.sumTXKBs','pnavgrxcmps' => 'BMK.NET.avgRXcmps','pnmaxrxcmps' => 'BMK.NET.maxRXcmps','pnminrxcmps' => 'BMK.NET.minRXcmps','pnstddevpoprxcmps' => 'BMK.NET.sdpopRXcmps','pnvarpoprxcmps' => 'BMK.NET.varpopRXcmps','pnsumrxcmps' => 'BMK.NET.sumRXcmps','pnavgtxcmps' => 'BMK.NET.avgTXcmps','pnmaxtxcmps' => 'BMK.NET.maxTXcmps','pnmintxcmps' => 'BMK.NET.minTXcmps','pnstddevpoptxcmps' => 'BMK.NET.sdpopTXcmps','pnvarpoptxcmps' => 'BMK.NET.varpopTXcmps','pnsumtxcmps' => 'BMK.NET.sumTXcmps','pnavgrxmcsts' => 'BMK.NET.avgRXcsts','pnmaxrxmcsts' => 'BMK.NET.maxRXcsts','pnminrxmcsts' => 'BMK.NET.minRXcsts','pnstddevpoprxmcsts' => 'BMK.NET.sdpopRXcsts','pnvarpoprxmcsts' => 'BMK.NET.varpopRXcsts','pnsumrxmcsts' => 'BMK.NET.sumRXcsts',
					'pdavgtps' => 'BMK.DSK.avgtps','pdmaxtps' => 'BMK.DSK.maxtps','pdmintps' => 'BMK.DSK.mintps','pdavgrdsecs' => 'BMK.DSK.avgRDs','pdmaxrdsecs' => 'BMK.DSK.maxRDs','pdminrdsecs' => 'BMK.DSK.minRDs','pdstddevpoprdsecs' => 'BMK.DSK.sdpopRDs','pdvarpoprdsecs' => 'BMK.DSK.varpopRDs','pdsumrdsecs' => 'BMK.DSK.sumRDs','pdavgwrsecs' => 'BMK.DSK.avgWRs','pdmaxwrsecs' => 'BMK.DSK.maxWRs','pdminwrsecs' => 'BMK.DSK.minWRs','pdstddevpopwrsecs' => 'BMK.DSK.sdpopWRs','pdvarpopwrsecs' => 'BMK.DSK.varpopWRs','pdsumwrsecs' => 'BMK.DSK.sumWRs','pdavgrqsz' => 'BMK.DSK.avgReqs','pdmaxrqsz' => 'BMK.DSK.maxReqs','pdminrqsz' => 'BMK.DSK.minReqs','pdstddevpoprqsz' => 'BMK.DSK.sdpopReqs','pdvarpoprqsz' => 'BMK.DSK.varpopReqs','pdavgqusz' => 'BMK.DSK.avgQus','pdmaxqusz' => 'BMK.DSK.maxQus','pdminqusz' => 'BMK.DSK.minQus','pdstddevpopqusz' => 'BMK.DSK.sdpopQus','pdvarpopqusz' => 'BMK.DSK.varpopQus','pdavgawait' => 'BMK.DSK.avgwait','pdmaxawait' => 'BMK.DSK.maxwait','pdminawait' => 'BMK.DSK.minwait','pdstddevpopawait' => 'BMK.DSK.sdpopwait','pdvarpopawait' => 'BMK.DSK.varpopwait','pdavgutil' => 'BMK.DSK.avgutil','pdmaxutil' => 'BMK.DSK.maxutil','pdminutil' => 'BMK.DSK.minutil','pdstddevpoputil' => 'BMK.DSK.sdpoputil','pdvarpoputil' => 'BMK.DSK.varpoputil','pdavgsvctm' => 'BMK.DSK.avgsvctm','pdmaxsvctm' => 'BMK.DSK.maxsvctm','pdminsvctm' => 'BMK.DSK.minsvctm','pdstddevpopsvctm' => 'BMK.DSK.sdpopsvctm','pdvarpopsvctm' => 'BMK.DSK.varpopsvctm'
				);
				$bench_query = array(
					'pc.`avg%user`' => 'pcavguser','pc.`max%user`' => 'pcmaxuser','pc.`min%user`' => 'pcminuser','pc.`stddev_pop%user`' => 'pcstddevpopuser','pc.`var_pop%user`' => 'pcvarpopuser','pc.`avg%nice`' => 'pcavgnice','pc.`max%nice`' => 'pcmaxnice','pc.`min%nice`' => 'pcminnice','pc.`stddev_pop%nice`' => 'pcstddevpopnice','pc.`var_pop%nice`' => 'pcvarpopnice','pc.`avg%system`' => 'pcavgsystem','pc.`max%system`' => 'pcmaxsystem','pc.`min%system`' => 'pcminsystem','pc.`stddev_pop%system`' => 'pcstddevpopsystem','pc.`var_pop%system`' => 'pcvarpopsystem','pc.`avg%iowait`' => 'pcavgiowait','pc.`max%iowait`' => 'pcmaxiowait','pc.`min%iowait`' => 'pcminiowait','pc.`stddev_pop%iowait`' => 'pcstddevpopiowait','pc.`var_pop%iowait`' => 'pcvarpopiowait','pc.`avg%steal`' => 'pcavgsteal','pc.`max%steal`' => 'pcmaxsteal','pc.`min%steal`' => 'pcminsteal','pc.`stddev_pop%steal`' => 'pcstddevpopsteal','pc.`var_pop%steal`' => 'pcvarpopsteal','pc.`avg%idle`' => 'pcavgidle','pc.`max%idle`' => 'pcmaxidle','pc.`min%idle`' => 'pcminidle','pc.`stddev_pop%idle`' => 'pcstddevpopidle','pc.`var_pop%idle`' => 'pcvarpopidle',
					'pm.`avgkbmemfree`' => 'pmavgkbmemfree','pm.`maxkbmemfree`' => 'pmmaxkbmemfree','pm.`minkbmemfree`' => 'pmminkbmemfree','pm.`stddev_popkbmemfree`' => 'pmstddevpopkbmemfree','pm.`var_popkbmemfree`' => 'pmvarpopkbmemfree','pm.`avgkbmemused`' => 'pmavgkbmemused','pm.`maxkbmemused`' => 'pmmaxkbmemused','pm.`minkbmemused`' => 'pmminkbmemused','pm.`stddev_popkbmemused`' => 'pmstddevpopkbmemused','pm.`var_popkbmemused`' => 'pmvarpopkbmemused','pm.`avg%memused`' => 'pmavgmemused','pm.`max%memused`' => 'pmmaxmemused','pm.`min%memused`' => 'pmminmemused','pm.`stddev_pop%memused`' => 'pmstddevpopmemused','pm.`var_pop%memused`' => 'pmvarpopmemused','pm.`avgkbbuffers`' => 'pmavgkbbuffers','pm.`maxkbbuffers`' => 'pmmaxkbbuffers','pm.`minkbbuffers`' => 'pmminkbbuffers','pm.`stddev_popkbbuffers`' => 'pmstddevpopkbbuffers','pm.`var_popkbbuffers`' => 'pmvarpopkbbuffers','pm.`avgkbcached`' => 'pmavgkbcached','pm.`maxkbcached`' => 'pmmaxkbcached','pm.`minkbcached`' => 'pmminkbcached','pm.`stddev_popkbcached`' => 'pmstddevpopkbcached','pm.`var_popkbcached`' => 'pmvarpopkbcached','pm.`avgkbcommit`' => 'pmavgkbcommit','pm.`maxkbcommit`' => 'pmmaxkbcommit','pm.`minkbcommit`' => 'pmminkbcommit','pm.`stddev_popkbcommit`' => 'pmstddevpopkbcommit','pm.`var_popkbcommit`' => 'pmvarpopkbcommit','pm.`avg%commit`' => 'pmavgcommit','pm.`max%commit`' => 'pmmaxcommit','pm.`min%commit`' => 'pmmincommit','pm.`stddev_pop%commit`' => 'pmstddevpopcommit','pm.`var_pop%commit`' => 'pmvarpopcommit','pm.`avgkbactive`' => 'pmavgkbactive','pm.`maxkbactive`' => 'pmmaxkbactive','pm.`minkbactive`' => 'pmminkbactive','pm.`stddev_popkbactive`' => 'pmstddevpopkbactive','pm.`var_popkbactive`' => 'pmvarpopkbactive','pm.`avgkbinact`' => 'pmavgkbinact','pm.`maxkbinact`' => 'pmmaxkbinact','pm.`minkbinact`' => 'pmminkbinact','pm.`stddev_popkbinact`' => 'pmstddevpopkbinact','pm.`var_popkbinact`' => 'pmvarpopkbinact',
					'pn.`avgrxpck/s`' => 'pnavgrxpcks','pn.`maxrxpck/s`' => 'pnmaxrxpcks','pn.`minrxpck/s`' => 'pnminrxpcks','pn.`stddev_poprxpck/s`' => 'pnstddevpoprxpcks','pn.`var_poprxpck/s`' => 'pnvarpoprxpcks','pn.`sumrxpck/s`' => 'pnsumrxpcks','pn.`avgtxpck/s`' => 'pnavgtxpcks','pn.`maxtxpck/s`' => 'pnmaxtxpcks','pn.`mintxpck/s`' => 'pnmintxpcks','pn.`stddev_poptxpck/s`' => 'pnstddevpoptxpcks','pn.`var_poptxpck/s`' => 'pnvarpoptxpcks','pn.`sumtxpck/s`' => 'pnsumtxpcks','pn.`avgrxkB/s`' => 'pnavgrxkBs','pn.`maxrxkB/s`' => 'pnmaxrxkBs','pn.`minrxkB/s`' => 'pnminrxkBs','pn.`stddev_poprxkB/s`' => 'pnstddevpoprxkBs','pn.`var_poprxkB/s`' => 'pnvarpoprxkBs','pn.`sumrxkB/s`' => 'pnsumrxkBs','pn.`avgtxkB/s`' => 'pnavgtxkBs','pn.`maxtxkB/s`' => 'pnmaxtxkBs','pn.`mintxkB/s`' => 'pnmintxkBs','pn.`stddev_poptxkB/s`' => 'pnstddevpoptxkBs','pn.`var_poptxkB/s`' => 'pnvarpoptxkBs','pn.`sumtxkB/s`' => 'pnsumtxkBs','pn.`avgrxcmp/s`' => 'pnavgrxcmps','pn.`maxrxcmp/s`' => 'pnmaxrxcmps','pn.`minrxcmp/s`' => 'pnminrxcmps','pn.`stddev_poprxcmp/s`' => 'pnstddevpoprxcmps','pn.`var_poprxcmp/s`' => 'pnvarpoprxcmps','pn.`sumrxcmp/s`' => 'pnsumrxcmps','pn.`avgtxcmp/s`' => 'pnavgtxcmps','pn.`maxtxcmp/s`' => 'pnmaxtxcmps','pn.`mintxcmp/s`' => 'pnmintxcmps','pn.`stddev_poptxcmp/s`' => 'pnstddevpoptxcmps','pn.`var_poptxcmp/s`' => 'pnvarpoptxcmps','pn.`sumtxcmp/s`' => 'pnsumtxcmps','pn.`avgrxmcst/s`' => 'pnavgrxmcsts','pn.`maxrxmcst/s`' => 'pnmaxrxmcsts','pn.`minrxmcst/s`' => 'pnminrxmcsts','pn.`stddev_poprxmcst/s`' => 'pnstddevpoprxmcsts','pn.`var_poprxmcst/s`' => 'pnvarpoprxmcsts','pn.`sumrxmcst/s`' => 'pnsumrxmcsts',
					'pd.`avgtps`' => 'pdavgtps','pd.`maxtps`' => 'pdmaxtps','pd.`mintps`' => 'pdmintps','pd.`avgrd_sec/s`' => 'pdavgrdsecs','pd.`maxrd_sec/s`' => 'pdmaxrdsecs','pd.`minrd_sec/s`' => 'pdminrdsecs','pd.`stddev_poprd_sec/s`' => 'pdstddevpoprdsecs','pd.`var_poprd_sec/s`' => 'pdvarpoprdsecs','pd.`sumrd_sec/s`' => 'pdsumrdsecs','pd.`avgwr_sec/s`' => 'pdavgwrsecs','pd.`maxwr_sec/s`' => 'pdmaxwrsecs','pd.`minwr_sec/s`' => 'pdminwrsecs','pd.`stddev_popwr_sec/s`' => 'pdstddevpopwrsecs','pd.`var_popwr_sec/s`' => 'pdvarpopwrsecs','pd.`sumwr_sec/s`' => 'pdsumwrsecs','pd.`avgrq_sz`' => 'pdavgrqsz','pd.`maxrq_sz`' => 'pdmaxrqsz','pd.`minrq_sz`' => 'pdminrqsz','pd.`stddev_poprq_sz`' => 'pdstddevpoprqsz','pd.`var_poprq_sz`' => 'pdvarpoprqsz','pd.`avgqu_sz`' => 'pdavgqusz','pd.`maxqu_sz`' => 'pdmaxqusz','pd.`minqu_sz`' => 'pdminqusz','pd.`stddev_popqu_sz`' => 'pdstddevpopqusz','pd.`var_popqu_sz`' => 'pdvarpopqusz','pd.`avgawait`' => 'pdavgawait','pd.`maxawait`' => 'pdmaxawait','pd.`minawait`' => 'pdminawait','pd.`stddev_popawait`' => 'pdstddevpopawait','pd.`var_popawait`' => 'pdvarpopawait','pd.`avg%util`' => 'pdavgutil','pd.`max%util`' => 'pdmaxutil','pd.`min%util`' => 'pdminutil','pd.`stddev_pop%util`' => 'pdstddevpoputil','pd.`var_pop%util`' => 'pdvarpoputil','pd.`avgsvctm`' => 'pdavgsvctm','pd.`maxsvctm`' => 'pdmaxsvctm','pd.`minsvctm`' => 'pdminsvctm','pd.`stddev_popsvctm`' => 'pdstddevpopsvctm','pd.`var_popsvctm`' => 'pdvarpopsvctm'
				);

			    	// dump the result to csv
			    	$query = "SELECT
					".implode(',', array_map(function ($k, $v) { return sprintf("%s AS '%s'", $k, $v); }, array_keys($exec_query), array_values($exec_query))).",
					n.".implode(",n.",array_values($net_query)).",
					d.".implode(",d.",array_values($disk_query)).",
					b.".implode(",b.",array_values($bench_query))."
					FROM aloja2.execs AS e LEFT JOIN aloja2.clusters AS c ON e.id_cluster = c.id_cluster,
					(
					    SELECT ae.bench AS aebench,
					    ".implode(',', array_map(function ($k, $v) { return sprintf("AVG(%s) AS '%s'", $k, $v); }, array_keys($bench_query), array_values($bench_query)))."
					    FROM aloja2.precal_cpu_metrics AS pc, aloja2.precal_memory_metrics AS pm, aloja2.precal_network_metrics AS pn, aloja2.precal_disk_metrics AS pd, aloja2.execs AS ae
					    WHERE pc.id_exec = pm.id_exec AND pc.id_exec = pn.id_exec AND pc.id_exec = pd.id_exec AND pc.id_exec = ae.id_exec AND ae.id_cluster = '".$reference_cluster."'
					    GROUP BY ae.bench
					) AS b,
					(
					    SELECT
					    ".implode(',', array_map(function ($k, $v) { return sprintf("MAX(%s) AS '%s'", $k, $v); }, array_keys($net_query), array_values($net_query))).",
					    e1.net AS net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
					    FROM aloja2.precal_network_metrics AS n1,
					    aloja2.execs AS e1 LEFT JOIN aloja2.clusters AS c1 ON e1.id_cluster = c1.id_cluster
					    WHERE e1.id_exec = n1.id_exec
					    GROUP BY e1.net, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
					) AS n,
					(
					    SELECT
					    ".implode(',', array_map(function ($k, $v) { return sprintf("MAX(%s) AS '%s'", $k, $v); }, array_keys($disk_query), array_values($disk_query))).",
					    e2.disk AS disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
					    FROM aloja2.precal_disk_metrics AS d1,
					    aloja2.execs AS e2 LEFT JOIN aloja2.clusters AS c1 ON e2.id_cluster = c1.id_cluster
					    WHERE e2.id_exec = d1.id_exec
					    GROUP BY e2.disk, c1.vm_cores, c1.vm_RAM, c1.vm_size, c1.vm_OS, c1.provider
					) AS d
					WHERE e.bench = b.aebench AND e.net = n.net AND c.vm_cores = n.vm_cores AND c.vm_RAM = n.vm_RAM
					AND c.vm_size = n.vm_size AND c.vm_OS = n.vm_OS AND c.provider = n.provider AND e.disk = d.disk
					AND c.vm_cores = d.vm_cores AND c.vm_RAM = d.vm_RAM AND c.vm_size = d.vm_size AND c.vm_OS = d.vm_OS
					AND c.provider = d.provider
					AND hadoop_version IS NOT NULL".$where_configs.";";
			    	$rows = $db->get_rows ( $query );
				if (empty($rows)) throw new \Exception('No data matches with your critteria.');

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp,array_values(array_merge($exec_names,$net_names,$disk_names,$bench_names)),',','"');
			    	foreach($rows as $row) fputcsv($fp, array_values($row),',','"');

				// run the R processor
				$vin = "Benchmark,Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Datanodes,VM.OS,VM.Cores,VM.RAM,Provider,VM.Size,Service.Type,Bench.Type,Hadoop.Version,Datasize,Scale.Factor";
				$vin = $vin.",".implode(",",array_values($net_names)).",".implode(",",array_values($disk_names)).",".implode(",",array_values($bench_names));
				exec('cd '.getcwd().'/cache/ml; touch '.md5($config).'.lock');
				$command = getcwd().'/resources/queue -c "cd '.getcwd().'/cache/ml; ../../resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."F").':vin=\''.$vin.'\' >debug1.txt 2>&1 && ';
				$count = 1;
				foreach ($instances as $inst)
				{
					$command = $command.'../../resources/aloja_cli.r -m aloja_predict_instance -l '.md5($config."F").' -p inst_predict=\''.$inst.'\':saveall='.md5($config."D").'-'.($count++).':vin=\''.$vin.'\' >>debug2.txt 2>&1 && ';
				}
				$command = $command.' head -1 '.md5($config."D").'-1-dataset.data >'.md5($config."D").'-dataset.data 2>>debug2-1.txt && ';				
				$command = $command.' cat '.md5($config."D").'*-dataset.data >'.md5($config."D").'-aux.data 2>>debug2-1.txt && ';
				$command = $command.' grep -v "ID" '.md5($config."D").'*-aux.data >>'.md5($config."D").'-dataset.data 2>>debug2-1.txt && ';
				$command = $command.'../../resources/aloja_cli.r -d '.md5($config."D").'-dataset.data -m '.$learn_method.' -p '.$learn_options.':saveall='.md5($config."M").':vin=\''.$vin.'\' >debug3.txt 2>&1 && ';
				$command = $command.'../../resources/aloja_cli.r -m aloja_minimal_instances -l '.md5($config."M").' -p saveall='.md5($config.'R').':kmax=200 >debug4.txt 2>&1; rm -f '.md5($config).'.lock; touch '.md5($config).'.fin" >debug4.tmp 2>&1 &';
				exec($command);

				sleep(2);
			}
			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');

			if ($in_process)
			{
				$must_wait = "YES";
				throw new \Exception('WAIT');
			}

			$learners = array();
			$learners[] = md5($config."F");
			$learners[] = md5($config."M");
			foreach ($learners as $learner_1)
			{
				// Save learning model to DB, with predictions
				$is_cached_mysql = $dbml->query("SELECT id_learner FROM aloja_ml.learners WHERE id_learner = '".$learner_1."'");
				$tmp_result = $is_cached_mysql->fetch();
				if ($tmp_result['id_learner'] != $learner_1) 
				{
					// register model to DB
					$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice)";
					$query = $query." VALUES ('".$learner_1."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."');";

					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

					// read results of the CSV and dump to DB
					if (($handle = fopen(getcwd().'/cache/ml/'.$learner_1.'-predictions.csv', 'r')) !== FALSE)
					{
						$header = fgetcsv($handle, 5000, ",");
						while (($data = fgetcsv($handle, 5000, ",")) !== FALSE)
						{
							// INSERT INTO DB <INSTANCE>
							$selected = array_merge(array_slice($data,1,10),array_slice($data,18,4));
							$selected_inst = implode("','",$selected);
							$selected_inst = preg_replace('/,\'Cmp(\d+)\',/',',\'${1}\',',$selected_inst);
							$selected_inst = preg_replace('/,\'Cl(\d+)\',/',',\'${1}\',',$selected_inst);
							$query_i = "INSERT IGNORE INTO aloja_ml.pred_execs (bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,id_cluster,bench_type,hadoop_version,datasize,scale_factor,start_time,end_time) VALUES ";
							$query_i = $query_i."('".$selected_inst."',now(),now())";
							if ($dbml->query($query_i) === FALSE) throw new \Exception('Error when saving into DB');

							// GET REFERENCE IDs
							$where_clauses = '1=1';
							$where_names = array("bench","net","disk","maps","iosf","replication","iofilebuf","comp","blk_size","id_cluster","bench_type","hadoop_version","datasize","scale_factor");
							$selcount = 0;
							foreach($where_names as $wn) $where_clauses = $where_clauses.' AND '.$wn.' = \''.$selected[$selcount++].'\'';
							$where_clauses = preg_replace('/\'Cmp(\d+)\'/','\'${1}\'',$where_clauses);
							$where_clauses = preg_replace('/\'Cl(\d+)\'/','\'${1}\'',$where_clauses);

							$query = "SELECT id_prediction FROM aloja_ml.pred_execs WHERE ".$where_clauses.' LIMIT 1';
							$result = $dbml->query($query);
							$row = $result->fetch();
							$predid = (is_null($row['id_prediction']))?0:$row['id_prediction'];

							// INSERT INTO DB <PREDICTIONS>
							$id_exec = $data[0];
							$exe_time = $data[2];
							$pred_time = $data[key(array_slice($data,-2,1,TRUE))];
							$code = $data[key(array_slice($data,-1,1,TRUE))];
							$full_instance = implode(",",array_slice($data,1,-1));
							$specific_instance = array_merge(array($data[1]),array_slice($data, 3, 21));
							$specific_instance = implode(",",$specific_instance);

							$query = "INSERT IGNORE INTO aloja_ml.predictions (id_exec,id_pred_exec,exe_time,pred_time,id_learner,instance,full_instance,predict_code) VALUES ";
							$query = $query."('".$id_exec."','".$predid."','".$exe_time."','".$pred_time."','".$learner_1."','".$specific_instance."','".$full_instance."','".(($code=='tt')?3:(($code=='tv')?2:1))."') ";								
							if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
						}
						fclose($handle);
					}
					else throw new \Exception('Error on R processing. Result file '.$learner_1.'-predictions.csv not present');

					// Remove temporal files
					$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.$learner_1.'*.{dat,csv}');
				}
			}

			// Save minconfigs to DB, with props and centers
			$is_cached_mysql = $dbml->query("SELECT id_minconfigs FROM aloja_ml.minconfigs WHERE id_minconfigs = '".md5($config.'R')."'");
			$tmp_result = $is_cached_mysql->fetch();
			if ($tmp_result['id_minconfigs'] != md5($config.'R')) 
			{
				// register minconfigs to DB
				$query = "INSERT IGNORE INTO aloja_ml.minconfigs (id_minconfigs,id_learner,instance,model,is_new)";
				$query = $query." VALUES ('".md5($config.'R')."','".md5($config.'M')."','".$instance."','".substr($model_info,1)."','1');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving minconfis into DB');

				$clusters = array();

				// Save results of the CSV - MAE or RAE
				if (file_exists(getcwd().'/cache/ml/'.md5($config.'R').'-raes.csv')) $error_file = 'raes.csv'; else $error_file = 'maes.csv';
				$handle = fopen(getcwd().'/cache/ml/'.md5($config.'R').'-'.$error_file, 'r');
				while (($data = fgetcsv($handle, 5000, ",")) !== FALSE)
				{
					$cluster = (int)$data[0];
					if ($error_file == 'raes.csv') { $error_mae = 'NULL'; $error_rae = (float)$data[1]; }
					if ($error_file == 'maes.csv') { $error_mae = (float)$data[1]; $error_rae = 'NULL'; }

					// register minconfigs_props to DB
					$query = "INSERT INTO aloja_ml.minconfigs_props (id_minconfigs,cluster,MAE,RAE)";
					$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$error_mae."','".$error_rae."');";
					if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving minconfis into DB');

					$clusters[] = $cluster;
				}
				fclose($handle);

				// Save results of the CSV - Configs
				$handle_sizes = fopen(getcwd().'/cache/ml/'.md5($config.'R').'-sizes.csv', 'r');
				foreach ($clusters as $cluster)
				{
					// Get supports from sizes
					$sizes = fgetcsv($handle_sizes, 1000, ",");

					// Get clusters
					$handle = fopen(getcwd().'/cache/ml/'.md5($config.'R').'-dsk'.$cluster.'.csv', 'r');
					$header = fgetcsv($handle, 5000, ",");
					$i = 0;
					while (($data = fgetcsv($handle, 5000, ",")) !== FALSE)
					{
						$subdata1 = array_slice($data, 0, 11);
						$subdata2 = array_slice($data, 19, 4);
						$specific_data = implode(',',array_merge($subdata1,$subdata2));
						$specific_data = preg_replace('/,Cmp(\d+),/',',${1},',$specific_data);
						$specific_data = preg_replace('/,Cl(\d+),/',',${1},',$specific_data);
						$specific_data = preg_replace('/,Cl(\d+)/',',${1}',$specific_data);
						$specific_data = str_replace(",","','",$specific_data);

						// register minconfigs_props to DB
						$query = "INSERT INTO aloja_ml.minconfigs_centers (id_minconfigs,cluster,id_exec,bench,exe_time,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,bench_type,hadoop_version,datasize,scale_factor,support)";
						$query = $query." VALUES ('".md5($config.'R')."','".$cluster."','".$specific_data."','".$sizes[$i++]."');";
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving centers into DB');
					}
					fclose($handle);
				}
				fclose($handle_sizes);

				// Store file model to DB
				$filemodel = getcwd().'/cache/ml/'.md5($config.'F').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'F')."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				$filemodel = getcwd().'/cache/ml/'.md5($config.'M').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'M')."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				$filemodel = getcwd().'/cache/ml/'.md5($config.'R').'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config.'R')."','minconf','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file minconf into DB');

				// Remove temporal files
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'R').'*.rds');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'R').'*.dat');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'R').'*.csv');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'D').'*.csv');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'D').'*.dat');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'D').'*.data');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'F').'*.rds');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'F').'*.csv');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'F').'*.dat');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'M').'*.rds');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'M').'*.csv');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config.'M').'*.dat');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.csv');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.dat');
				exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.fin');
			}

			// Retrieve minconfig progression results from DB
			$header = "id_exec,exe_time,bench,net,disk,maps,iosf,replication,iofilebuf,comp,blk_size,bench_type,hadoop_version,datasize,scale_factor,support";
			$header_array = explode(",",$header);

			$last_y = 9E15;
			$configs = '[';

			$jsonData = array();

			$query = "SELECT cluster, MAE, RAE FROM aloja_ml.minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'";
			$result = $dbml->query($query);
			foreach ($result as $row)
			{
				// Retrieve minconfig progression results from DB
				if ((float)$row['MAE'] > 0) $error = (float)$row['MAE']; else $error = (float)$row['RAE'];
				$cluster = (int)$row['cluster'];

				$new_val = array();
				$new_val['x'] = $cluster;
				if ($error > $last_y) $new_val['y'] = $last_y;
				else $last_y = $new_val['y'] = $error;

				$jsonData[] = $new_val;

				// Retrieve minconfig centers from DB
				$query_2 = "SELECT ".$header." FROM aloja_ml.minconfigs_centers WHERE id_minconfigs='".md5($config.'R')."' AND cluster='".$cluster."'";
				$result_2 = $dbml->query($query_2);

				$jsonConfig = '[';
				foreach ($result_2 as $row_2)
				{
					$values = '';
					foreach ($header_array as $ha) $values = $values.(($values!='')?',':'').'\''.$row_2[$ha].'\'';
					$jsonConfig = $jsonConfig.(($jsonConfig!='[')?',':'').'['.$values.']';
				}
				$jsonConfig = $jsonConfig.']';
				
				$configs = $configs.(($configs!='[')?',':'').$jsonConfig;
			}
			$configs = $configs.']';
			$jsonData = json_encode($jsonData);
			$jsonHeader = '[{title:""},{title:"Est.Time"},{title:"Benchmark"},{title:"Network"},{title:"Disk"},{title:"Maps"},{title:"IO.SF"},{title:"Replicas"},{title:"IO.FBuf"},{title:"Compression"},{title:"Blk.Size"},{title:"Bench.Type"},{title:"Hadoop.Ver"},{title:"Data.Size"},{title:"Scale.Factor"},{title:"Support"}]';

			$query = "SELECT MAX(cluster) as mcluster, MAX(MAE) as mmae, MAX(RAE) as mrae FROM aloja_ml.minconfigs_props WHERE id_minconfigs='".md5($config.'R')."'";
			$is_cached_mysql = $dbml->query($query);

			$tmp_result = $is_cached_mysql->fetch();
			$max_x = ((float)$tmp_result['mmae'] > 0)?(float)$tmp_result['mmae']:(float)$tmp_result['mrae'];
			$max_y = (float)$tmp_result['mcluster'];
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonData = $jsonHeader = $configs = '[]';
		}
		$dbml = null;

		$params['id_cluster'] = $param_id_cluster;
		$return_params = array(
			'selected' => 'mlnewconfigs',
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'configs' => $configs,
			'newconfs' => $jsonNewconfs,
			'header_newconfs' => $jsonNewconfsHeader,
			'max_p' => min(array($max_x,$max_y)),
			'instance' => $instance,
			'id_newconf' => md5($config),
			'id_newconf_first' => md5($config.'F'),
			'id_newconf_dataset' => md5($config.'D'),
			'id_newconf_model' => md5($config.'M'),
			'id_newconf_result' => md5($config.'R'),
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'learn' => $learn_param,
			'must_wait' => $must_wait,
			'options' => MLNewconfigsController::getFilterOptions($db)
		);
		foreach ($param_names as $p) $return_params[$p] = $params[$p];
		foreach ($param_names_additional as $p) $return_params[$p] = $params_additional[$p];
		echo $this->container->getTwig()->render('mltemplate/mlnewconfigs.html.twig', $return_params);	
	}
}
