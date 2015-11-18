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
		$jsonData = $jsonHeader = '[]';
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

/*TODO			$this->buildFilters(array(
			'percent' => array(
				'type' => 'selectOne',
				'default' => array('20%'),
				'label' => 'Top split: ',
				'generateChoices' => function() {
					$retval = array();
					foreach (range(0, 100, 10) as $rg) $retval[] = $rg.'%';
					return $retval;
				},
				'parseFunction' => function() {
					$choice = isset($_GET['percent']) ? $_GET['percent'] : array('20%');
					return array('whereClause' => '', 'currentChoice' => $choice);
				},
				'filterGroup' => 'MLearning'
			)
			));*/

			$this->buildFilters();

//TODO			$this->buildFilterGroups(array('MLearning' => array('label' => 'Pattern Mining', 'tabOpenDefault' => true, 'filters' => array('percent'))));

			if ($instructions)
			{
				MLUtils::getIndexVarweightsExps ($jsonVarweightsExps, $jsonVarweightsExpsHeader, $dbml);
				return $this->render('mltemplate/mlvariableweight.html.twig', array('varweightsexps' => $jsonVarweightsExps, 'header_varweightsexps' => $jsonVarweightsExpsHeader,'jsonData' => '[]','jsonHeader' => '[]','instructions' => 'YES'));
			}

			$params = array();
			$param_names = array('bench','net','disk','maps','iosf','replication','iofilebuf','comp','blk_size','id_cluster','datanodes','vm_OS','vm_cores','vm_RAM','provider','vm_size','type','bench_type','hadoop_version','datasize','scale_factor'); // Order is important
			$params = $this->filters->getFiltersSelectedChoices($param_names);
			foreach ($param_names as $p) if (!is_null($params[$p]) && is_array($params[$p])) sort($params[$p]);

			$params_additional = array();
			$param_names_additional = array('datefrom','dateto','minexetime','maxexetime','valid','filter'); // Order is important
			$params_additional = $this->filters->getFiltersSelectedChoices($param_names_additional);

//TODO			$rulesParams = $this->filters->getFiltersSelectedChoices(array('percent'));
//TODO			$rules_percent = $rulesParams['percent'];

			$where_configs = $this->filters->getWhereClause();
			$where_configs = str_replace("AND .","AND ",$where_configs);

			// compose instance
			$instance = MLUtils::generateSimpleInstance($this->filters, $param_names, $params, true);
			$model_info = MLUtils::generateModelInfo($this->filters, $param_names, $params, true);
			$slice_info = MLUtils::generateDatasliceInfo($this->filters, $param_names_additional, $params_additional);

			$config = $model_info.' '.$slice_info.' vars';
//TODO			$config = $model_info.' '.$rules_percent.' '.$slice_info.' rules';
//TODO			$rules_options = 'percent="'.$rules_percent.'":quiet=1';

			$cache_ds = getcwd().'/cache/ml/'.md5($config).'-cache.csv';

			$is_cached_mysql = $dbml->query("SELECT count(*) as num FROM aloja_ml.variable_weights WHERE id_varweights = '".md5($config)."'");
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
				exec('cd '.getcwd().'/cache/ml ; '.getcwd().'/resources/queue -c "'.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m aloja_variable_relations -p saveall="'.md5($config).'" >/dev/null 2>&1; rm -f '.getcwd().'/cache/ml/'.md5($config).'.lock; touch '.md5($config).'.fin" > /dev/null 2>&1 -p 1 &');
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
				if (($handle = fopen(getcwd().'/cache/ml/'.md5($config).'-json.dat', 'r')) !== FALSE)
				{
					$jsonData = fgets($handle, 5000);
					$jsonData = trim(preg_replace('/\s+/', ' ', $jsonData));
					fclose($handle);
				}
				else throw new \Exception("R result files [json] not found. Check if R is working properly");

				// register model to DB
				$query = "INSERT IGNORE INTO aloja_ml.variable_weights (id_varweights,instance,model,dataslice,varweight_code)";
				$query = $query." VALUES ('".md5($config)."','".$instance."','".substr($model_info,1)."','".$slice_info."','".$jsonData."');";
				if ($dbml->query($query) === FALSE) throw new \Exception('Error when saving rules into DB');

				// Remove temporal files
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.csv');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.fin');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.dat');
				$output = shell_exec('rm -f '.getcwd().'/cache/ml/'.md5($config).'*.rds');
			}
			else
			{
				$cached_result = $dbml->query("SELECT varweight_code FROM aloja_ml.variable_weights WHERE id_varweights = '".md5($config)."'");
				$tmp_result = $cached_result->fetch();
				$jsonData = $tmp_result['varweight_code'];
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
