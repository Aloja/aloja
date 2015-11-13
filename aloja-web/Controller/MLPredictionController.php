<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\MLUtils;

class MLPredictionController extends AbstractController
{
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->removeFilters(array('prediction_model','upred','uobsr','warning','outlier','money'));
	}

	public function mlpredictionAction()
	{
		$jsonExecs = $jsonLearners = $jsonLearningHeader = '[]';
		$message = $instance = $error_stats = $config = $model_info = $slice_info = '';
		$max_x = $max_y = 0;
		$must_wait = 'NO';
		try
		{
			$dbml = new \PDO($this->container->get('config')['db_conn_chain'], $this->container->get('config')['mysql_user'], $this->container->get('config')['mysql_pwd']);
			$dbml->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
			$dbml->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);

			$db = $this->container->getDBUtils();

			// FIXME - This must be counted BEFORE building filters, as filters inject rubbish in GET when there are no parameters...
			$instructions = count($_GET) <= 1;

			if (array_key_exists('dump',$_GET)) { $dump = $_GET["dump"]; unset($_GET["dump"]); }
			if (array_key_exists('pass',$_GET)) { $pass = $_GET["pass"]; unset($_GET["pass"]); }

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
			), 'umodel' => array(
				'type' => 'checkbox',
				'default' => 1,
				'label' => 'Unrestricted to new values',
				'parseFunction' => function() {
					$choice = (isset($_GET['submit']) && !isset($_GET['umodel'])) ? 0 : 1;
					return array('whereClause' => '', 'currentChoice' => $choice);
				},
				'filterGroup' => 'MLearning')
			));
			$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('learn','umodel'))));

			if ($instructions)
			{
				MLUtils::getIndexModels ($jsonLearners, $jsonLearningHeader, $dbml);
				return $this->render('mltemplate/mlprediction.html.twig', array('jsonExecs' => $jsonExecs, 'learners' => $jsonLearners, 'header_learners' => $jsonLearningHeader, 'instructions' => 'YES'));
			}

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

			$learnParams = $this->filters->getFiltersSelectedChoices(array('learn','umodel'));
			$learn_param = $learnParams['learn'];
			$unrestricted = ($learnParams['umodel']) ? true : false;

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters,$param_names, $params, $unrestricted);
			$model_info = MLUtils::generateModelInfo($this->filters,$param_names, $params, $unrestricted);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters,$param_names_additional, $params_additional);

			$config = $model_info.' '.$learn_param.' '.(($unrestricted)?'U':'R').' '.$slice_info;
			$learn_options = 'saveall='.md5($config);

			if ($learn_param == 'regtree') { $learn_method = 'aloja_regtree'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param == 'nnet') { $learn_method = 'aloja_nnet'; $learn_options .= ':prange=0,20000'; }
			else if ($learn_param == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3:prange=0,20000'; }

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');
			$finished_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.fin');

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

				$reference_cluster = 21; #FIXME - Reference Cluster should come from parameter, or fixed when selected for 1st time

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
				exec('cd '.getcwd().'/cache/ml ; touch '.getcwd().'/cache/ml/'.md5($config).'.lock');
				exec('cd '.getcwd().'/cache/ml ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options.' > /dev/null 2>&1; rm -f '.getcwd().'/cache/ml/'.md5($config).'.lock; touch '.md5($config).'.fin" > /dev/null 2>&1 -p 1 &');
			}

			$in_process = file_exists(getcwd().'/cache/ml/'.md5($config).'.lock');

			if ($in_process)
			{
				$must_wait = "YES";
				if (isset($dump)) { echo "1"; exit(0); }
				if (isset($pass)) { return 1; }
				throw new \Exception('WAIT');
			}

			// Retrieve / Process the Learning
			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.learners WHERE id_learner = '".md5($config)."'");
			$tmp_result = $is_cached_mysql->fetch();
			$is_cached = ($tmp_result['num'] > 0);

			if (!$is_cached) 
			{
				// register model to DB
				$query = "INSERT IGNORE INTO aloja_ml.learners (id_learner,instance,model,algorithm,dataslice)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$learn_param."','".$slice_info."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving model into DB');

				// read results of the CSV and dump to DB
				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-predictions.csv', 'r')) !== FALSE)
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
						$query = $query."('".$id_exec."','".$predid."','".$exe_time."','".$pred_time."','".md5($config)."','".$specific_instance."','".$full_instance."','".(($code=='tt')?3:(($code=='tv')?2:1))."') ";								
						if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving into DB');
					}
					fclose($handle);
				}
				else throw new \Exception('Error on R processing. Result file '.md5($config).'-predictions.csv not present');

				// Store file model to DB
				$filemodel = getcwd().'/cache/ml/'.md5($config).'-object.rds';
				$fp = fopen($filemodel, 'r');
				$content = fread($fp, filesize($filemodel));
				$content = addslashes($content);
				fclose($fp);

				$query = "INSERT INTO aloja_ml.model_storage (id_hash,type,file) VALUES ('".md5($config)."','learner','".$content."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving file model into DB');

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.fin');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.dat');
			}

			// Retrieve results from DB
			$count = 0;
			$error_stats = '';
			$jsonExecs = array();

			$query = "SELECT exe_time, pred_time, instance FROM aloja_ml.predictions WHERE id_learner='".md5($config)."' AND exe_time > 100 LIMIT 5000"; // FIXME - CLUMPSY PATCH FOR BYPASS THE BUG FROM HIGHCHARTS... REMEMBER TO ERASE THIS LIMIT WHEN THE BUG IS SOLVED
			$result = $dbml->query($query);
			foreach ($result as $row)
			{
				$jsonExecs[$count]['y'] = (int)$row['exe_time'];
				$jsonExecs[$count]['x'] = (int)$row['pred_time'];
				$jsonExecs[$count]['mydata'] = implode(",",array_slice(explode(",",$row['instance']),0,21));

				if ((int)$row['exe_time'] > $max_y) $max_y = (int)$row['exe_time'];
				if ((int)$row['pred_time'] > $max_x) $max_x = (int)$row['pred_time'];
				$count++;
			}

			$query = "SELECT AVG(ABS(exe_time - pred_time)) AS MAE, AVG(ABS(exe_time - pred_time)/exe_time) AS RAE, predict_code FROM aloja_ml.predictions WHERE id_learner='".md5($config)."' AND predict_code > 0 AND exe_time > 100 GROUP BY predict_code";
			$result = $dbml->query($query);
			foreach ($result as $row)
			{
				$error_stats = $error_stats.'Dataset: '.(($row['predict_code']==1)?'tr':(($row['predict_code']==2)?'tv':'tt')).' => MAE: '.$row['MAE'].' RAE: '.$row['RAE'].'<br/>';
			}

			if (isset($dump))
			{
				$data = json_encode($jsonExecs);
				echo "Observed, Predicted, Execution\n";
				echo str_replace(array('},{"y":','"x":','"mydata":','[{"y":','"}]'),array("\n",'','','',''),$data);
				exit(0);
			}
			if (isset($pass))
			{
				$data = json_encode($jsonExecs);
				$retval = "Observed, Predicted, Execution\n";
				$retval = $retval.str_replace(array('},{"y":','"x":','"mydata":','[{"y":','"}]'),array("\n",'','','',''),$data);
				return $retval;
			}
		}
		catch(\Exception $e)
		{
			if ($e->getMessage () != "WAIT")
			{
				$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
			}
			$jsonExecs = '[]';
		}
		$dbml = null;

		$return_params = array(
			'jsonExecs' => json_encode($jsonExecs),
			'learners' => $jsonLearners,
			'header_learners' => $jsonLearningHeader,
			'max_p' => min(array($max_x,$max_y)),
			'must_wait' => $must_wait,
			'instance' => $instance,
			'model_info' => $model_info,
			'slice_info' => $slice_info,
			'id_learner' => md5($config),
			'error_stats' => $error_stats,
		);
		return $this->render('mltemplate/mlprediction.html.twig', $return_params);
	}
}
?>
