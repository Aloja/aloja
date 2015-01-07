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
	    'histogram' => 'Histogram',
            // 'files' => 'Files',
            'prv' => 'PARAVER',
            // 'version' => 'Hadoop v.',
            'init_time' => 'End time',
        );

    public function indexAction()
    {
        echo $this->container->get('twig')->render('welcome.html.twig', array(
         'selected' => 'About'
        ));
    }

    public function configImprovementAction()
    {
        $db = $this->container->getDBUtils();
        $rows_config = '';
        try {
            $configurations = array();
            $where_configs = '';
            $concat_config = "";

            $benchs         = Utils::read_params('benchs',$where_configs,$configurations,$concat_config);
            $nets           = Utils::read_params('nets',$where_configs,$configurations,$concat_config);
            $disks          = Utils::read_params('disks',$where_configs,$configurations,$concat_config);
            $blk_sizes      = Utils::read_params('blk_sizes',$where_configs,$configurations,$concat_config);
            $comps          = Utils::read_params('comps',$where_configs,$configurations,$concat_config);
            $id_clusters    = Utils::read_params('id_clusters',$where_configs,$configurations,$concat_config);
            $mapss          = Utils::read_params('mapss',$where_configs,$configurations,$concat_config);
            $replications   = Utils::read_params('replications',$where_configs,$configurations,$concat_config);
            $iosfs          = Utils::read_params('iosfs',$where_configs,$configurations,$concat_config);
            $iofilebufs     = Utils::read_params('iofilebufs',$where_configs,$configurations,$concat_config);
			$money 			= Utils::read_params('money',$where_configs,$configurations,$concat_config);
			
            //$concat_config = join(',\'_\',', $configurations);
            //$concat_config = substr($concat_config, 1);

            //make sure there are some defaults
            if (!$concat_config) {
                $concat_config = 'disk';
                $disks = array('HDD');
            }

            $filter_execs = "AND exe_time > 200 AND (id_cluster = 1 OR (bench != 'bayes' AND id_cluster=2))";
            $order_conf = 'LENGTH(conf), conf';
            
            //get configs first (categories)
            $query = "SELECT count(*) num, concat($concat_config) conf from execs e
                      WHERE 1 $filter_execs $where_configs
                      GROUP BY conf ORDER BY $order_conf #AVG(exe_time)
                      ;";

            $rows_config = $db->get_rows($query);

            $height = 600;

            if (count($rows_config) > 4) {
                $num_configs = count($rows_config);
                $height = round($height + (10*($num_configs-4)));
            }

            //get the result rows
            $query = "SELECT #count(*),
            		  e.id_exec,
                      concat($concat_config) conf, bench,
                      avg(exe_time) AVG_exe_time,
                      #max(exe_time) MAX_exe_time,
                      min(exe_time) MIN_exe_time,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P50_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 95/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P95_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 05/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P05_exe_time`,
                      #(select CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) FROM execs WHERE bench = e.bench $filter_execs $where_configs) P50_ALL_exe_time,
                      (select AVG(exe_time) FROM execs WHERE bench = e.bench $filter_execs $where_configs) AVG_ALL_exe_time,
                      #(select MAX(exe_time) FROM execs WHERE bench = e.bench $filter_execs $where_configs) MAX_ALL_exe_time,
                      #(select MIN(exe_time) FROM execs WHERE bench = e.bench $filter_execs $where_configs) MIN_ALL_exe_time,
                      'none'
                      from execs e
                      WHERE 1  $filter_execs $where_configs
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
                if ($bench && $bench != $row['bench']) {
                    $series .= "]
                        }, ";
                }
                //starts a new series
                if ($bench != $row['bench']) {
                	$seriesIndex = 0;
                    $bench = $row['bench'];
                    $series .= "
                        {
                            name: '{$row['bench']}',
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

        echo $this->container->getTwig()->render('config_improvement/config_improvement.html.twig',
             array('selected' => 'Config Improvement',
                'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
                'highcharts_js' => HighCharts::getHeader(),
                'categories' => $categories,
                'series' => $series,
                'benchs' => $benchs,
                'nets' => $nets,
                'disks' => $disks,
                'blk_sizes' => $blk_sizes,
                'comps' => $comps,
                'id_clusters' => $id_clusters,
                'mapss' => $mapss,
                'replications' => $replications,
                'iosfs' => $iosfs,
                'iofilebufs' => $iofilebufs,
                'count' => $count,
                'height' => $height,
             	'money' => $money
             )
        );
    }

    public function benchExecutionsAction()
    {
    	$discreteOptions = Utils::getExecsOptions($this->container->getDBUtils());
        echo $this->container->getTwig()->render('benchexecutions/benchexecutions.html.twig',
            array('selected' => 'Benchmark Executions',
                'theaders' => self::$show_in_result,
            	'discreteOptions' => $discreteOptions
            ));
    }

    public function costPerfEvaluationAction()
    {
        $filter_execs = "AND exe_time > 200 AND (id_cluster = 1 OR (bench != 'bayes' AND id_cluster=2))";
        $filter_execs_max_time = "AND exe_time < 10000";
        $dbUtils = $this->container->getDBUtils();
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

            if (isset($_GET['cost_hour_HDD_ETH'])) {
                $cost_hour_HDD_ETH = $_GET['cost_hour_HDD_ETH'];
            } else {
                $cost_hour_HDD_ETH = 7.1;
            }

            if (isset($_GET['cost_hour_AZURE'])) {
                $cost_hour_AZURE = $_GET['cost_hour_AZURE'];
            } else {
                $cost_hour_AZURE = 5.4;
            }

            if (isset($_GET['cost_hour_AZURE_1remote'])) {
                $cost_hour_AZURE_1remote = $_GET['cost_hour_AZURE_1remote'];
            } else {
                $cost_hour_AZURE_1remote = 0.313;
            }

            if (isset($_GET['cost_hour_SSD_IB'])) {
                $cost_hour_SSD_IB = $_GET['cost_hour_SSD_IB'];
            } else {
                $cost_hour_SSD_IB = 11.2;
            }

            if (isset($_GET['cost_hour_SSD_ETH'])) {
                $cost_hour_SSD_ETH = $_GET['cost_hour_SSD_ETH'];
            } else {
                $cost_hour_SSD_ETH = 7.5;
            }

            if (isset($_GET['cost_hour_HDD_IB'])) {
                $cost_hour_HDD_IB = $_GET['cost_hour_HDD_IB'];
            } else {
                $cost_hour_HDD_IB = 11.6;
            }

            $configurations = array();
            $where_configs = '';
            $concat_config = "";

            // $benchs = $dbUtils->read_params('benchs',$where_configs,$configurations,$concat_config);
            $nets = Utils::read_params('nets', $where_configs, $configurations, $concat_config);
            $disks = Utils::read_params('disks', $where_configs, $configurations, $concat_config);
            $blk_sizes = Utils::read_params('blk_sizes', $where_configs, $configurations, $concat_config);
            $comps = Utils::read_params('comps', $where_configs, $configurations, $concat_config);
            $id_clusters = Utils::read_params('id_clusters', $where_configs, $configurations, $concat_config);
            $mapss = Utils::read_params('mapss', $where_configs, $configurations, $concat_config);
            $replications = Utils::read_params('replications', $where_configs, $configurations, $concat_config);
            $iosfs = Utils::read_params('iosfs', $where_configs, $configurations, $concat_config);
            $iofilebufs = Utils::read_params('iofilebufs', $where_configs, $configurations, $concat_config);
            $money 	= Utils::read_params('money',$where_configs,$configurations,$concat_config);
            
            $outliers = "(exe_time/3600)*$cost_hour_HDD_ETH < 100 $filter_execs $filter_execs_max_time";
    //        $avg_exe_time = "(select avg(exe_time) from execs e where $outliers $bench_where $where_configs )";
     //       $std_exe_time = "(select std(exe_time) from execs e where $outliers $bench_where $where_configs )";
            $max_exe_time = "(select max(exe_time) from execs e where $outliers $bench_where $where_configs )";
            $min_exe_time = "(select min(exe_time) from execs e where $outliers $bench_where $where_configs )";
            $cost_per_run = "(exe_time/3600)*
            (
            if(locate('_SSD_', exec) > 0,
            if(locate('IB_SSD_', exec) > 0,
            $cost_hour_SSD_IB,
            $cost_hour_SSD_ETH
            ),
            if (locate('IB_HDD', exec) > 0,
            $cost_hour_HDD_IB,
            if (locate('_az', exec) > 0,
            if (locate('_ETH_R1_', exec) > 0 OR locate('_ETH_RR1_', exec) > 0,
            " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 1)) . ",
            if (locate('_ETH_R2_', exec) > 0 OR locate('_ETH_RR2_', exec) > 0,
                        " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 2)) . ",
                if (locate('_ETH_R3_', exec) > 0 OR locate('_ETH_RR3_', exec) > 0,
                            " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 3)) . ",
                    if (locate('_RL1_', exec) > 0,
                    " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 1)) . ",
                                if (locate('_RL2_', exec) > 0,
                    " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 2)) . ",
                                    if (locate('_RL3_', exec) > 0,
                        " . ($cost_hour_AZURE + ($cost_hour_AZURE_1remote * 3)) . ",
                                        $cost_hour_AZURE
                                    )
                        )
                        )
                    )
                    )
                    ),
                        $cost_hour_HDD_ETH
                    )
                    )
                    )
                    )";

        //    $avg_cost_per_run = "(select avg($cost_per_run) from execs e where $outliers $bench_where $where_configs)";
          //  $std_cost_per_run = "(select std($cost_per_run) from execs e where $outliers $bench_where $where_configs)";
            $max_cost_per_run = "(select max($cost_per_run) from execs e where $outliers $bench_where $where_configs)";
            $min_cost_per_run = "(select min($cost_per_run) from execs e where $outliers $bench_where $where_configs)";

            // http://minerva.bsc.es:8099/aloja-web/perf_by_cost2.php?bench=wordcount&cost_hour_LOCAL=12&cost_hour_AZURE=7&cost_hour_SSD_IB=40&cost_hour_SSD_ETH=30&cost_hour_HDD_IB=22

            $query = "
                            SELECT
                            (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time)  exe_time_std,
                            ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
                            exec, exe_time, $cost_per_run cost,
                            $min_exe_time min_exe_time, $max_exe_time max_exe_time, $min_exe_time min_exe_time
                            from execs e
                            where $outliers $bench_where $where_configs and substr(exec, 1, 8) > '20131220';
                            ";

            $rows = $dbUtils->get_rows($query);

            if ($rows) {
                // var_dump($rows);
            } else {
                throw new \Exception("No results for query!");
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
        }

        $seriesData = '';
        foreach ($rows as $row) {

            $exec = substr($row['exec'], 21);

            if (strpos($exec, '_az') > 0) {
                $exec = "AZURE " . $exec;
            } else {
                $exec = "LOCAL " . $exec;
            }

            $seriesData .= "{
            name: '" . $exec . "',
                data: [[" . round($row['exe_time_std'], 3) . ", " . round($row['cost_std'], 3) . "]]
        },";
        }

        echo $this->container->getTwig()->render('perf_by_cost/perf_by_cost.html.twig', array(
            'selected' => 'Cost Evaluation',
            'highcharts_js' => HighCharts::getHeader(),
            // 'show_in_result' => count($show_in_result),
            'seriesData' => $seriesData,
            'benchs' => array($bench),
            'select_multiple_benchs' => false,
            'cost_hour_SSD_IB' => $cost_hour_SSD_IB,
            'cost_hour_AZURE' => $cost_hour_AZURE,
            'cost_hour_AZURE_1remote' => $cost_hour_AZURE_1remote,
            'cost_hour_HDD_ETH' => $cost_hour_HDD_ETH,
            'cost_hour_HDD_IB' => $cost_hour_HDD_IB,
            'cost_hour_SSD_ETH' => $cost_hour_SSD_ETH,
            // 'benchs' => $benchs,
            'nets' => $nets,
            'disks' => $disks,
            'blk_sizes' => $blk_sizes,
            'comps' => $comps,
            'id_clusters' => $id_clusters,
            'mapss' => $mapss,
            'replications' => $replications,
            'iosfs' => $iosfs,
            'iofilebufs' => $iofilebufs,
            'title' => 'Normalized Cost by Performance Evaluation of Hadoop Executions',
        	'money' => $money
        // 'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
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
                $selected_hosts = array(
                    'minerva-1002', 'minerva-1003', 'minerva-1004',
                    'al-1002', 'al-1003', 'al-1004',
                    'minerva-2','minerva-3','minerva-4',
                    'minerva-6','minerva-7','minerva-8',
                    'minerva-7', 'minerva-8','minerva-9','minerva-10','minerva-11','minerva-12','minerva-13','minerva-14','minerva-15','minerva-16','minerva-17','minerva-18','minerva-19','minerva-20',

                );
            } elseif ($hosts == 'Master') {
                $selected_hosts = array(
                    'minerva-1001',
                    'al-1001',
                    'minerva-1',
                    'minerva-6',
                    'minerva-5',
                );
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
                        'group_title' => 'Job execution history',
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

        echo $this->container->getTwig()->render('perfcharts/perfcharts.html.twig',
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
        	$benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs JOIN JOB_details USING (id_exec) WHERE valid = TRUE");
        	
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

            $join = "JOIN execs e using (id_exec) WHERE JOBNAME NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links')".
                ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':''). " LIMIT 10000";

            if ($type == 'SUMMARY') {
                $query = "SELECT e.bench, exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES
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
                $taskStatusOptions = $db->get_rows("SELECT DISTINCT TASK_STATUS FROM JOB_tasks JOIN execs USING (id_exec) WHERE valid = TRUE");
                $typeOptions = $db->get_rows("SELECT DISTINCT TASK_TYPE FROM JOB_tasks JOIN execs USING (id_exec) WHERE valid = TRUE");

                $discreteOptions['TASK_STATUS'][] = 'All';
                $discreteOptions['TASK_TYPE'][] = 'All';
                foreach($taskStatusOptions as $option) {
                	$discreteOptions['TASK_STATUS'][] = array_shift($option);
                }
                foreach($typeOptions as $option) {
                	$discreteOptions['TASK_TYPE'][] = array_shift($option);
                }
            } else {
                throw new \Exception('Unknown type!');
            }

            $exec_rows = $dbUtil->get_rows($query);

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

        echo $this->container->getTwig()->render('counters/counters.html.twig',
            array('selected' => 'Hadoop Job Counters',
                'theaders' => $show_in_result_counters,
                //'table_fields' => $table_fields,
                'message' => $message,
                'title' => 'Hadoop Jobs and Tasks Execution Counters',
                'type' => $type,
                'execs' => $execs,
                'execsParam' => (isset($_GET['execs'])) ? $_GET['execs'] : '',
            	'discreteOptions' => $discreteOptions
                //'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
            ));
    }
    
    public function performanceTableAction()
    {
        $show_in_result_metrics = array();
        $type = Utils::get_GET_string('type');
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
     
        $discreteOptions = Utils::getExecsOptions($this->container->getDBUtils());
        echo $this->container->getTwig()->render('metrics/metrics.html.twig',
            array('selected' => 'Performance Metrics',
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

    public function bestConfigAction() {
		$db = $this->container->getDBUtils ();
		$rows_config = '';
		$bestexec = '';
		$cluster = '';
		$comp = '';
		$execsDetails = array ();
		try {
			$configurations = array ();
			$where_configs = '';
			$concat_config = "";
			
			$benchs = Utils::read_params ( 'benchs', $where_configs, $configurations, $concat_config, false );
			$nets = Utils::read_params ( 'nets', $where_configs, $configurations, $concat_config, false );
			$disks = Utils::read_params ( 'disks', $where_configs, $configurations, $concat_config, false );
			$blk_sizes = Utils::read_params ( 'blk_sizes', $where_configs, $configurations, $concat_config, false );
			$comps = Utils::read_params ( 'comps', $where_configs, $configurations, $concat_config, false );
			$id_clusters = Utils::read_params ( 'id_clusters', $where_configs, $configurations, $concat_config, false );
			$mapss = Utils::read_params ( 'mapss', $where_configs, $configurations, $concat_config, false );
			$replications = Utils::read_params ( 'replications', $where_configs, $configurations, $concat_config, false );
			$iosfs = Utils::read_params ( 'iosfs', $where_configs, $configurations, $concat_config, false );
			$iofilebufs = Utils::read_params ( 'iofilebufs', $where_configs, $configurations, $concat_config, false );
			$money = Utils::read_params ( 'money', $where_configs, $configurations, $concat_config, false );
			if (! $benchs)
				$where_configs .= 'AND bench IN (\'wordcount\')';
			$order_type = Utils::get_GET_string ( 'ordertype' );
			if (! $order_type)
				$order_type = 'exe_time';
				// $concat_config = join(',\'_\',', $configurations);
				// $concat_config = substr($concat_config, 1);
			
			$filter_execs = "AND exe_time > 200 AND (id_cluster = 1 OR (bench != 'bayes' AND id_cluster=2))";
			$order_conf = 'LENGTH(conf), conf';
			
			// get the result rows
			$query = "SELECT e.*,
    		(exe_time/3600)*(cost_hour) cost
    		from execs e
    		join clusters USING (id_cluster)
    		WHERE e.valid = TRUE $where_configs
    		ORDER BY $order_type ASC;";
			
			$this->getContainer ()->getLog ()->addInfo ( 'BestConfig query: ' . $query );
			
			$rows = $db->get_rows ( $query );
			
			if (! $rows) {
				throw new \Exception ( "No results for query!" );
			}
			if ($rows) {
				$bestexec = $rows[0];
				$conf = $bestexec['exec'];
				$parameters = explode ( '_', $conf );
				$cluster = (explode ( '/', $parameters [count ( $parameters ) - 1] )[0] == 'az') ? 'Azure' : 'Local';
				Utils::makeExecInfoBeauty($bestexec);
			}
		} catch ( \Exception $e ) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		}
		
		if (empty ( $benchs ))
			$benchs = array (
					'wordcount' 
			);
		echo $this->container->getTwig ()->render ( 'bestconfig/bestconfig.html.twig', array (
				'selected' => 'Best configuration',
				'title' => 'Best Run Configuration',
				'bestexec' => $bestexec,
				'cluster' => $cluster,
				'order_type' => $order_type,
				'benchs' => $benchs,
				'nets' => $nets,
				'disks' => $disks,
				'blk_sizes' => $blk_sizes,
				'comps' => $comps,
				'id_clusters' => $id_clusters,
				'mapss' => $mapss,
				'replications' => $replications,
				'iosfs' => $iosfs,
				'iofilebufs' => $iofilebufs,
				'money' => $money,
				'select_multiple_benchs' => false 
		) );
	}
	public function paramEvaluationAction() {
		$db = $this->container->getDBUtils ();
		$rows = '';
		$categories = '';
		$series = '';
		try {
			$configurations = array ();
			$where_configs = '';
			$concat_config = "";
			
			if(!(isset($_GET['benchs'])))
				$_GET['benchs'][] = 'wordcount';
			
			$benchs = Utils::read_params ( 'benchs', $where_configs, $configurations, $concat_config );
			$nets = Utils::read_params ( 'nets', $where_configs, $configurations, $concat_config );
			$disks = Utils::read_params ( 'disks', $where_configs, $configurations, $concat_config );
			$blk_sizes = Utils::read_params ( 'blk_sizes', $where_configs, $configurations, $concat_config );
			$comps = Utils::read_params ( 'comps', $where_configs, $configurations, $concat_config );
			$id_clusters = Utils::read_params ( 'id_clusters', $where_configs, $configurations, $concat_config );
			$mapss = Utils::read_params ( 'mapss', $where_configs, $configurations, $concat_config );
			$replications = Utils::read_params ( 'replications', $where_configs, $configurations, $concat_config );
			$iosfs = Utils::read_params ( 'iosfs', $where_configs, $configurations, $concat_config );
			$iofilebufs = Utils::read_params ( 'iofilebufs', $where_configs, $configurations, $concat_config );
			$money = Utils::read_params ( 'money', $where_configs, $configurations, $concat_config );
			// $concat_config = join(',\'_\',', $configurations);
			// $concat_config = substr($concat_config, 1);
			$paramEval = (isset($_GET['parameval']) && $_GET['parameval'] != '') ? $_GET['parameval'] : 'maps';
			$minExecs = (isset($_GET['minexecs'])) ? $_GET['minexecs'] : -1;
			$minExecsFilter = "";
			if($minExecs > 0)
				$minExecsFilter = "HAVING COUNT(*) > $minExecs";
			
			$filter_execs = "AND valid = TRUE";
				
			$paramOptions = array();
			if($paramEval == 'maps')
				$paramOptions = array(4,6,8,10,12,16,24,32);
			else if($paramEval == 'comp')
				$paramOptions = array('None','ZLIB','BZIP2','Snappy');
		    else if($paramEval == 'id_cluster')
				$paramOptions = array('Local','Azure');
			else if($paramEval == 'net')
				$paramOptions = array('Ethernet','Infiniband');
			else if($paramEval == 'disk')
				$paramOptions = array('Hard-disk drive','1 HDFS remote(s)/tmp local','2 HDFS remote(s)/tmp local','3 HDFS remote(s)/tmp local','1 HDFS remote(s)', '2 HDFS remote(s)', '3 HDFS remote(s)', 'SSD');
			else if($paramEval == 'replication')
				$paramOptions = array(1,2,3);
			else if($paramEval == 'iofilebuf')
				$paramOptions = array(1,4,16,32,64,128,256);
			else if($paramEval == 'blk_size')
				$paramOptions = array(32,64,128,256);
			else if($paramEval == 'iosf')
				$paramOptions = array(5,10,20,50);
			
			$benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs WHERE 1 $filter_execs $where_configs GROUP BY $paramEval, bench order by $paramEval");
						
			// get the result rows
			$query = "SELECT count(*) as count, $paramEval, e.id_exec, exec as conf, bench, ".
				"exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
				"from execs e WHERE 1 $filter_execs $where_configs".
				"GROUP BY $paramEval, bench $minExecsFilter order by bench,$paramEval";
			
			$rows = $db->get_rows ( $query );

			if (!$rows) {
				throw new \Exception ( "No results for query!" );
			}
	
			$categories = '';
			$arrayBenchs = array();
			foreach ( $paramOptions as $param ) {
				$categories .= "'$param ".Utils::getParamevalUnit($paramEval)."',";
				foreach($benchOptions as $bench) {
					$arrayBenchs[$bench['bench']][$param] = null;
				}
			}

			$series = array();
			$bench = '';
			foreach($rows as $row) {
				if($paramEval == 'comp')
					$row[$paramEval] = Utils::getCompressionName($row['comp']);
				else if($paramEval == 'id_cluster') {
					if($row[$paramEval] == 1)
						$row[$paramEval] = 'Local';
					else
						$row[$paramEval] = 'Azure';
				} else if($paramEval == 'net')
					$row[$paramEval] = Utils::getNetworkName($row['net']);
				else if($paramEval == 'disk')
					$row[$paramEval] = Utils::getDisksName($row['disk']);
				else if($paramEval == 'iofilebuf')
					$row[$paramEval] /= 1024;
				
				$arrayBenchs[$row['bench']][$row[$paramEval]]['y'] = round((int)$row['avg_exe_time'],2);
				$arrayBenchs[$row['bench']][$row[$paramEval]]['count'] = (int)$row['count'];
			}				
					
			foreach($arrayBenchs as $key => $arrayBench)
			{
				$series[] = array('name' => $key, 'data' => array_values($arrayBench));
			}
			$series = json_encode($series);
		} catch ( \Exception $e ) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		}
		
		echo $this->container->getTwig ()->render ('configperf/configperf.html.twig', array (
				'selected' => 'Parameter Evaluation',
				'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
				'categories' => $categories,
				'series' => $series,
				'benchs' => $benchs,
				'nets' => $nets,
				'disks' => $disks,
				'blk_sizes' => $blk_sizes,
				'comps' => $comps,
				'id_clusters' => $id_clusters,
				'mapss' => $mapss,
				'replications' => $replications,
				'iosfs' => $iosfs,
				'iofilebufs' => $iofilebufs,
				'money' => $money,
				'paramEval' => $paramEval
		) );
	}
	
	public function publicationsAction()
	{
		echo $this->container->getTwig()->render('publications/publications.html.twig', array(
				'selected' => 'Publications',
				'title' => 'ALOJA Publications'));
	}
	
	public function teamAction()
	{
		echo $this->container->getTwig()->render('team/team.html.twig', array(
				'selected' => 'Team',
				'title' => 'ALOJA Team & Collaborators'));
	}
	
	public function clustersAction()
	{
		echo $this->container->getTwig()->render('clusters/clusters.html.twig', array(
				'selected' => 'Clusters',
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
            $query = "
                SELECT DISTINCT(t.`JOBID`)
                FROM `JOB_tasks` t
                ORDER BY RAND()
                LIMIT 1
            ;";
            $jobid = $db->get_rows($query)[0]['JOBID'];
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
        $jobid = Utils::get_GET_string("jobid");

        // if no job requested, show a random one
        if (strlen($jobid) == 0 || $jobid === "random") {
            $_GET['NO_CACHE'] = 1;  // Disable cache, otherwise random will not work
            $db = $this->container->getDBUtils();
            $query = "
                SELECT DISTINCT(t.`JOBID`)
                FROM `JOB_tasks` t
                ORDER BY RAND()
                LIMIT 1
            ;";
            $jobid = $db->get_rows($query)[0]['JOBID'];
        }

        list($bench, $job_offset, $id_exec) = $this->container->getDBUtils()->get_jobid_info($jobid);

        echo $this->container->getTwig()->render('dbscanexecs/dbscanexecs.html.twig',
            array(
                'selected' => 'DBSCANexecs',
                'highcharts_js' => HighCharts::getHeader(),
                'jobid' => $jobid,
                'bench' => $bench,
                'job_offset' => $job_offset,
                'METRICS' => DBUtils::$TASK_METRICS,
            )
        );
    }
    
    public function mlpredictionAction()
    {
    	$jsonExecs = array();
    	try
	{
	    	$db = $this->container->getDBUtils();
	    	
	    	$configurations = array ();
	    	$where_configs = '';
	    	$concat_config = "";
	    	
	    	$benchs         = Utils::read_params('benchs',$where_configs,$configurations,$concat_config);
	    	$nets           = Utils::read_params('nets',$where_configs,$configurations,$concat_config);
	    	$disks          = Utils::read_params('disks',$where_configs,$configurations,$concat_config);
	    	$blk_sizes      = Utils::read_params('blk_sizes',$where_configs,$configurations,$concat_config);
	    	$comps          = Utils::read_params('comps',$where_configs,$configurations,$concat_config);
	    	$id_clusters    = Utils::read_params('id_clusters',$where_configs,$configurations,$concat_config);
	    	$mapss          = Utils::read_params('mapss',$where_configs,$configurations,$concat_config);
	    	$replications   = Utils::read_params('replications',$where_configs,$configurations,$concat_config);
	    	$iosfs          = Utils::read_params('iosfs',$where_configs,$configurations,$concat_config);
	    	$iofilebufs     = Utils::read_params('iofilebufs',$where_configs,$configurations,$concat_config);

		$dummy = "";
		$learn_param	= Utils::read_params('learn',$dummy,$configurations,$dummy);

		// Check params...
		$all_ok = !empty($benchs) && !empty($nets) && !empty($disks) && !empty($blk_sizes) && !empty($comps) && !empty($id_clusters) && !empty($mapss) && !empty($replications) && !empty($iosfs) && !empty($iofilebufs);

		$message = "";
		if (count($_GET) > 1 && !$all_ok) $message = "Select AT LEAST 1 value for each attribute";

		if (count($_GET) > 1 && $all_ok)
		{
			$config = str_replace(array('AND ','IN '),'',$where_configs).' '.$learn_param[0];
			$learn_options = 'saveall='.md5($config);

			if ($learn_param[0] == 'regtree') $learn_method = 'aloja_regtree';
			else if ($learn_param[0] == 'nneighbours') { $learn_method = 'aloja_nneighbors'; $learn_options .=':kparam=3';}
			else if ($learn_param[0] == 'nnet') $learn_method = 'aloja_nnet';
			else if ($learn_param[0] == 'polyreg') { $learn_method = 'aloja_linreg'; $learn_options .= ':ppoly=3'; }

			$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';

			if (file_exists($cache_ds))
			{
				$keep_cache = TRUE;
				foreach (array("tt", "tv", "tr") as &$value)
				{
					$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv');
				}
				if (!$keep_cache)
				{
					unlink($cache_ds);
					shell_exec("sed -i '".md5($config)." :".$config."/d' ".getcwd()."/cache/query/record.data");
				}
			}

			if (!file_exists($cache_ds))
			{
				// get headers for csv
				$header_names = array(
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
					'histogram' => 'Histogram',
					'prv' => 'PARAVER',
					'end_time' => 'End time',
				);

			    	$query="SHOW COLUMNS FROM execs;";
			    	$rows = $db->get_rows ($query);
				$headers = array();
				$names = array();
				$count = 0;
				foreach($rows as $row)
				{
					if (array_key_exists($row['Field'],$header_names))
					{
						$headers[$count] = $row['Field'];
						$names[$count++] = $header_names[$row['Field']];
					}
				}
				$headers[$count] = 0;	// FIXME - Costs are NOT in the database?! What kind of anarchy is this?!
				$names[$count++] = $header_names['cost'];

			    	// dump the result to csv
			    	$query="SELECT ".implode(",",$headers)." FROM execs WHERE valid = TRUE ".$where_configs.";";
			    	$rows = $db->get_rows ( $query );

				$fp = fopen($cache_ds, 'w');
				fputcsv($fp, $names,',','"');
			    	foreach($rows as $row)
				{
					$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
					$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
					fputcsv($fp, array_values($row),',','"');
				}

				// run the R processor
				$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -d '.$cache_ds.' -m '.$learn_method.' -p '.$learn_options;
				$output = shell_exec($command);

				// update cache record (for human reading)
				$register = md5($config).' :'.$config."\n";
				file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
			}

			// read results of the CSV
			$count = 0;
			foreach (array("tt", "tv", "tr") as &$value)
			{
				if (($handle = fopen(getcwd().'/cache/query/'.md5($config).'-'.$value.'.csv', 'r')) !== FALSE) {
					$header = fgetcsv($handle, 1000, ",");

					$key_exec = array_search('Exe.Time', array_values($header));
					$key_pexec = array_search('Pred.Exe.Time', array_values($header));

					$info_keys = array("ID","Cluster","Benchmark","Net","Disk","Maps","IO.SFac","Rep","IO.FBuf","Comp","Blk.size");
					while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
						$jsonExecs[$count]['y'] = (int)$data[$key_exec];
						$jsonExecs[$count]['x'] = (int)$data[$key_pexec];

						$extra_data = "";
						foreach(array_values($header) as &$value2)
						{
							$aux = array_search($value2, array_values($header));
							if (array_search($value2, array_values($info_keys)) > 0) $extra_data = $extra_data.$value2.":".$data[$aux]." ";
							else if (!array_search($value2, array('Exe.Time','Pred.Exe.Time')) > 0 && $data[$aux] == 1) $extra_data = $extra_data.$value2." "; // Binarized Data
						}
						$jsonExecs[$count++]['mydata'] = $extra_data;
					}
					fclose($handle);
				}
			}
	    	}
    	}
	catch(\Exception $e) { $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" ); }
    	echo $this->container->getTwig()->render('mltemplate/mlprediction.html.twig',
		array(
			'selected' => 'mlprediction',
			'jsonExecs' => json_encode($jsonExecs),
			'benchs' => $benchs,
			'nets' => $nets,
			'disks' => $disks,
			'blk_sizes' => $blk_sizes,
			'comps' => $comps,
			'id_clusters' => $id_clusters,
			'mapss' => $mapss,
			'replications' => $replications,
			'iosfs' => $iosfs,
			'iofilebufs' => $iofilebufs,
			'learn' => $learn_param,
			'message' => $message
		)
    	);
    }

    public function mldatacollapseAction()
    {
    	try
	{
	    	$db = $this->container->getDBUtils();
	    	
/*	    	$configurations = array ();
	    	$where_configs = '';
	    	$concat_config = "";
	    	
	    	$benchs         = Utils::read_params('benchs',$where_configs,$configurations,$concat_config);
	    	$nets           = Utils::read_params('nets',$where_configs,$configurations,$concat_config);
	    	$disks          = Utils::read_params('disks',$where_configs,$configurations,$concat_config);
	    	$blk_sizes      = Utils::read_params('blk_sizes',$where_configs,$configurations,$concat_config);
	    	$comps          = Utils::read_params('comps',$where_configs,$configurations,$concat_config);
	    	$id_clusters    = Utils::read_params('id_clusters',$where_configs,$configurations,$concat_config);
	    	$mapss          = Utils::read_params('mapss',$where_configs,$configurations,$concat_config);
	    	$replications   = Utils::read_params('replications',$where_configs,$configurations,$concat_config);
	    	$iosfs          = Utils::read_params('iosfs',$where_configs,$configurations,$concat_config);
	    	$iofilebufs     = Utils::read_params('iofilebufs',$where_configs,$configurations,$concat_config);
*/
		$dims1 = "Net,Disk,Maps,IO.SFac,Rep,IO.FBuf,Comp,Blk.size,Cluster"; // FIXME - From input
		$dims2 = "Benchmark"; // FIXME - From input
		$dname1 = "Configuration"; // FIXME - From input
		$dname2 = "Benchmark"; // FIXME - From input
		$filling = "f9a02da6488bd924d92af2d16c71fb05"; // FIXME - bench ("bayes","pagerank","sort","terasort","wordcount","dfsioe_read","dfsioe_write") net ("IB","ETH") disk ("SSD","HDD","RL1","RL2","RL3","R1","R2","R3") blk_size ("32","64","128","256") comp ("0","1","2","3") id_cluster ("1","2") maps ("4","6","8","10","12","16","24","32") replication ("1","2","3") iosf ("5","10","20","50") iofilebuf ("1024","4096","16384","32768","65536","131072","262144") regtree

		$learning_model = '';
		if (file_exists(getcwd().'/cache/query/'.$filling.'-object.rds')) $learning_model = ':model_name='.$filling;

		$config = $dims1.'-'.$dims2.'-'.$dname1.'-'.$dname2."-".$filling;
		$options = 'dimension1="'.$dims1.'":dimension2="'.$dims2.'":dimname1="'.$dname1.'":dimname2="'.$dname2.'":saveall='.md5($config).$learning_model;

		$cache_ds = getcwd().'/cache/query/'.md5($config).'-cache.csv';
		if (file_exists($cache_ds))
		{
			$keep_cache = TRUE;
			foreach (array("ids.csv", "matrix.csv", "object.rds") as &$value)
			{
				$keep_cache = $keep_cache && file_exists(getcwd().'/cache/query/'.md5($config).'-'.$value);
			}
			if (!$keep_cache)
			{
				unlink($cache_ds);
				shell_exec("sed -i '".md5($config)." : ".$config."/d' ".getcwd()."/cache/query/record.data");
			}
		}

		if (!file_exists($cache_ds))
		{
			// get headers for csv
			$header_names = array(
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
				'histogram' => 'Histogram',
				'prv' => 'PARAVER',
				'end_time' => 'End time',
			);

		    	$query="SHOW COLUMNS FROM execs;";
		    	$rows = $db->get_rows ($query);
			$headers = array();
			$names = array();
			$count = 0;
			foreach($rows as $row)
			{
				if (array_key_exists($row['Field'],$header_names))
				{
					$headers[$count] = $row['Field'];
					$names[$count++] = $header_names[$row['Field']];
				}
			}
			$headers[$count] = 0;	// FIXME - Costs are NOT in the database?! What kind of anarchy is this?!
			$names[$count++] = $header_names['cost'];

			// dump the result to csv
		    	$query="SELECT ".implode(",",$headers)." FROM execs WHERE valid = TRUE ";//.$where_configs.";";
		    	$rows = $db->get_rows ( $query );

			$fp = fopen($cache_ds, 'w');
			fputcsv($fp, $names,',','"');
		    	foreach($rows as $row)
			{
				$row['id_cluster'] = "Cl".$row['id_cluster'];	// Cluster is numerically codified...
				$row['comp'] = "Cmp".$row['comp'];		// Compression is numerically codified...
				fputcsv($fp, array_values($row),',','"');
			}

			// prepare collapse
			$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_dataset_collapse -d '.$cache_ds.' -p '.$options;
			$output = shell_exec($command);

			// update cache record (for human reading)
			$register = md5($config).' : '.$config."\n";
			file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
		}

		// read results of the CSV
		if (	($handle = fopen(getcwd().'/cache/query/'.md5($config).'-matrix.csv', 'r')) !== FALSE
		&&	($handid = fopen(getcwd().'/cache/query/'.md5($config).'-ids.csv', 'r')) !== FALSE )
		{
			$header = fgetcsv($handle, 1000, ",");
			$headid = fgetcsv($handid, 1000, ",");

			$jsonHeader = '[{title:""}';
			foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
			$jsonHeader = $jsonHeader.']';

			$jsonColumns = '[';
			for ($i = 1; $i <= count($header); $i++)
			{
				if ($jsonColumns != '[') $jsonColumns = $jsonColumns.',';
				$jsonColumns = $jsonColumns.$i;
			}
			$jsonColumns = $jsonColumns.']';

			$jsonData = '[';
			$jsonColor = '[';
			while (	($data = fgetcsv($handle, 1000, ",")) !== FALSE
			&&	($daid = fgetcsv($handid, 1000, ",")) !== FALSE )
			{
				$data = str_replace('NA','',$data);
				if ($jsonData!='[') $jsonData = $jsonData.',';
				$jsonData = $jsonData.'[\''.implode("','",$data).'\']';


				$aux = array();
				for ($j = 0; $j < count($daid); $j++) $aux[$j] = ($daid[$j] == 'NA')?0:1;
				if ($jsonColor!='[') $jsonColor = $jsonColor.',';
				$jsonColor = $jsonColor.'[\''.implode("','",$aux).'\']';
			}
			$jsonColor = $jsonColor.']';
			$jsonData = $jsonData.']';
			fclose($handle);

			// negative prediction values (errors) are considered by default 100 as the minimal value...
			$jsonData = preg_replace('/(\-\d+\.\d+)/','100.0',$jsonData);
		}
    	}
	catch(Exception $e)
	{
		$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );

		$noData = array();
		for($i = 0; $i<=sizeof($show_in_result); ++$i) $noData[] = 'error';

		$jsonEncoded = json_encode(array('aaData' => array($noData)));
	}
	echo $this->container->getTwig()->render('mltemplate/mldatacollapse.html.twig',
		array(
			'selected' => 'mldatacollapse',
			'jsonEncoded' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'jsonColumns' => $jsonColumns,
			'jsonColor' => $jsonColor
		)
	);
    }


    public function mlfindattributesAction()
    {
    	try
	{
	    	$db = $this->container->getDBUtils();
	    	
	    	$configurations = array ();
	    	$where_configs = '';
	    	$concat_config = "";
	    	
	    	$benchs         = Utils::read_params('benchs',$where_configs,$configurations,$concat_config);
	    	$nets           = Utils::read_params('nets',$where_configs,$configurations,$concat_config);
	    	$disks          = Utils::read_params('disks',$where_configs,$configurations,$concat_config);
	    	$blk_sizes      = Utils::read_params('blk_sizes',$where_configs,$configurations,$concat_config);
	    	$comps          = Utils::read_params('comps',$where_configs,$configurations,$concat_config);
	    	$id_clusters    = Utils::read_params('id_clusters',$where_configs,$configurations,$concat_config);
	    	$mapss          = Utils::read_params('mapss',$where_configs,$configurations,$concat_config);
	    	$replications   = Utils::read_params('replications',$where_configs,$configurations,$concat_config);
	    	$iosfs          = Utils::read_params('iosfs',$where_configs,$configurations,$concat_config);
	    	$iofilebufs     = Utils::read_params('iofilebufs',$where_configs,$configurations,$concat_config);

		$jsonData = $jsonHeader = "[]";
		$instance = "";
		$possible_models = array();
		$possible_models_id = array();
		$message = "";

		$current_model = "";
		if (array_key_exists('current_model',$_GET)) $current_model = $_GET['current_model'];

		if (count($_GET) > 1)
		{
			// compose instance
			$bench_token = '';
			if (empty($benchs)) { $bench_token = '*'; }
			else { foreach ($benchs as $b) $bench_token = $bench_token.(($bench_token != '')?'|':'').$b; }

			$nets_token = '';
			if (empty($nets)) { $nets_token = '*'; }
			else { foreach ($nets as $b) $nets_token = $nets_token.(($nets_token != '')?'|':'').$b; }

			$disks_token = '';
			if (empty($disks)) { $disks_token = '*'; }
			else { foreach ($disks as $b) $disks_token = $disks_token.(($disks_token != '')?'|':'').$b; }

			$blk_sizes_token = '';
			if (empty($blk_sizes)) { $blk_sizes_token = '*'; }
			else { foreach ($blk_sizes as $b) $blk_sizes_token = $blk_sizes_token.(($blk_sizes_token != '')?'|':'').$b; }

			$comps_token = '';
			if (empty($comps)) { $comps_token = '*'; }
			else { foreach ($comps as $b) $comps_token = $comps_token.'Cmp'.(($comps_token != '')?'|':'').$b; }

			$id_clusters_token = '';
			if (empty($id_clusters)) { $id_clusters_token = '*'; }
			else { foreach ($id_clusters as $b) $id_clusters_token = $id_clusters_token.'Cl'.(($id_clusters_token != '')?'|':'').$b; }

			$mapss_token = '';
			if (empty($mapss)) { $mapss_token = '*'; }
			else { foreach ($mapss as $b) $mapss_token = $mapss_token.(($mapss_token != '')?'|':'').$b; }

			$replications_token = '';
			if (empty($replications)) { $replications_token = '*'; }
			else { foreach ($replications as $b) $replications_token = $replications_token.(($replications_token != '')?'|':'').$b; }

			$iosfs_token = '';
			if (empty($iosfs)) { $iosfs_token = '*'; }
			else { foreach ($iosfs as $b) $iosfs_token = $iosfs_token.(($iosfs_token != '')?'|':'').$b; }

			$iofilebufs_token = '';
			if (empty($iofilebufs)) { $iofilebufs_token = '*'; }
			else { foreach ($iofilebufs as $b) $iofilebufs_token = $iofilebufs_token.(($iofilebufs_token != '')?'|':'').$b; }

			// find possible models to predict
			$model_info = str_replace(array('AND ','IN '),'',$where_configs);

			if (($fh = fopen(getcwd().'/cache/query/record.data', 'r')) !== FALSE)
			{
				while (!feof($fh))
				{
					$line = fgets($fh, 4096);
					if (preg_match("(((bench|net|disk|blk_size) (\(.+\)))( )?)", $line))
					{
						$fts = explode(" : ",$line);
						$parts = explode(" ",$fts[1]);
						$buffer = array();
						$last_part = "";
						foreach ($parts as $p)
						{
							if (preg_match("(\(.+\))", $p)) $buffer[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
							else $last_part = $p;
						}

						if ($model_info[0]==' ') $model_info = substr($model_info, 1);
						$parts_2 = explode(" ",$model_info);
						$buffer_2 = array();
						$last_part = "";
						foreach ($parts_2 as $p)
						{
							if (preg_match("(\(.+\))", $p)) $buffer_2[$last_part] = explode(",",str_replace(array('(',')','"'),'',$p));
							else $last_part = $p;
						}

						$match = TRUE;
						foreach ($buffer_2 as $bk => $ba)
						{
							if (!array_key_exists($bk,$buffer)) { $match = FALSE; break; }
							if (array_intersect($ba, $buffer[$bk]) != $ba) { $match = FALSE; break; }
						}

						if ($match)
						{
							$possible_models[] = $line;
							$possible_models_id[] = $fts[0];
						}
					}
				}
				fclose($fh);
			}

			// compose and run instance
			$instance = $bench_token.','.$nets_token.','.$disks_token.','.$mapss_token.','.$iosfs_token.','.$replications_token.','.$iofilebufs_token.','.$comps_token.','.$blk_sizes_token.','.$id_clusters_token;

			if (!empty($possible_models_id))
			{
				if ($current_model != "") $model = $current_model;
				else $current_model = $model = $possible_models_id[0];

				$cache_filename = getcwd().'/cache/query/'.md5($instance.'-'.$model).'-ipred.csv';
				if (!file_exists($cache_filename))
				{
					// drop query
					$command = 'cd '.getcwd().'/cache/query; '.getcwd().'/resources/aloja_cli.r -m aloja_predict_instance -l '.$model.' -p inst_predict="'.$instance.'" -v | grep -v "WARNING"';
					$output = shell_exec($command);

					// read results
					$lines = explode("\n", $output);
					$jsonData = '[';
					$i = 1;
					while($i < count($lines))
					{
						if ($lines[$i]=='') break;
						$parsed = preg_replace('/\s+/', ',', $lines[$i]);
						if ($jsonData!='[') $jsonData = $jsonData.',';
						$jsonData = $jsonData.'[\''.implode("','",explode(',',$parsed)).'\']';
						$i++;
					}
					$jsonData = $jsonData.']';

					$header = array('Benchmark','Net','Disk','Maps','IO.SFS','Rep','IO.FBuf','Comp','Blk.Size','Cluster','Prediction');
					$jsonHeader = '[{title:""}';
					foreach ($header as $title) $jsonHeader = $jsonHeader.',{title:"'.$title.'"}';
					$jsonHeader = $jsonHeader.']';

					// save at cache
					file_put_contents($cache_filename, $jsonHeader."\n".$jsonData);

					// update cache record (for human reading)
					$register = md5($instance.'-'.$model).' : '.$instance."-".$model."\n";
					file_put_contents(getcwd().'/cache/query/record.data', $register, FILE_APPEND | LOCK_EX);
				}
				else
				{
					// get cache
					$data = explode("\n",file_get_contents($cache_filename));
					$jsonHeader = $data[0];
					$jsonData = $data[1];
				}
			}
			else
			{
				$message = "There are no prediction models trained for such parameters. Train at least one model in 'ML Prediction' section.";
			}
		}
		else
		{
			$message = "Select the attributes to create a prediction on the right menu";
		}
	}
	catch(Exception $e)
	{
		$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );

		$noData = array();
		for($i = 0; $i<=sizeof($show_in_result); ++$i) $noData[] = 'error';

		$jsonData = json_encode(array('aaData' => array($noData)));
		$jsonHeader = "[]";
		$instance = $possible_models_id = "";
		$possible_models = array();
	}
	echo $this->container->getTwig()->render('mltemplate/mlfindattributes.html.twig',
		array(
			'selected' => 'mlfindattributes',
			'instance' => $instance,
			'benchs' => $benchs,
			'nets' => $nets,
			'disks' => $disks,
			'blk_sizes' => $blk_sizes,
			'comps' => $comps,
			'id_clusters' => $id_clusters,
			'mapss' => $mapss,
			'replications' => $replications,
			'iosfs' => $iosfs,
			'iofilebufs' => $iofilebufs,
			'jsonData' => $jsonData,
			'jsonHeader' => $jsonHeader,
			'models' => '<li>'.implode('</li><li>',$possible_models).'</li>',
			'models_id' => '[\''.implode("','",$possible_models_id).'\']',
			'current_model' => $current_model,
			'message' => $message
		)
	);
    }

    public function mlclearcacheAction()
    {
    	try
	{
		$message = "";
		$output = array();

		if (array_key_exists("ccache",$_GET))
		{
			if (($fh = fopen(getcwd().'/cache/query/record.data', 'r')) !== FALSE)
			{
				while (!feof($fh))
				{
					$line = fgets($fh, 4096);
					$fts = explode(" : ",$line);

					$command = 'rm '.getcwd().'/cache/query/'.$fts[0].'-*';
					$output[] = shell_exec($command);
				}
				fclose($fh);

				$command = 'rm '.getcwd().'/cache/query/record.data';
				$output[] = shell_exec($command);
			}
		}
	}
	catch(Exception $e)
	{
		$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		$message = $e->getMessage();
		$output = array();
	}
	echo $this->container->getTwig()->render('mltemplate/mlclearcache.html.twig',
		array(
			'selected' => 'mlclearcache',
			'message' => $message,
			'output' => '<li>'.implode("</li><li>",$output).'</li>'
		)
	);
    }
}
