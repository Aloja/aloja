<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class DefaultController extends AbstractController
{
    public static $show_in_result = array(
			'id_exec' => 'ID',
			'bench' => 'Benchmark',
			'exe_time' => 'Exe Time',
			'exec' => 'Exec Conf',
			'cost' => 'Running Cost $',
			'net' => 'Net',
			'disk' => 'Disk',
			'maps' => 'Maps',
			'iosf' => 'IO SFac',
			'replication' => 'Rep',
			'iofilebuf' => 'IO FBuf',
			'comp' => 'Comp',
			'blk_size' => 'Blk size',
			'id_cluster' => 'Cluster',
            'vm_OS' => 'OS',
            'cdesc' => 'Cluster description',
			'datanodes' => 'Datanodes',
            'exec_type' => 'Type',
			'prv' => 'PARAVER',
			//'version' => 'Hadoop v.',
			'init_time' => 'End time',
			'hadoop_version' => 'H Version',
			'bench_type' => 'Bench',
            'counters' => 'Counters'
	);

    public function indexAction()
    {
        return $this->render('welcome.html.twig', array());
    }

    public function configImprovementAction()
    {
        $db = $this->container->getDBUtils();

        $this->buildFilters();
        $whereClause = $this->filters->getWhereClause();
       
        $rows_config = '';
        try {
            $concat_config = "";
            $selectedGroups = array();
            if(isset($_GET['selected-groups']) && $_GET['selected-groups'] != "") {
               $selectedGroups = explode(",",$_GET['selected-groups']);
           	   $concat_config = Utils::getConfig($selectedGroups);
            }
            else {
            	$concat_config = 'disk';
            	$selectedGroups = array('disk');
            }

            $filter_execs = DBUtils::getFilterExecs();
            $order_conf = 'LENGTH(conf), conf';

            //get configs first (categories)
            $query = "SELECT count(*) num, concat($concat_config) conf from execs e
                      JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause
                      GROUP BY conf ORDER BY $order_conf #AVG(exe_time)
                      ;";

            $rows_config = $db->get_rows($query);

            $height = 600;

            if (count($rows_config) > 4) {
                $num_configs = count($rows_config);
                $height = round($height + (10*($num_configs-4)));
            }

            //get the result rows
            //#(select CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) FROM execs e WHERE bench = e.bench $filter_execs $whereClause) P50_ALL_exe_time,
            $query = "SELECT #count(*),
            		  e.id_exec,
                      concat($concat_config) conf, bench,
                      avg(exe_time) AVG_exe_time,
                      #max(exe_time) MAX_exe_time,
                      min(exe_time) MIN_exe_time,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P50_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 95/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P95_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 05/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P05_exe_time`,
                      (select AVG(exe_time) FROM execs WHERE bench = e.bench $whereClause) AVG_ALL_exe_time,
                      #(select MAX(exe_time) FROM execs WHERE bench = e.bench $whereClause) MAX_ALL_exe_time,
                      #(select MIN(exe_time) FROM execs WHERE bench = e.bench $whereClause) MIN_ALL_exe_time,
                      'none'
                      from execs e JOIN clusters USING (id_cluster)
                      WHERE 1 $filter_execs $whereClause
                      GROUP BY conf, bench order by bench, $order_conf;";

            $rows = $db->get_rows($query);

            if ($rows) {
                //print_r($rows);
            } else {
                throw new \Exception("No results for query!");
            }

        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        $categories = '';
        $count = 0;
        $confOrders = array();
        foreach ($rows_config as $row_config) {
            $categories .= "'{$row_config['conf']} #{$row_config['num']}',";
            $count += $row_config['num'];
            $confOrders[] = $row_config['conf'];
        }

        $series = '';
        $bench = '';
        if ($rows) {
            $seriesIndex = 0;
            foreach ($rows as $row) {
                //close previous serie if not first one
                if ($bench && $bench != strtolower($row['bench'])) {
                    $series .= "]
                        }, ";
                }
                //starts a new series
                if ($bench != strtolower($row['bench'])) {
                    $seriesIndex = 0;
                    $bench = strtolower($row['bench']);
                    $series .= "
                        {
                            name: '".strtolower($row['bench'])."',
                                data: [";
                }
                while($row['conf'] != $confOrders[$seriesIndex]) {
                    $series .= "[null],";
                    $seriesIndex++;
                }
                $series .= "['{$row['conf']}',".
                    //round((($row['AVG_exe_time']-$row['MIN_ALL_exe_time'])/(0.0001+$row['MAX_ALL_exe_time']-$row['MIN_ALL_exe_time'])), 3).
                    //round(($row['AVG_exe_time']), 3).
                    round(($row['AVG_ALL_exe_time']/$row['AVG_exe_time']), 3). //
                    "],";
                $seriesIndex++;

            }
            //close the last series
            $series .= "]
                    }, ";
        }

        return $this->render ( 'config_improvement/config_improvement.html.twig', array (
                'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
                'highcharts_js' => HighCharts::getHeader(),
                'categories' => $categories,
                'series' => $series,
            )
        );
    }

    public function benchExecutionsAction()
    {
        $dbUtils = $this->container->getDBUtils();
        $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
        $whereClause = $this->filters->getWhereClause();

		$type = Utils::get_GET_string("pageTab");
		
		if(!$type)
			$type = 'SUMMARY';
		
		if($type == 'SUMMARY') {
			$show_in_result = array(
					'id_exec' => 'ID',
					'bench' => 'Benchmark',
					'exe_time' => 'Exe Time',
					'exec' => 'Exec Conf',
					'cost' => 'Running Cost $',
					'id_cluster' => 'Cluster',
                    'vm_OS' => 'OS',
                    'cdesc' => 'Cluster description',
					'datanodes' => 'Datanodes',
					'prv' => 'PARAVER',
					//'version' => 'Hadoop v.',
					'init_time' => 'End time',
					'hadoop_version' => 'H Version',
					'bench_type' => 'Bench',
			);
		} else if($type == 'HWCONFIG') {
			$show_in_result = array(
            			'id_exec' => 'ID',
            			'bench' => 'Benchmark',
            			'exe_time' => 'Exe Time',
            			'exec' => 'Exec Conf',
            			'cost' => 'Running Cost $',
            			'net' => 'Net',
            			'disk' => 'Disk',
            			'id_cluster' => 'Cluster',
                        'vm_OS' => 'OS',
                        'cdesc' => 'Cluster description',
            			'datanodes' => 'Datanodes',
            			'prv' => 'PARAVER',
            			//'version' => 'Hadoop v.',
            			'init_time' => 'End time',
            			'hadoop_version' => 'H Version',
            			'bench_type' => 'Bench',
            	);
		} else if($type == 'SWCONFIG') {
			$show_in_result = array(
					'id_exec' => 'ID',
					'bench' => 'Benchmark',
					'exe_time' => 'Exe Time',
					'exec' => 'Exec Conf',
					'cost' => 'Running Cost $',
					'net' => 'Net',
					'disk' => 'Disk',
					'maps' => 'Maps',
					'iosf' => 'IO SFac',
					'replication' => 'Rep',
					'iofilebuf' => 'IO FBuf',
					'comp' => 'Comp',
					'blk_size' => 'Blk size',
					'id_cluster' => 'Cluster',
                    'vm_OS' => 'OS',
                    'cdesc' => 'Cluster description',
			  		'datanodes' => 'Datanodes',
					'prv' => 'PARAVER',
					//'version' => 'Hadoop v.',
					'init_time' => 'End time',
					'hadoop_version' => 'H Version',
					'bench_type' => 'Bench',
			);
		} else
			$show_in_result = self::$show_in_result;

        $discreteOptions = Utils::getExecsOptions($this->container->getDBUtils(),$whereClause);
        return $this->render('benchexecutions/benchexecutions.html.twig',
            array(
                'theaders' => $show_in_result,
            	'clustersInfo' => Utils::getClustersInfo($dbUtils),
            	'type' => $type,
                'discreteOptions' => $discreteOptions
            ));
    }

    public function costPerfEvaluationAction()
    {
        $filter_execs = DBUtils::getFilterExecs();
        $dbUtils = $this->container->getDBUtils();
        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne')));
        $whereClause = $this->filters->getWhereClause();
        
        try {
            if(isset($_GET['benchs']))
                $_GET['benchs'] = $_GET['benchs'][0];

            if (isset($_GET['benchs']) and strlen($_GET['benchs']) > 0) {
                $bench = $_GET['benchs'];
                $bench_where = " AND bench = '$bench'";
            } else {
                $bench = 'terasort';
                $bench_where = " AND bench = '$bench'";
            }

            /*
             * 1. Get execs and cluster associated costs
             * 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
             * 3. Calculate max and minimum costs
             * 4. calculate max and minimum exe times
             * 5. Normalize costs and exe times
             * 6. Print results
             */

            $minCost = -1;
            $maxCost = 0;
            $minExeTime = -1;
            $maxExeTime = 0;

            $execs = "SELECT e.*, c.* FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $bench_where $whereClause ORDER BY rand() LIMIT 500";

            $execs = $dbUtils->get_rows($execs);
            if(!$execs)
                throw new \Exception("No results for query!");

            foreach($execs as &$exec) {
                $costHour = (isset($_GET['cost_hour'][$exec['id_cluster']])) ? $_GET['cost_hour'][$exec['id_cluster']] : $exec['cost_hour'];
                $_GET['cost_hour'][$exec['id_cluster']] = $costHour;

                $costRemote = (isset($_GET['cost_remote'][$exec['id_cluster']])) ? $_GET['cost_remote'][$exec['id_cluster']] : $exec['cost_remote'];
                $_GET['cost_remote'][$exec['id_cluster']] = $costRemote;

                $costSSD = (isset($_GET['cost_SSD'][$exec['id_cluster']])) ? $_GET['cost_SSD'][$exec['id_cluster']] : $exec['cost_SSD'];
                $_GET['cost_SSD'][$exec['id_cluster']] = $costSSD;

                $costIB = (isset($_GET['cost_IB'][$exec['id_cluster']])) ? $_GET['cost_IB'][$exec['id_cluster']] : $exec['cost_IB'];
                $_GET['cost_IB'][$exec['id_cluster']] = $costIB;

                $exec['cost_std'] = Utils::getExecutionCost($exec, $costHour, $costRemote, $costSSD, $costIB);

                if($exec['cost_std'] > $maxCost)
                    $maxCost = $exec['cost_std'];
                if($exec['cost_std'] < $minCost || $minCost == -1)
                    $minCost = $exec['cost_std'];

                if($exec['exe_time']<$minExeTime || $minExeTime == -1)
                    $minExeTime = $exec['exe_time'];
                if($exec['exe_time']>$maxExeTime)
                    $maxExeTime = $exec['exe_time'];
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
        }

//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,

        $seriesData = '';
        foreach ($execs as $exec) {
        	$exeTimeStd = 0.01;
        	$costTimeStd = 0.01;
        	if(count($execs) > 1) {
        		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
        		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
        		
        		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
        		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
        	}

            $seriesData .= "{
            name: '" . $exec['exec'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . "]], idexec: ${exec['id_exec']}},";
        }

        $clusters = $dbUtils->get_rows("SELECT * FROM clusters WHERE id_cluster IN (SELECT DISTINCT id_cluster FROM execs e WHERE 1 $filter_execs);");

        return $this->render('perf_by_cost/perf_by_cost.html.twig', array(
            'selected' => 'Cost Evaluation',
            'highcharts_js' => HighCharts::getHeader(),
            'cost_hour' => isset($_GET['cost_hour']) ? $_GET['cost_hour'] : null,
            'cost_remote' => isset($_GET['cost_remote']) ? $_GET['cost_remote'] : null,
            'cost_SSD' => isset($_GET['cost_SSD']) ? $_GET['cost_SSD'] : null,
            'cost_IB' => isset($_GET['cost_IB']) ? $_GET['cost_IB'] : null,
            'seriesData' => $seriesData,
            'title' => 'Normalized Cost by Performance Evaluation of Hadoop Executions',
            'clusters' => $clusters,
            'select_multiple_benchs' => false
        ));
    }

    public function performanceChartsAction()
    {
        $exec_rows = null;
        $id_exec_rows = null;
        $dbUtil = $this->container->getDBUtils();

        try {
            //TODO fix, initialize variables
            $dbUtil->get_exec_details('1', 'id_exec',$exec_rows,$id_exec_rows);

            //check the URL
            $execs = Utils::get_GET_execs();

            if (Utils::get_GET_string('random') && !$execs) {
                $keys = array_keys($exec_rows);
                $execs = array_unique(array($keys[array_rand($keys)], $keys[array_rand($keys)]));
            }
            if (Utils::get_GET_string('hosts')) {
                $hosts = Utils::get_GET_string('hosts');
            } else {
                $hosts = 'Slaves';
            }
            if (Utils::get_GET_string('metric')) {
                $metric = Utils::get_GET_string('metric');
            } else {
                $metric = 'CPU';
            }

            if (Utils::get_GET_string('aggr')) {
                $aggr = Utils::get_GET_string('aggr');
            } else {
                $aggr = 'AVG';
            }

            if (Utils::get_GET_string('detail')) {
                $detail = Utils::get_GET_int('detail');
            } else {
                $detail = 10;
            }

            if ($aggr == 'AVG') {
                $aggr_text = "Average";
            } elseif ($aggr == 'SUM') {
                $aggr_text = "SUM";
            } else {
                throw new \Exception("Aggregation type '$aggr' is not valid.");
            }

            if ($hosts == 'Slaves') {
                $selectedHosts = $dbUtil->get_rows("SELECT h.host_name from execs e inner join hosts h where e.id_exec IN (".implode(", ", $execs).") AND h.id_cluster = e.id_cluster AND h.role='slave'");

                $selected_hosts = array();
                foreach($selectedHosts as $host) {
                    array_push($selected_hosts, $host['host_name']);
                }
            } elseif ($hosts == 'Master') {
                $selectedHosts = $dbUtil->get_rows("SELECT h.host_name from execs e inner join hosts h where e.id_exec IN (".implode(", ", $execs).") AND h.id_cluster = e.id_cluster AND h.role='master' AND h.host_name != ''");

                $selected_hosts = array();
                foreach($selectedHosts as $host) {
                    array_push($selected_hosts, $host['host_name']);
                }
            } else {
                $selected_hosts = array($hosts);
            }

            $charts = array();
            $exec_details = array();
            $chart_details = array();

            $clusters = array();

            foreach ($execs as $exec) {
                //do a security check
                $tmp = filter_var($exec, FILTER_SANITIZE_NUMBER_INT);
                if (!is_numeric($tmp) || !($tmp > 0) ) {
                    unset($execs[$exec]);
                    continue;
                }

                $exec_title = $dbUtil->get_exec_details($exec, 'exec',$exec_rows,$id_exec_rows);

                $pos_name = strpos($exec_title, '/');
                $exec_title =
                    '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'.
                    strtoupper(substr($exec_title, ($pos_name+1))).
                    '&nbsp;'.
                    ((strpos($exec_title, '_az') > 0) ? 'AZURE':'LOCAL').
                    "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ID_$exec ".
                    substr($exec_title, 21, (strlen($exec_title) - $pos_name - ((strpos($exec_title, '_az') > 0) ? 21:18)))
                ;

                $exec_details[$exec]['time']        = $dbUtil->get_exec_details($exec, 'exe_time',$exec_rows,$id_exec_rows);
                $exec_details[$exec]['start_time']  = $dbUtil->get_exec_details($exec, 'start_time',$exec_rows,$id_exec_rows);
                $exec_details[$exec]['end_time']    = $dbUtil->get_exec_details($exec, 'end_time',$exec_rows,$id_exec_rows);

                $id_cluster = $dbUtil->get_exec_details($exec, 'id_cluster',$exec_rows,$id_exec_rows);
                if (!in_array($id_cluster, $clusters)) $clusters[] = $id_cluster;

                //$end_time = get_exec_details($exec, 'init_time');

                $date_where     = " AND date BETWEEN '{$exec_details[$exec]['start_time']}' and '{$exec_details[$exec]['end_time']}' ";

                $where          = " WHERE id_exec = '$exec' AND host IN ('".join("','", $selected_hosts)."') $date_where";
                $where_BWM      = " WHERE id_exec = '$exec' AND host IN ('".join("','", $selected_hosts)."') ";

                $where_VMSTATS  = " WHERE id_exec = '$exec' AND host IN ('".join("','", $selected_hosts)."') ";

                $where_sampling = "round(time/$detail)";
                $group_by       = " GROUP BY $where_sampling ORDER by time";

                $group_by_vmstats = " GROUP BY $where_sampling ORDER by time";

                $where_sampling_BWM = "round(unix_timestamp/$detail)";
                $group_by_BWM = " GROUP BY $where_sampling_BWM ORDER by unix_timestamp";

                $charts[$exec] = array(
                    'job_status' => array(
                        'metric'    => "ALL",
                        'query'     => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time,
                        maps map,shuffle,merge,reduce,waste FROM JOB_status
                        WHERE id_exec = '$exec' $date_where GROUP BY job_name, date ORDER by job_name, time;",
                        'fields'    => array('map', 'shuffle', 'reduce', 'waste', 'merge'),
                        'title'     => "Job execution history $exec_title ",
                        'group_title' => 'Job execution history (number of running Hadoop processes)',
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'cpu' => array(
                        'metric'    => "CPU",
                        'query'     => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`%user`) `%user`, $aggr(`%system`) `%system`, $aggr(`%steal`) `%steal`, $aggr(`%iowait`)
                        `%iowait`, $aggr(`%nice`) `%nice` FROM SAR_cpu $where $group_by;",
                        'fields'    => array('%user', '%system', '%steal', '%iowait', '%nice'),
                        'title'     => "CPU Utilization ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Utilization '."($aggr_text, $hosts)",
                        'percentage'=> ($aggr == 'SUM' ? '300':100),
                        'stacked'   => true,
                        'negative'  => false,
                    ),
                    'load' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`ldavg-1`) `ldavg-1`, $aggr(`ldavg-5`) `ldavg-5`, $aggr(`ldavg-15`) `ldavg-15`
                        FROM SAR_load $where $group_by;",
                        'fields'    => array('ldavg-15', 'ldavg-5', 'ldavg-1'),
                        'title'     => "CPU Load Average ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Load Average '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'load_queues' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`runq-sz`) `runq-sz`, $aggr(`blocked`) `blocked`
                        FROM SAR_load $where $group_by;",
                        'fields'    => array('runq-sz', 'blocked'),
                        'title'     => "CPU Queues ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Queues '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'load_tasks' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`plist-sz`) `plist-sz` FROM SAR_load $where $group_by;",
                        'fields'    => array('plist-sz'),
                        'title'     => "Number of tasks for CPUs ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Number of tasks for CPUs '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'switches' => array(
                        'metric'    => "CPU",
                        'query'     => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`proc/s`) `proc/s`, $aggr(`cswch/s`) `cswch/s` FROM SAR_switches $where $group_by;",
                        'fields'    => array('proc/s', 'cswch/s'),
                        'title'     => "CPU Context Switches ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Context Switches'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'interrupts' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`intr/s`) `intr/s` FROM SAR_interrupts $where $group_by;",
                        'fields'    => array('intr/s'),
                        'title'     => "CPU Interrupts ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Interrupts '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'memory_util' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time,  $aggr(kbmemfree)*1024 kbmemfree, $aggr(kbmemused)*1024 kbmemused
                        FROM SAR_memory_util $where $group_by;",
                        'fields'    => array('kbmemfree', 'kbmemused'),
                        'title'     => "Memory Utilization ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Memory Utilization'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => true,
                        'negative'  => false,
                    ),
                    'memory_util_det' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time,  $aggr(kbbuffers)*1024 kbbuffers,  $aggr(kbcommit)*1024 kbcommit, $aggr(kbcached)*1024 kbcached,
                        $aggr(kbactive)*1024 kbactive, $aggr(kbinact)*1024 kbinact
                        FROM SAR_memory_util $where $group_by;",
                        'fields'    => array('kbcached', 'kbbuffers', 'kbinact', 'kbcommit',  'kbactive'), //
                        'title'     => "Memory Utilization Details ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Memory Utilization Details'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => true,
                        'negative'  => false,
                    ),
                    //            'memory_util3' => array(
                    //                'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`%memused`) `%memused`, $aggr(`%commit`) `%commit` FROM SAR_memory_util $where $group_by;",
                    //                'fields'    => array('%memused', '%commit',),
                    //                'title'     => "Memory Utilization % ($aggr_text, $hosts) $exec_title ",
                    //                'percentage'=> true,
                    //                'stacked'   => false,
                    //                'negative'  => false,
                    //            ),
                    'memory' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`frmpg/s`) `frmpg/s`, $aggr(`bufpg/s`) `bufpg/s`, $aggr(`campg/s`) `campg/s`
                    FROM SAR_memory $where $group_by;",
                        'fields'    => array('frmpg/s','bufpg/s','campg/s'),
                        'title'     => "Memory Stats ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Memory Stats'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false, //este tiene valores negativos...
                    ),
                    'io_pagging_disk' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`pgpgin/s`)*1024 `pgpgin/s`, $aggr(`pgpgout/s`)*1024 `pgpgout/s`
                                    FROM SAR_io_paging $where $group_by;",
                        'fields'    => array('pgpgin/s', 'pgpgout/s'),
                        'title'     => "I/O Paging IN/OUT to disk ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'I/O Paging IN/OUT to disk'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'io_pagging' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`fault/s`) `fault/s`, $aggr(`majflt/s`) `majflt/s`, $aggr(`pgfree/s`) `pgfree/s`,
                                $aggr(`pgscank/s`) `pgscank/s`, $aggr(`pgscand/s`) `pgscand/s`, $aggr(`pgsteal/s`) `pgsteal/s`
                                    FROM SAR_io_paging $where $group_by;",
                        'fields'    => array('fault/s', 'majflt/s', 'pgfree/s', 'pgscank/s', 'pgscand/s', 'pgsteal/s'),
                        'title'     => "I/O Paging ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'I/O Paging'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'io_pagging_vmeff' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`%vmeff`) `%vmeff` FROM SAR_io_paging $where $group_by;",
                        'fields'    => array('%vmeff'),
                        'title'     => "I/O Paging %vmeff ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'I/O Paging %vmeff'." ($aggr_text, $hosts)",
                        'percentage'=> ($aggr == 'SUM' ? '300':100),
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'io_transactions' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`tps`) `tp/s`, $aggr(`rtps`) `read tp/s`, $aggr(`wtps`) `write tp/s`
                                                        FROM SAR_io_rate $where $group_by;",
                        'fields'    => array('tp/s', 'read tp/s', 'write tp/s'),
                        'title'     => "I/O Transactions/s ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'I/O Transactions/s'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'io_bytes' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`bread/s`)/(1024) `KB_read/s`, $aggr(`bwrtn/s`)/(1024) `KB_wrtn/s`
                                            FROM SAR_io_rate $where $group_by;",
                        'fields'    => array('KB_read/s', 'KB_wrtn/s'),
                        'title'     => "KB R/W ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'KB R/W'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    // All fields
                    //            'block_devices' => array(
                    //                'metric'    => "Disk",
                    //                'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, #$aggr(`tps`) `tps`, $aggr(`rd_sec/s`) `rd_sec/s`, $aggr(`wr_sec/s`) `wr_sec/s`,
                    //                                   $aggr(`avgrq-sz`) `avgrq-sz`, $aggr(`avgqu-sz`) `avgqu-sz`, $aggr(`await`) `await`,
                    //                                   $aggr(`svctm`) `svctm`, $aggr(`%util`) `%util`
                    //                            FROM (
                    //                                select
                    //                                id_exec, host, date,
                    //                                #sum(`tps`) `tps`,
                    //                                #sum(`rd_sec/s`) `rd_sec/s`,
                    //                                #sum(`wr_sec/s`) `wr_sec/s`,
                    //                                max(`avgrq-sz`) `avgrq-sz`,
                    //                                max(`avgqu-sz`) `avgqu-sz`,
                    //                                max(`await`) `await`,
//                                max(`svctm`) `svctm`,
                    //                                max(`%util`) `%util`
                    //                                from SAR_block_devices d WHERE id_exec = '$exec'
                    //                                GROUP BY date, host
                    //                            ) t $where $group_by;",
                    //                'fields'    => array('avgrq-sz', 'avgqu-sz', 'await', 'svctm', '%util'),
                    //                'title'     => "SAR Block Devices ($aggr_text, $hosts) $exec_title ",
                    //                'percentage'=> false,
                    //                'stacked'   => false,
//                'negative'  => false,
                    //            ),
                    'block_devices_util' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`%util_SUM`) `%util_SUM`, $aggr(`%util_MAX`) `%util_MAX`
            FROM (
                select
                id_exec, host, date,
                sum(`%util`) `%util_SUM`,
                    max(`%util`) `%util_MAX`
                    from SAR_block_devices d WHERE id_exec = '$exec'
                    GROUP BY date, host
                ) t $where $group_by;",
                        'fields'    => array('%util_SUM', '%util_MAX'),
                        'title'     => "Disk Uitlization percentage (All DEVs, $aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Disk Uitlization percentage'." (All DEVs, $aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'block_devices_await' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`await_SUM`) `await_SUM`, $aggr(`await_MAX`) `await_MAX`
                    FROM (
                    select
                    id_exec, host, date,
                    sum(`await`) `await_SUM`,
                    max(`await`) `await_MAX`
                        from SAR_block_devices d WHERE id_exec = '$exec'
                        GROUP BY date, host
                            ) t $where $group_by;",
                        'fields'    => array('await_SUM', 'await_MAX'),
                        'title'     => "Disk request wait time in ms (All DEVs, $aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Disk request wait time in ms'." (All DEVs, $aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'block_devices_svctm' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`svctm_SUM`) `svctm_SUM`, $aggr(`svctm_MAX`) `svctm_MAX`
                                        FROM (
                                        select
                                        id_exec, host, date,
                                        sum(`svctm`) `svctm_SUM`,
                                            max(`svctm`) `svctm_MAX`
                                            from SAR_block_devices d WHERE id_exec = '$exec'
                                            GROUP BY date, host
                                        ) t $where $group_by;",
                        'fields'    => array('svctm_SUM', 'svctm_MAX'),
                        'title'     => "Disk service time in ms (All DEVs, $aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Disk service time in ms'." (All DEVs, $aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'block_devices_queues' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`avgrq-sz`) `avg-req-size`, $aggr(`avgqu-sz`) `avg-queue-size`
                                        FROM (
                                        select
                                        id_exec, host, date,
                                        max(`avgrq-sz`) `avgrq-sz`,
                                        max(`avgqu-sz`) `avgqu-sz`
                                        from SAR_block_devices d WHERE id_exec = '$exec'
                                        GROUP BY date, host
                                    ) t $where $group_by;",
                        'fields'    => array('avg-req-size', 'avg-queue-size'),
                        'title'     => "Disk req and queue sizes ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Disk req and queue sizes'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'vmstats_io' => array(
                        'metric'    => "Disk",
                        'query' => "SELECT time, $aggr(`bi`)/(1024) `KB_IN`, $aggr(`bo`)/(1024) `KB_OUT`
            FROM VMSTATS $where_VMSTATS $group_by_vmstats;",
                        'fields'    => array('KB_IN', 'KB_OUT'),
                        'title'     => "VMSTATS KB I/O ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'VMSTATS KB I/O'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'vmstats_rb' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time, $aggr(`r`) `runnable procs`, $aggr(`b`) `sleep procs` FROM VMSTATS $where_VMSTATS $group_by_vmstats;",
                        'fields'    => array('runnable procs', 'sleep procs'),
                        'title'     => "VMSTATS Processes (r-b) ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'VMSTATS Processes (r-b)'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'vmstats_memory' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time,  $aggr(`buff`) `buff`,
                    $aggr(`cache`) `cache`,
                        $aggr(`free`) `free`,
                        $aggr(`swpd`) `swpd`
                        FROM VMSTATS $where_VMSTATS $group_by_vmstats;",
                        'fields'    => array('buff', 'cache', 'free', 'swpd'),
                        'title'     => "VMSTATS Processes (r-b) ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'VMSTATS Processes (r-b)'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => true,
                        'negative'  => false,
                    ),
                    'net_devices_kbs' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(if(IFACE != 'lo', `rxkB/s`, NULL))/1024 `rxMB/s_NET`, $aggr(if(IFACE != 'lo', `txkB/s`, NULL))/1024 `txMB/s_NET`
                        FROM SAR_net_devices $where AND IFACE not IN ('') $group_by;",
                        'fields'    => array('rxMB/s_NET', 'txMB/s_NET'),
                        'title'     => "MB/s received and transmitted ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'MB/s received and transmitted'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'net_devices_kbs_local' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(if(IFACE =  'lo', `rxkB/s`, NULL))/1024 `rxMB/s_LOCAL`, $aggr(if(IFACE = 'lo', `txkB/s`, NULL))/1024 `txMB/s_LOCAL`
                        FROM SAR_net_devices $where AND IFACE not IN ('') $group_by;",
                        'fields'    => array('rxMB/s_LOCAL', 'txMB/s_LOCAL'),
                        'title'     => "MB/s received and transmitted LOCAL ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'MB/s received and transmitted LOCAL'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'net_devices_pcks' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(if(IFACE != 'lo', `rxpck/s`, NULL))/1024 `rxpck/s_NET`, $aggr(if(IFACE != 'lo', `txkB/s`, NULL))/1024 `txpck/s_NET`
                                            FROM SAR_net_devices $where AND IFACE not IN ('') $group_by;",
                        'fields'    => array('rxpck/s_NET', 'txpck/s_NET'),
                        'title'     => "Packets/s received and transmitted ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Packets/s received and transmitted'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'net_devices_pcks_local' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(if(IFACE =  'lo', `rxkB/s`, NULL))/1024 `rxpck/s_LOCAL`, $aggr(if(IFACE = 'lo', `txkB/s`, NULL))/1024 `txpck/s_LOCAL`
                                            FROM SAR_net_devices $where AND IFACE not IN ('') $group_by;",
                        'fields'    => array('rxpck/s_LOCAL', 'txpck/s_LOCAL'),
                        'title'     => "Packets/s received and transmitted LOCAL ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Packets/s received and transmitted LOCAL'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'net_sockets_pcks' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`totsck`) `totsck`,
                                                $aggr(`tcpsck`) `tcpsck`,
                                                    $aggr(`udpsck`) `udpsck`,
                                                    $aggr(`rawsck`) `rawsck`,
                                                    $aggr(`ip-frag`) `ip-frag`,
                                                    $aggr(`tcp-tw`) `tcp-time-wait`
                                                    FROM SAR_net_sockets $where $group_by;",
                        'fields'    => array('totsck', 'tcpsck', 'udpsck', 'rawsck', 'ip-frag', 'tcp-time-wait'),
                        'title'     => "Packets/s received and transmitted ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Packets/s received and transmitted'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'net_erros' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`rxerr/s`) `rxerr/s`,
                                                            $aggr(`txerr/s`) `txerr/s`,
                                                            $aggr(`coll/s`) `coll/s`,
                                                            $aggr(`rxdrop/s`) `rxdrop/s`,
                                                                $aggr(`txdrop/s`) `txdrop/s`,
                                                            $aggr(`txcarr/s`) `txcarr/s`,
                                                                $aggr(`rxfram/s`) `rxfram/s`,
                                                                $aggr(`rxfifo/s`) `rxfifo/s`,
                                                                $aggr(`txfifo/s`) `txfifo/s`
                                                                FROM SAR_net_errors $where $group_by;",
                        'fields'    => array('rxerr/s', 'txerr/s', 'coll/s', 'rxdrop/s', 'txdrop/s', 'txcarr/s', 'rxfram/s', 'rxfifo/s', 'txfifo/s'),
                        'title'     => "Network errors ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Network errors'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'bwm_in_out_total' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(FROM_UNIXTIME(unix_timestamp),'{$exec_details[$exec]['start_time']}')) time,
                                                                            $aggr(`bytes_in`)/(1024*1024) `MB_in`,
                                                                                $aggr(`bytes_out`)/(1024*1024) `MB_out`
                                                                                FROM BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
                        'fields'    => array('MB_in', 'MB_out'),
                        'title'     => "BW Monitor NG Total Bytes IN/OUT ($aggr_text, $hosts) $exec_title",
                        'group_title' => 'BW Monitor NG Total Bytes IN/OUT'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'bwm_packets_total' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(FROM_UNIXTIME(unix_timestamp),'{$exec_details[$exec]['start_time']}')) time,
                                                                                        $aggr(`packets_in`) `packets_in`,
                                                                                        $aggr(`packets_out`) `packets_out`
                                                                                            FROM BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
                        'fields'    => array('packets_in', 'packets_out'),
                        'title'     => "BW Monitor NG Total packets IN/OUT ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'BW Monitor NG Total packets IN/OUT'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'bwm_errors_total' => array(
                        'metric'    => "Network",
                        'query' => "SELECT time_to_sec(timediff(FROM_UNIXTIME(unix_timestamp),'{$exec_details[$exec]['start_time']}')) time,
                                            $aggr(`errors_in`) `errors_in`,
                                            $aggr(`errors_out`) `errors_out`
                                            FROM BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
                        'fields'    => array('errors_in', 'errors_out'),
                        'title'     => "BW Monitor NG Total errors IN/OUT ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'BW Monitor NG Total errors IN/OUT'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                );

                $has_records = false; //of any chart
                foreach ($charts[$exec] as $key_type=>$chart) {
                    if ($chart['metric'] == 'ALL' || $metric == $chart['metric']) {
                        $charts[$exec][$key_type]['chart'] = new HighCharts();
                        $charts[$exec][$key_type]['chart']->setTitle($chart['title']);
                        $charts[$exec][$key_type]['chart']->setPercentage($chart['percentage']);
                        $charts[$exec][$key_type]['chart']->setStacked($chart['stacked']);
                        $charts[$exec][$key_type]['chart']->setFields($chart['fields']);
                        $charts[$exec][$key_type]['chart']->setNegativeValues($chart['negative']);

                        list($rows, $max, $min) = Utils::minimize_exec_rows($dbUtil->get_rows($chart['query']), $chart['stacked']);

                        if (!isset($chart_details[$key_type]['max']) || $max > $chart_details[$key_type]['max'])
                            $chart_details[$key_type]['max'] = $max;
                        if (!isset($chart_details[$key_type]['min']) || $min < $chart_details[$key_type]['min'])
                            $chart_details[$key_type]['min'] = $min;

                        //$charts[$exec][$key_type]['chart']->setMax($max);
                        //$charts[$exec][$key_type]['chart']->setMin($min);

                        if (count($rows) > 0) {
                            $has_records = true;
                            $charts[$exec][$key_type]['chart']->setRows($rows);
                        }
                    }
                }
            }

            if ($exec_details) {
                $max_time = null;
                foreach ($exec_details as $exec=>$exe_time) {
                    if (!$max_time || $exe_time['time'] > $max_time) $max_time = $exe_time['time'];
                }
                foreach ($exec_details as $exec=>$exe_time) {
                    #if (!$max_time) throw new Exception('Missing MAX time');
                    $exec_details[$exec]['size'] = round((($exe_time['time']/$max_time)*100), 2);
                    //TODO improve
                    $exec_details[$exec]['max_time'] = $max_time;
                }
            }

            if (isset($has_records)) {

            } else {
                throw new \Exception("No results for query!");
            }

        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        $chartsJS = '';
        if ($charts) {
            reset($charts);
            $current_chart = current($charts);

            foreach ($current_chart as $chart_type=>$chart) {
                foreach ($execs as $exec) {
                    if (isset($charts[$exec][$chart_type]['chart'])) {
                        //make Y axis all the same when comparing
                        $charts[$exec][$chart_type]['chart']->setMax($chart_details[$chart_type]['max']);
                        //the same for max X (plus 10%)
                        $charts[$exec][$chart_type]['chart']->setMaxX(($exec_details[$exec]['max_time']*1.007));
                        //print the JS
                        $chartsJS .= $charts[$exec][$chart_type]['chart']->getChartJS()."\n\n";
                    }
                }
            }
        }

        if(!isset($exec))
            $exec = '';

        return $this->render('perfcharts/perfcharts.html.twig',
            array('selected' => 'Performance charts',
                'show_in_result' => count(self::$show_in_result),
                'title' => 'Hadoop Job/s Execution details and System Performance Charts',
                'chartsJS' => $chartsJS,
                'charts' => $charts,
                'metric' => $metric,
                'execs' => $execs,
                'aggr' => $aggr,
                'hosts' => $hosts,
                'host_rows' => $dbUtil->get_hosts($clusters),
                'detail' => $detail,
            ));
    }

    public function countersAction()
    {
        try {
            $db = $this->container->getDBUtils();
            $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
            $whereClause = $this->filters->getWhereClause();

            $benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs e JOIN JOB_details USING (id_exec) WHERE valid = 1");

            $discreteOptions = array();
            $discreteOptions['bench'][] = 'All';
            foreach($benchOptions as $option) {
                $discreteOptions['bench'][] = array_shift($option);
            }

            $message = null;

            //check the URL
            $execs = Utils::get_GET_execs();

            if (Utils::get_GET_string('type')) {
                $type = Utils::get_GET_string('type');
            } else {
                $type = 'SUMMARY';
            }

            $join = "JOIN execs e using (id_exec) JOIN clusters USING (id_cluster) WHERE JOBNAME NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links') $whereClause".
                ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':'');
            if(isset($_GET['jobid'])) {
                $join.= " AND JOBID = '${_GET['jobid']}' ";
            }
            $join .= " LIMIT 10000";

            if ($type == 'SUMMARY') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES, c.JOBNAME as CHARTS
                FROM JOB_details c $join";
            } elseif ($type == 'MAP') {
                $query = "SELECT e.bench, exe_time, c.id_exec, JOBID, JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, `Launched map tasks`,
                `Data-local map tasks`,
                `Rack-local map tasks`,
                `Spilled Records`,
                `Map input records`,
                `Map output records`,
                `Map input bytes`,
                `Map output bytes`,
                `Map output materialized bytes`
                FROM JOB_details c $join";
            } elseif ($type == 'REDUCE') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_REDUCES, c.FAILED_REDUCES,
                `Launched reduce tasks`,
                `Reduce input groups`,
                `Reduce input records`,
                `Reduce output records`,
                `Reduce shuffle bytes`,
                `Combine input records`,
                `Combine output records`
                FROM JOB_details c $join";
            } elseif ($type == 'FILE-IO') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME,
                `SLOTS_MILLIS_MAPS`,
                `SLOTS_MILLIS_REDUCES`,
                `SPLIT_RAW_BYTES`,
                `FILE_BYTES_WRITTEN`,
                `FILE_BYTES_READ`,
                `HDFS_BYTES_WRITTEN`,
                `HDFS_BYTES_READ`,
                `Bytes Read`,
                `Bytes Written`
                FROM JOB_details c $join";
            } elseif ($type == 'DETAIL') {
                $query = "SELECT e.bench, exe_time, c.* FROM JOB_details c $join";
            } elseif ($type == 'TASKS') {
                $query = "SELECT e.bench, exe_time, j.JOBNAME, c.* FROM JOB_tasks c
                JOIN JOB_details j USING(id_exec, JOBID) $join ";
                #$taskStatusOptions = $db->get_rows("SELECT DISTINCT TASK_STATUS FROM JOB_tasks JOIN execs USING (id_exec) WHERE valid = 1");
                #TODO cache this result into a temp table
//                $taskStatusOptions = $db->get_rows("select distinct(TASK_TYPE) from (SELECT TASK_TYPE FROM JOB_tasks limit 10000) t");
//                $typeOptions = $db->get_rows("SELECT DISTINCT TASK_TYPE FROM JOB_tasks JOIN execs USING (id_exec) WHERE valid = 1 LIMIT 5000;");

//                $discreteOptions['TASK_STATUS'][] = 'All';
//                $discreteOptions['TASK_TYPE'][] = 'All';
//                foreach($taskStatusOptions as $option) {
//                    $discreteOptions['TASK_STATUS'][] = array_shift($option);
//                }
//                foreach($typeOptions as $option) {
//                    $discreteOptions['TASK_TYPE'][] = array_shift($option);
//                }
                $discreteOptions['TASK_STATUS'] = array('All','SUCCESS');
                $discreteOptions['TASK_TYPE'] = array('All','MAP','REDUCE','SETUP','CLEANUP');
            } else {
                throw new \Exception('Unknown type!');
            }

            $exec_rows = $db->get_rows($query);

            if (count($exec_rows) > 0) {

                $show_in_result_counters = array(
                    'id_exec'   => 'ID',
                    //'job_name'  => 'Job Name',
                    //'exe_time' => 'Total Time',

                    'JOBID'     => 'JOBID',
                    'bench'     => 'Bench',
                    'JOBNAME'   => 'JOBNAME',
                );

                $show_in_result_counters = Utils::generate_show($show_in_result_counters, $exec_rows, 4);
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        return $this->render('counters/counters.html.twig',
            array(
                'theaders' => $show_in_result_counters,
                'message' => $message,
                'title' => 'Hadoop Jobs and Tasks Execution Counters',
                'type' => $type,
                'execs' => $execs,
                'execsParam' => (isset($_GET['execs'])) ? $_GET['execs'] : '',
                'discreteOptions' => $discreteOptions,
            ));
    }

    public function performanceMetricsAction()
    {
        $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
        $whereClause = $this->filters->getWhereClause();

        $show_in_result_metrics = array();
        $type = Utils::get_GET_string('pageTab');
        if(!$type || $type == 'CPU') {
            $show_in_result_metrics = array('Conf','bench' => 'Benchmark', 'net' => 'Net', 'disk' => 'Disk','maps' => 'Maps','comp' => 'Comp','Rep','blk_size' => 'Blk size',
                'Avg %user', 'Max %user', 'Min %user', 'Stddev %user', 'Var %user',
                'Avg %nice', 'Max %nice', 'Min %nice', 'Stddev %nice', 'Var %nice',
                'Avg %system', 'Max %system', 'Min %system', 'Stddev %system', 'Var %system',
                'Avg %iowait', 'Max %iowait', 'Min %iowait', 'Stddev %iowait', 'Var %iowait',
                'Avg %steal', 'Max %steal', 'Min %steal', 'Stddev %steal', 'Var %steal',
                'Avg %idle', 'Max %idle', 'Min %idle', 'Stddev %idle', 'Var %idle', 'Cluster', 'end_time' => 'End time');
        } else if($type == 'DISK') {
            $show_in_result_metrics = array('Conf','bench' => 'Benchmark', 'net' => 'Net', 'disk' => 'Disk','maps' => 'Maps','comp' => 'Comp','Rep','blk_size' => 'Blk size',
                'DEV', 'Avg tps', 'Max tps', 'Min tps',
                'Avg rd_sec/s', 'Max rd_sec/s', 'Min rd_sec/s', 'Stddev rd_sec/s', 'Var rd_sec/s', 'Sum rd_sec/s',
                'Avg wr_sec/s', 'Max wr_sec/s', 'Min wr_sec/s', 'Stddev wr_sec/s', 'Var wr_sec/s', 'Sum wr_sec/s',
                'Avg rq-sz', 'Max rq-sz', 'Min rq-sz', 'Stddev rq-sz', 'Var rq-sz',
                'Avg queue sz', 'Max queue sz', 'Min queue sz', 'Stddev queue sz', 'Var queue sz',
                'Avg Await', 'Max Await', 'Min Await', 'Stddev Await', 'Var Await',
                'Avg %util', 'Max %util', 'Min %util', 'Stddev %util', 'Var %util',
                'Avg svctm', 'Max svctm', 'Min svctm', 'Stddev svctm', 'Var svctm', 'Cluster', 'end_time' => 'End time');
        } else if($type == 'MEMORY') {
            $show_in_result_metrics = array('Conf','bench' => 'Benchmark', 'net' => 'Net', 'disk' => 'Disk','maps' => 'Maps','comp' => 'Comp','Rep','blk_size' => 'Blk size',
                'Avg kbmemfree', 'Max kbmemfree', 'Min kbmemfree', 'Stddev kbmemfree', 'Var kbmemfree',
                'Avg kbmemused', 'Max kbmemused', 'Min kbmemused', 'Stddev kbmemused', 'Var kbmemused',
                'Avg %memused', 'Max %memused', 'Min %memused', 'Stddev %memused', 'Var %memused',
                'Avg kbbuffers', 'Max kbbuffers', 'Min kbbuffers', 'Stddev kbbuffers', 'Var kbbuffers',
                'Avg kbcached', 'Max kbcached', 'Min kbcached', 'Stddev kbcached', 'Var kbcached',
                'Avg kbcommit', 'Max kbcommit', 'Min kbcommit', 'Stddev kbcommit', 'Var kbcommit',
                'Avg %commit', 'Max %commit', 'Min %commit', 'Stddev %commit', 'Var %commit',
                'Avg kbactive', 'Max kbactive', 'Min kbactive', 'Stddev kbactive', 'Var kbactive',
                'Avg kbinact', 'Max kbinact', 'Min kbinact', 'Stddev kbinact', 'Var kbinact', 'Cluster', 'end_time' => 'End time');
        } else if($type == 'NETWORK')
            $show_in_result_metrics = array('Conf','bench' => 'Benchmark', 'net' => 'Net', 'disk' => 'Disk','maps' => 'Maps','comp' => 'Comp','Rep','blk_size' => 'Blk size', 'Interface',
                'Avg rxpck/s', 'Max rxpck/s', 'Min rxpck/s', 'Stddev rxpck/s', 'Var rxpck/s', 'Sum rxpck/s',
                'Avg txpck/s', 'Max txpck/s', 'Min txpck/s', 'Stddev txpck/s', 'Var txpck/s', 'Sum txpck/s',
                'Avg rxkB/s', 'Max rxkB/s', 'Min rxkB/s', 'Stddev rxkB/s', 'Var rxkB/s', 'Sum rxkB/s',
                'Avg txkB/s', 'Max txkB/s', 'Min txkB/s', 'Stddev txkB/s', 'Var txkB/s', 'Sum txkB/s',
                'Avg rxcmp/s', 'Max rxcmp/s', 'Min rxcmp/s', 'Stddev rxcmp/s', 'Var rxcmp/s', 'Sum rxcmp/s',
                'Avg txcmp/s', 'Max txcmp/s', 'Min txcmp/s', 'Stddev txcmp/s', 'Var txcmp/s', 'Sum txcmp/s',
                'Avg rxmcst/s', 'Max rxmcst/s', 'Min rxmcst/s', 'Stddev rxmcst/s', 'Var rxmcst/s', 'Sum rxmcst/s', 'Cluster', 'end_time' => 'End time');

        $discreteOptions = Utils::getExecsOptions($this->container->getDBUtils(), $whereClause);
        return $this->render('metrics/metrics.html.twig',
            array(
                'theaders' => $show_in_result_metrics,
                'title' => 'Hadoop Performance Counters',
                'type' => $type ? $type : 'CPU',
                'discreteOptions' => $discreteOptions
            ));
    }

    public function histogramAction()
    {
        $db = $this->container->getDBUtils();
        $idExec = '';
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec)
                throw new \Exception("No execution selected!");
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        echo $this->container->getTwig()->render('histogram/histogram.html.twig',
            array('selected' => 'Histogram',
                'idExec' => $idExec
            ));
    }

    public function histogramHDIAction()
    {
        $db = $this->container->getDBUtils();
        $idExec = '';
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec)
                throw new \Exception("No execution selected!");
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        echo $this->container->getTwig()->render('histogram/histogramhdi.html.twig',
            array('selected' => 'Histogram',
                'idExec' => $idExec
            ));
    }

    public function bestConfigAction() {
        $db = $this->container->getDBUtils ();
        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne'))
        );

        $bestexec = '';
        $cluster = '';
        try {
            $whereClause = $this->filters->getWhereClause();

            $order_type = Utils::get_GET_string ( 'ordertype' );
            if (! $order_type)
                $order_type = 'exe_time';

            $filterExecs = DBUtils::getFilterExecs();

            // get the result rows
            $query = "SELECT (e.exe_time/3600)*c.cost_hour as cost, e.id_exec,e.exec,e.bench,e.exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version, c.*
    		from execs e
    		join clusters c USING (id_cluster)
    		WHERE 1 $filterExecs $whereClause
    		GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
    		ORDER BY $order_type ASC;";

            $this->getContainer ()->getLog ()->addInfo ( 'BestConfig query: ' . $query );
            $rows = $db->get_rows ( $query );

            if (! $rows) {
                throw new \Exception ( "No results for query!" );
            }
            
            $minCost = -1;
            $minCostIdx = 0;
            
            if ($rows) {
            	$bestexec = $rows[0];
            	if($order_type == 'cost') {
	            	foreach($rows as $key => &$exec) {
	            		$cost = Utils::getExecutionCost($exec,$exec['cost_hour'],$exec['cost_remote'],$exec['cost_SSD'],$exec['cost_IB']);
                        if(($cost < $minCost) || $minCost == -1) {
	            			$minCost = $cost;
	            			$minCostIdx = $key;
	            		}
	            	}
	            	$bestexec = $rows[$minCostIdx];
            	}

                $cluster=$bestexec['name'];
                Utils::makeExecInfoBeauty($bestexec);
            }
        } catch ( \Exception $e ) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        return $this->render ( 'bestconfig/bestconfig.html.twig', array (
            'title' => 'Best Run Configuration',
            'select_multiple_benchs' => false,
            'bestexec' => $bestexec,
            'cluster' => $cluster,
            'order_type' => $order_type
        ));
    }

    public function paramEvaluationAction() {
        $db = $this->container->getDBUtils ();
        $this->buildFilters();
        $whereClause = $this->filters->getWhereClause();

        $categories = '';
        $series = '';
        try {
           /* if(!(isset($_GET['benchs']))) {
                $_GET['benchs'] = array('wordcount', 'terasort', 'sort');
            }*/

            $paramEval = (isset($_GET['parameval']) && $_GET['parameval'] != '') ? $_GET['parameval'] : 'maps';
            $minExecs = (isset($_GET['minexecs'])) ? $_GET['minexecs'] : -1;
            $minExecsFilter = "";
            if($minExecs > 0)
                $minExecsFilter = "HAVING COUNT(*) > $minExecs";

            $filter_execs = DBUtils::getFilterExecs();

            $paramOptions = array();
            foreach($options[$paramEval] as $option) {
                if($paramEval == 'id_cluster')
                    $paramOptions[] = $option['name'];
                else if($paramEval == 'comp')
                    $paramOptions[] = Utils::getCompressionName($option[$paramEval]);
                else if($paramEval == 'net')
                    $paramOptions[] = Utils::getNetworkName($option[$paramEval]);
                else if($paramEval == 'disk')
                    $paramOptions[] = Utils::getDisksName($option[$paramEval]);
                else if($paramEval == 'vm_ram')
                    $paramOptions[] = Utils::getBeautyRam($option['vm_RAM']);
                else
                    $paramOptions[] = $option[$paramEval];
            }

            $benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause GROUP BY $paramEval, bench order by $paramEval");

            // get the result rows
            $query = "SELECT count(*) as count, $paramEval, e.id_exec, exec as conf, bench, ".
                "exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
                "from execs e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause".
                "GROUP BY $paramEval, bench $minExecsFilter order by bench,$paramEval";

            $rows = $db->get_rows ( $query );

            if (!$rows) {
                throw new \Exception ( "No results for query!" );
            }

            $categories = '';
            $arrayBenchs = array();
            foreach ( $paramOptions as $param ) {
                $categories .= "'$param".Utils::getParamevalUnit($paramEval)."',";
                foreach($benchOptions as $bench) {
                    $arrayBenchs[$bench['bench']][$param] = null;
                }
            }

            $series = array();
            foreach($rows as $row) {
                if($paramEval == 'comp')
                    $row[$paramEval] = Utils::getCompressionName($row['comp']);
                else if($paramEval == 'id_cluster') {
                    $row[$paramEval] = Utils::getClusterName($row[$paramEval],$db);
                } else if($paramEval == 'net')
                    $row[$paramEval] = Utils::getNetworkName($row['net']);
                else if($paramEval == 'disk')
                    $row[$paramEval] = Utils::getDisksName($row['disk']);
                else if($paramEval == 'vm_ram')
                    $row[$paramEval] = Utils::getBeautyRam($row['vm_ram']);

                $arrayBenchs[strtolower($row['bench'])][$row[$paramEval]]['y'] = round((int)$row['avg_exe_time'],2);
                $arrayBenchs[strtolower($row['bench'])][$row[$paramEval]]['count'] = (int)$row['count'];
            }

            foreach($arrayBenchs as $key => $arrayBench)
            {
                $series[] = array('name' => $key, 'data' => array_values($arrayBench));
            }
            $series = json_encode($series);
        } catch ( \Exception $e ) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        return $this->render ('parameval/parameval.html.twig', array (
            'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
            'categories' => $categories,
            'series' => $series,
            'paramEval' => $paramEval
        ) );
    }

    public function publicationsAction()
    {
        echo $this->container->getTwig()->render('publications/publications.html.twig', array(
            'selected' => 'Publications',
            'title' => 'ALOJA Publications and Slides'));
    }

    public function teamAction()
    {
        echo $this->container->getTwig()->render('team/team.html.twig', array(
            'selected' => 'Team',
            'title' => 'ALOJA Team & Collaborators'));
    }

    public function clustersAction()
    {
        $clusterNameSelected = null;

        if(isset($_GET['cluster_name'])) {
            $clusterNameSelected = $_GET['cluster_name'];
        }

        $filter_execs = DBUtils::getFilterExecs();

        $db = $this->container->getDBUtils();
        $clusters = $db->get_rows("SELECT * FROM clusters c WHERE id_cluster IN (SELECT distinct(id_cluster) FROM execs e WHERE 1 $filter_execs);");

        echo $this->container->getTwig()->render('clusters/clusters.html.twig', array(
            'selected' => 'Clusters',
            'clusters' => $clusters,
            'clusterNameSelected' => $clusterNameSelected,
            'title' => 'ALOJA Clusters'));
    }

    public function clusterCostsAction()
    {
        echo $this->container->getTwig()->render('clusters/clustercosts.html.twig', array(
            'selected' => 'Clusters Costs',
            'title' => 'ALOJA Clusters Costs'));
    }

    public function dbscanAction()
    {
        $jobid = Utils::get_GET_string("jobid");

        // if no job requested, show a random one
        if (strlen($jobid) == 0 || $jobid === "random") {
            $_GET['NO_CACHE'] = 1;  // Disable cache, otherwise random will not work
            $db = $this->container->getDBUtils();
            $query = '
                SELECT DISTINCT(t.JOBID)
                FROM JOB_tasks t
                #ORDER BY t.JOBID DESC
                LIMIT 100
            ;';
            $jobid = $db->get_rows($query)[rand(0,count($jobid))]['JOBID'];
        }

        echo $this->container->getTwig()->render('dbscan/dbscan.html.twig',
            array(
                'selected' => 'DBSCAN',
                'highcharts_js' => HighCharts::getHeader(),
                'jobid' => $jobid,
                'METRICS' => DBUtils::$TASK_METRICS,
            )
        );
    }

    public function dbscanexecsAction()
    {
        $dbUtils = $this->container->getDBUtils();
        $this->buildFilters();
        $whereClause = $this->filters->getWhereClause(array('execs' => 'e', 'clusters' => 'c'));

        $jobid = Utils::get_GET_string("jobid");

        // if no job requested, show a random one
        if (strlen($jobid) == 0 || $jobid === "random") {
            $_GET['NO_CACHE'] = 1;  // Disable cache, otherwise random will not work
            $db = $this->container->getDBUtils();
            $query = "
                SELECT DISTINCT(t.JOBID)
                FROM JOB_tasks t JOIN execs e USING (id_exec)
                JOIN clusters c USING (id_cluster) WHERE 1=1 $whereClause
                LIMIT 100
            ;";
            $jobid = $db->get_rows($query)[rand(0,99)]['JOBID'];
        }

        list($bench, $job_offset, $id_exec) = $this->container->getDBUtils()->get_jobid_info($jobid);

        echo $this->render('dbscanexecs/dbscanexecs.html.twig',
            array(
                'highcharts_js' => HighCharts::getHeader(),
                'jobid' => $jobid,
                'bench' => $bench,
                'job_offset' => $job_offset,
                'METRICS' => DBUtils::$TASK_METRICS,
                'select_multiple_benchs' => false,
            )
        );
    }

    public function hdp2CountersAction()
    {
        try {
            $db = $this->container->getDBUtils();
            $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
            $whereClause = $this->filters->getWhereClause();

            $benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs e JOIN HDI_JOB_details USING (id_exec) WHERE valid = 1");

            $discreteOptions = array();
            $discreteOptions['bench'][] = 'All';
            foreach($benchOptions as $option) {
                $discreteOptions['bench'][] = array_shift($option);
            }

            $dbUtil = $this->container->getDBUtils();
            $message = null;

            //check the URL
            $execs = Utils::get_GET_execs();

            if (Utils::get_GET_string('type')) {
                $type = Utils::get_GET_string('type');
            } else {
                $type = 'SUMMARY';
            }

            $join = "JOIN execs e using (id_exec) JOIN clusters USING (id_cluster) WHERE job_name NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links') $whereClause".
                ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':'');
            if(isset($_GET['jobid'])) {
                $join.= " AND JOB_ID = '${_GET['jobid']}' ";
            }
            $join .= " LIMIT 10000";

            $query = "";
            if ($type == 'SUMMARY') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES, c.job_name as CHARTS
    			FROM HDI_JOB_details c $join";
            } else if ($type == "MAP") {
                $query = "SELECT e.bench, exe_time, c.id_exec, JOB_ID, job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, `TOTAL_LAUNCHED_MAPS`,
    			`RACK_LOCAL_MAPS`,
    			`SPILLED_RECORDS`,
    			`MAP_INPUT_RECORDS`,
    			`MAP_OUTPUT_RECORDS`,
    			`MAP_OUTPUT_BYTES`,
    			`MAP_OUTPUT_MATERIALIZED_BYTES`
    			FROM HDI_JOB_details c $join";
            } else if ($type == 'REDUCE') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_REDUCES, c.FAILED_REDUCES,
    			`TOTAL_LAUNCHED_REDUCES`,
    			`REDUCE_INPUT_GROUPS`,
    			`REDUCE_INPUT_RECORDS`,
    			`REDUCE_OUTPUT_RECORDS`,
    			`REDUCE_SHUFFLE_BYTES`,
    			`COMBINE_INPUT_RECORDS`,
    			`COMBINE_OUTPUT_RECORDS`
    			FROM HDI_JOB_details c $join";
            } else if ($type == 'FILE-IO') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME,
    			`SLOTS_MILLIS_MAPS`,
    			`SLOTS_MILLIS_REDUCES`,
    			`SPLIT_RAW_BYTES`,
    			`FILE_BYTES_WRITTEN`,
    			`FILE_BYTES_READ`,
    			`WASB_BYTES_WRITTEN`,
    			`WASB_BYTES_READ`,
    			`BYTES_READ`,
    			`BYTES_WRITTEN`
    			FROM HDI_JOB_details c $join";
            } else if ($type == 'DETAIL') {
                $query = "SELECT e.bench, exe_time, c.* FROM HDI_JOB_details c $join";
            } else if ($type == "TASKS") {
                $query = "SELECT e.bench, exe_time, j.job_name, c.* FROM HDI_JOB_tasks c
    			JOIN HDI_JOB_details j USING(id_exec,JOB_ID) $join ";

//                $taskStatusOptions = $db->get_rows("SELECT DISTINCT TASK_STATUS FROM HDI_JOB_tasks JOIN execs USING (id_exec) WHERE valid = 1");
//                $typeOptions = $db->get_rows("SELECT DISTINCT TASK_TYPE FROM HDI_JOB_tasks JOIN execs USING (id_exec) WHERE valid = 1");
//
//                $discreteOptions['TASK_STATUS'][] = 'All';
//                $discreteOptions['TASK_TYPE'][] = 'All';
//                foreach($taskStatusOptions as $option) {
//                    $discreteOptions['TASK_STATUS'][] = array_shift($option);
//                }
//                foreach($typeOptions as $option) {
//                    $discreteOptions['TASK_TYPE'][] = array_shift($option);
//                }
                $discreteOptions['TASK_STATUS'] = array('All','SUCCEEDED');
                $discreteOptions['TASK_TYPE'] = array('All','MAP','REDUCE');
            } else {
                throw new \Exception('Unknown type!');
            }

            $exec_rows = $dbUtil->get_rows($query);

            if (count($exec_rows) > 0) {

                $show_in_result_counters = array(
                    'id_exec'   => 'ID',
                    'JOB_ID'     => 'JOBID',
                    'bench'     => 'Bench',
                    'job_name'   => 'JOBNAME',
                );

                $show_in_result_counters = Utils::generate_show($show_in_result_counters, $exec_rows, 4);
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        return $this->render('counters/hdp2counters.html.twig',
            array(
                'theaders' => (isset($show_in_result_counters) ? $show_in_result_counters:array()),
                'message' => $message,
                'title' => 'Hadoop Jobs and Tasks Execution Counters',
                'type' => $type,
                'execs' => $execs,
                'execsParam' => (isset($_GET['execs'])) ? $_GET['execs'] : '',
                'discreteOptions' => $discreteOptions,
                'hdp2' => true,
            ));
    }

    public function clusterCostEffectivenessAction()
    {
        $db = $this->container->getDBUtils ();
        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne')));
        $whereClause = $this->filters->getWhereClause();

        $data = array();

        $filter_execs = DBUtils::getFilterExecs();

        if(isset($_GET['benchs']))
            $_GET['benchs'] = $_GET['benchs'][0];

        if (isset($_GET['benchs']) and strlen($_GET['benchs']) > 0) {
            $bench = $_GET['benchs'];
            $bench_where = " AND bench = '$bench'";
        } else {
            $bench = 'terasort';
            $bench_where = " AND bench = '$bench'";
        }

        $query = "SELECT t.scount as count, e.*, c.* from execs e JOIN clusters c USING (id_cluster)
        		INNER JOIN (SELECT count(*) as scount, MIN(exe_time) minexe FROM execs JOIN clusters USING(id_cluster)
        					 WHERE  1 $bench_where $whereClause GROUP BY name,net,disk ORDER BY name ASC)
        		t ON e.exe_time = t.minexe WHERE 1 $filter_execs $bench_where $whereClause GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC;";
        
    	try {
    		$rows = $db->get_rows($query);
    		$minCost = -1;
    		$minCostKey = 0;
    		$sumCount = 0;
    		$previousCluster = "none";
    		$bestExecs = array();
    		foreach($rows as $key => &$row) {
    			$cost = Utils::getExecutionCost($row, $row['cost_hour'], $row['cost_remote'], $row['cost_SSD'], $row['cost_IB']);
    			$row['cost_std'] = $cost;
    			if($previousCluster != "none" && $previousCluster != $row['name']) {
    				$min = $rows[$minCostKey];
    				array_push($bestExecs,$min);
    				$clusterDesc = "${min['datanodes']} datanodes,  ".round($min['vm_RAM'],0)." GB memory, ${min['vm_OS']}, ${min['provider']} ${min['type']}";
    				$set = array(round($min['exe_time'],0), round($minCost,2), $sumCount);
    				array_push($data, array('data' => array($set), 'name' => $min['name'], 'clusterdesc' => $clusterDesc, 'counts' => $sumCount));
    				$previousCluster = $row['name'];
    				$minCost = -1;
    				$sumCount = 0;
    			} else if($previousCluster == "none")
    				$previousCluster = $row['name'];
    			
    			if($minCost == -1 || $cost < $minCost) {
    				$minCost = $cost;
    				$minCostKey = $key;
    			}
    			
    			$sumCount += $row['count'];
    		}
    		$min = $rows[$minCostKey];
    		array_push($bestExecs,$min);
    		$clusterDesc = "${min['datanodes']} datanodes,  ".round($min['vm_RAM'],0)." GB memory, ${min['vm_OS']}, ${min['provider']} ${min['type']}";
    		$set = array(round($min['exe_time'],0), round($minCost,2), $sumCount);
    		array_push($data, array('data' => array($set), 'name' => $min['name'], 'clusterdesc' => $clusterDesc, 'counts' => $sumCount));
    		
    		//This is to order the cluster by cost-effectiveness (ascending)
    		//This way the labels in the cart are ordered
    		usort($data,function($a, $b) {
                $costA = $a['data'][0][1];
                $costB = $b['data'][0][1];
                //$costA = $a['data'][0][0] * $a['data'][0][1];
    			//$costB = $b['data'][0][0] * $b['data'][0][1];
    			return $costA >= $costB;
    		});
    		
    		//Sorting clusters by size
    		usort($bestExecs, function($a,$b) {
                return $a['cost_std'] > $b['cost_std'];
    			//return ($a['cost_std']*$a['exe_time']) > ($b['cost_std']*$b['exe_time']);
    		});

    	} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
    	}
    	
    	return $this->render('clustercosteffectiveness/clustercosteffectiveness.html.twig', array(
    			'series' => json_encode($data),
    			'select_multiple_benchs' => false,
                'bestExecs' => $bestExecs
    		));
    }
    
    public function costPerfClusterEvaluationAction()
    {
    	$filter_execs = DBUtils::getFilterExecs();
    	$dbUtils = $this->container->getDBUtils();

        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne')));

    	try {
    		if(isset($_GET['benchs']))
    			$_GET['benchs'] = $_GET['benchs'][0];
    
    		if (isset($_GET['benchs']) and strlen($_GET['benchs']) > 0) {
    			$bench = $_GET['benchs'];
    			$bench_where = " AND bench = '$bench'";
    		} else {
    			$bench = 'terasort';
    			$bench_where = " AND bench = '$bench'";
    		}
    
    		
    		$whereClause = $this->filters->getWhereClause();

    		/*
    		 * 1. Get execs and cluster associated costs
    		* 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
    		* 3. Calculate max and minimum costs
    		* 4. calculate max and minimum exe times
    		* 5. Normalize costs and exe times
    		* 6. Print results
    		*/
    
    		$minCost = -1;
    		$maxCost = 0;
    		$minExeTime = -1;
    		$maxExeTime = 0;
    		$sumCount = 0;
    
    		$execs = "SELECT e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,e.exec, c.name as clustername,c.* 
    		  FROM execs e JOIN clusters c USING (id_cluster)
      		  INNER JOIN (SELECT MIN(exe_time) minexe FROM execs e JOIN clusters c USING(id_cluster)
        					 WHERE  1 $filter_execs $bench_where $whereClause GROUP BY name,net,disk ORDER BY name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $bench_where $whereClause
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC;";
    
    		$execs = $dbUtils->get_rows($execs);
    		if(!$execs)
    			throw new \Exception("No results for query!");
    
    		foreach($execs as &$exec) {
    			$costHour = (isset($_GET['cost_hour'][$exec['id_cluster']])) ? $_GET['cost_hour'][$exec['id_cluster']] : $exec['cost_hour'];
    			$_GET['cost_hour'][$exec['id_cluster']] = $costHour;
    
    			$costRemote = (isset($_GET['cost_remote'][$exec['id_cluster']])) ? $_GET['cost_remote'][$exec['id_cluster']] : $exec['cost_remote'];
    			$_GET['cost_remote'][$exec['id_cluster']] = $costRemote;
    
    			$costSSD = (isset($_GET['cost_SSD'][$exec['id_cluster']])) ? $_GET['cost_SSD'][$exec['id_cluster']] : $exec['cost_SSD'];
    			$_GET['cost_SSD'][$exec['id_cluster']] = $costSSD;
    
    			$costIB = (isset($_GET['cost_IB'][$exec['id_cluster']])) ? $_GET['cost_IB'][$exec['id_cluster']] : $exec['cost_IB'];
    			$_GET['cost_IB'][$exec['id_cluster']] = $costIB;
    
    			$exec['cost_std'] = Utils::getExecutionCost($exec, $costHour, $costRemote, $costSSD, $costIB);
    
    			if($exec['cost_std'] > $maxCost)
    				$maxCost = $exec['cost_std'];
    			if($exec['cost_std'] < $minCost || $minCost == -1)
    				$minCost = $exec['cost_std'];
    
    			if($exec['exe_time']<$minExeTime || $minExeTime == -1)
    				$minExeTime = $exec['exe_time'];
    			if($exec['exe_time']>$maxExeTime)
    				$maxExeTime = $exec['exe_time'];
    		}
    	} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
    	}
    
    	//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
    	//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
    
    	$seriesData = '';
    	foreach ($execs as $exec) {
    		$exeTimeStd = 0.01;
    		$costTimeStd = 0.01;
    		if(count($execs) > 1) {
	    		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
	    		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
	    		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
	    		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
    		}
    
    		$seriesData .= "{
            name: '" . $exec['exec'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . ", ". round($costTimeStd*$exeTimeStd, 3) ."]]
        },";
    	}
    
    	$clusters = $dbUtils->get_rows("SELECT * FROM clusters c WHERE id_cluster IN (SELECT DISTINCT(id_cluster) FROM execs e WHERE 1 $filter_execs);");
    
    	//Sorting clusters by size
    	usort($execs, function($a,$b) {
    		return ($a['cost_std']) > ($b['cost_std']);
    	});
    	return $this->render('perf_by_cost/perf_by_cost_cluster.html.twig', array(
    			'selected' => 'Clusters Cost Evaluation',
    			'highcharts_js' => HighCharts::getHeader(),
    			// 'show_in_result' => count($show_in_result),
    			'cost_hour' => isset($_GET['cost_hour']) ? $_GET['cost_hour'] : null,
    			'cost_remote' => isset($_GET['cost_remote']) ? $_GET['cost_remote'] : null,
    			'cost_SSD' => isset($_GET['cost_SSD']) ? $_GET['cost_SSD'] : null,
    			'cost_IB' => isset($_GET['cost_IB']) ? $_GET['cost_IB'] : null,
    			'seriesData' => $seriesData,
    			'benchs' => array($bench),
    			'select_multiple_benchs' => false,
    			'execs' => $execs,
    			'title' => 'Normalized Cost by Performance Evaluation of Hadoop Executions',
    			'clusters' => $clusters,
    	));
    }
    
    public function BestCostPerfClusterEvaluationAction()
    {
    	$filter_execs = DBUtils::getFilterExecs();
    	$dbUtils = $this->container->getDBUtils();

        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne')));
    	try {
    		$whereClause = $this->filters->getWhereClause();

    		/*
    		 * 1. Get execs and cluster associated costs
    		* 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
    		* 3. Calculate max and minimum costs
    		* 4. calculate max and minimum exe times
    		* 5. Normalize costs and exe times
    		* 6. Print results
    		*/
    
    		$minCost = -1;
    		$maxCost = 0;
    		$minExeTime = -1;
    		$maxExeTime = 0;

    		$execs = "SELECT t.scount as count, e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,e.exec, c.name as clustername,c.* 
    		  FROM execs e JOIN clusters c USING (id_cluster)
      		  INNER JOIN (SELECT count(*) as scount, MIN(exe_time) minexe FROM execs e JOIN clusters c USING(id_cluster)
        					 WHERE  1 $filter_execs $bench_where $whereClause GROUP BY name,net,disk ORDER BY name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $bench_where $whereClause
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC;";
    
    		$execs = $dbUtils->get_rows($execs);
    		if(!$execs)
    			throw new \Exception("No results for query!");
    
    		$minCostKey = 0;
    		$tmpMinCost = -1;
    		$previousCluster = "none";
    		$bestExecs = array();
    		$sumCount = 0;
    		foreach($execs as $key => &$exec) {
    			if($previousCluster != "none" && $previousCluster != $exec['name']) {
    				$previousCluster = $exec['name'];
    				$tmpMinCost = -1;
    				
    				if($execs[$minCostKey]['cost_std'] > $maxCost)
    					$maxCost = $execs[$minCostKey]['cost_std'];
    				if($execs[$minCostKey]['cost_std'] < $minCost || $minCost == -1)
    					$minCost = $execs[$minCostKey]['cost_std'];
    				
    				if($execs[$minCostKey]['exe_time']<$minExeTime || $minExeTime == -1)
    					$minExeTime = $execs[$minCostKey]['exe_time'];
    				if($execs[$minCostKey]['exe_time']>$maxExeTime)
    					$maxExeTime = $execs[$minCostKey]['exe_time'];
    				
    				$execs[$minCostKey]['countexecs'] = $sumCount;
    				
    				array_push($bestExecs, $execs[$minCostKey]);
    				$sumCount = 0;
    			} else if($previousCluster == "none")
    				$previousCluster = $exec['name'];
    			
    			$costHour = (isset($_GET['cost_hour'][$exec['id_cluster']])) ? $_GET['cost_hour'][$exec['id_cluster']] : $exec['cost_hour'];
    			$_GET['cost_hour'][$exec['id_cluster']] = $costHour;
    
    			$costRemote = (isset($_GET['cost_remote'][$exec['id_cluster']])) ? $_GET['cost_remote'][$exec['id_cluster']] : $exec['cost_remote'];
    			$_GET['cost_remote'][$exec['id_cluster']] = $costRemote;
    
    			$costSSD = (isset($_GET['cost_SSD'][$exec['id_cluster']])) ? $_GET['cost_SSD'][$exec['id_cluster']] : $exec['cost_SSD'];
    			$_GET['cost_SSD'][$exec['id_cluster']] = $costSSD;
    
    			$costIB = (isset($_GET['cost_IB'][$exec['id_cluster']])) ? $_GET['cost_IB'][$exec['id_cluster']] : $exec['cost_IB'];
    			$_GET['cost_IB'][$exec['id_cluster']] = $costIB;
    
    			$exec['cost_std'] = Utils::getExecutionCost($exec, $costHour, $costRemote, $costSSD, $costIB);
    			
    			if($tmpMinCost == -1 || $exec['cost_std'] < $tmpMinCost) {
    				$tmpMinCost = $exec['cost_std'];
    				$minCostKey = $key;
    			}
    			
    			$sumCount += $exec['count'];
    		}    		
    		if($execs[$minCostKey]['cost_std'] > $maxCost)
    			$maxCost = $execs[$minCostKey]['cost_std'];
    		if($execs[$minCostKey]['cost_std'] < $minCost || $minCost == -1)
    			$minCost = $execs[$minCostKey]['cost_std'];
    		
    		if($execs[$minCostKey]['exe_time']<$minExeTime || $minExeTime == -1)
    			$minExeTime = $execs[$minCostKey]['exe_time'];
    		if($execs[$minCostKey]['exe_time']>$maxExeTime)
    			$maxExeTime = $execs[$minCostKey]['exe_time'];
    		
    		$execs[$minCostKey]['countexecs'] = $sumCount;
    		array_push($bestExecs, $execs[$minCostKey]);
    	} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
    	}
    
    	//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
    	//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
    
    	$seriesData = '';
    	foreach ($bestExecs as $exec) {
    		$exeTimeStd = 0.01;
    		$costTimeStd = 0.01;
    		if(count($bestExecs) > 1) {
	    		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
	    		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
	    		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
	    		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
    		}
    
    		$clusterDesc = "${exec['datanodes']} datanodes,  ".round($exec['vm_RAM'],0)." GB memory, ${exec['vm_OS']}, ${exec['provider']} ${exec['type']}";
    		$seriesData .= "{
            name: '" . $exec['name'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . ", ". $exec['countexecs'] ."]],
            clusterdesc: '$clusterDesc', countExecs: '${exec['countexecs']}'
        },";
    	}
    
    	$clusters = $dbUtils->get_rows("SELECT * FROM clusters c WHERE id_cluster IN (SELECT DISTINCT(id_cluster) FROM execs e WHERE 1 $filter_execs);");

    	//Sorting clusters by size
    	usort($bestExecs, function($a,$b) {
    		return ($a['cost_std']) > ($b['cost_std']);
    	});
    	
    	return $this->render('perf_by_cost/best_perf_by_cost_cluster.html.twig', array(
    			'highcharts_js' => HighCharts::getHeader(),
    			// 'show_in_result' => count($show_in_result),
    			'cost_hour' => isset($_GET['cost_hour']) ? $_GET['cost_hour'] : null,
    			'cost_remote' => isset($_GET['cost_remote']) ? $_GET['cost_remote'] : null,
    			'cost_SSD' => isset($_GET['cost_SSD']) ? $_GET['cost_SSD'] : null,
    			'cost_IB' => isset($_GET['cost_IB']) ? $_GET['cost_IB'] : null,
    			'seriesData' => $seriesData,
    			'select_multiple_benchs' => false,
    			'bestExecs' => $bestExecs,
    			'clusters' => $clusters,
    			// 'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
    	));
    }

    public function nodesEvaluationAction()
    {
        $dbUtils = $this->container->getDBUtils();

        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne')));
        try {
            $filter_execs = DBUtils::getFilterExecs();

            $whereClause = $this->filters->getWhereClause();

            $execs = $dbUtils->get_rows("SELECT c.datanodes,e.exec_type,c.vm_OS,c.vm_size,(e.exe_time * (c.cost_hour/3600)) as cost,e.*,c.* FROM execs e JOIN clusters c USING (id_cluster) INNER JOIN ( SELECT c2.datanodes,e2.exec_type,c2.vm_OS,c2.vm_size as vmsize,MIN(e2.exe_time) as minexe from execs e2 JOIN clusters c2 USING (id_cluster) WHERE 1 $whereClause GROUP BY c2.datanodes,e2.exec_type,c2.vm_OS,c2.vm_size ) t ON t.minexe = e.exe_time AND t.datanodes = c.datanodes AND t.vmsize = c.vm_size WHERE 1 $filter_execs  GROUP BY c.datanodes,e.exec_type,c.vm_OS,c.vm_size ORDER BY c.datanodes ASC,c.vm_OS,c.vm_size DESC;");

            $vmSizes = array();
            $categories = array();
            $dataNodes = array();
            $vmOS = array();
            $execTypes = array();
            foreach ($execs as &$exec) {
                if (!isset($dataNodes[$exec['datanodes']])) {
                    $dataNodes[$exec['datanodes']] = 1;
                    $categories[] = $exec['datanodes'];
                }
                if(!isset($vmOS[$exec['vm_OS']]))
                    $vmOS[$exec['vm_OS']] = 1;
                if(!isset($execTypes[$exec['exec_type']]))
                    $execTypes[$exec['exec_type']] = 1;

                $vmSizes[$exec['vm_size']][$exec['exec_type']][$exec['vm_OS']][$exec['datanodes']] = array(round($exec['exe_time'],2), round($exec['cost'],2));
            }

            $i = 0;
            $seriesColors = array('#7cb5ec', '#434348', '#90ed7d', '#f7a35c', '#8085e9',
                '#f15c80', '#e4d354', '#2b908f', '#f45b5b', '#91e8e1');
            $series = array();
            foreach($vmSizes as $vmSize => $value) {
                foreach($execTypes as $execType => $typevalue) {
                    foreach ($vmOS as $OS => $osvalue) {
                        if (isset($vmSizes[$vmSize][$execType][$OS])) {
                            if ($i == sizeof($seriesColors))
                                $i = 0;
                            $costSeries = array('name' => "$vmSize $execType $OS Run cost", 'type' => 'spline', 'dashStyle' => 'longdash', 'yAxis' => 0, 'data' => array(), 'tooltip' => array('valueSuffix' => ' US$'), 'color' => $seriesColors[$i]);
                            $timeSeries = array('name' => "$vmSize $execType $OS Run execution time", 'type' => 'spline', 'yAxis' => 1, 'data' => array(), 'tooltip' => array('valueSuffix' => ' s'), 'color' => $seriesColors[$i++]);
                            foreach ($dataNodes as $datanodes => $dvalue) {
                                if (!isset($value[$execType][$OS][$datanodes])) {
                                    $costSeries['data'][] = "null";
                                    $timeSeries['data'][] = "null";
                                } else {
                                    $costSeries['data'][] = $value[$execType][$OS][$datanodes][1];
                                    $timeSeries['data'][] = $value[$execType][$OS][$datanodes][0];
                                }
                            }
                            $series[] = $timeSeries;
                            $series[] = $costSeries;
                        }
                    }
                }
            }
        } catch(\Exception $e) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        return $this->render('nodeseval/nodes_evaluation.html.twig', array(
            'highcharts_js' => HighCharts::getHeader(),
            'categories' => json_encode($categories),
            'seriesData' => str_replace('"null"','null',json_encode($series)),
            'datanodess' => $datanodes,
            'select_multiple_benchs' => false,
            // 'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
        ));
    }
}
