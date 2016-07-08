<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\Container\Container;

class PerfDetailsController extends AbstractController
{
    public function __construct($container) {
        parent::__construct($container);

        $this->removeFilters(array('upred','uobsr'));
    }

    public function performanceChartsAction()
    {
        $exec_rows = null;
        $id_exec_rows = null;
        $dbUtil = $this->container->getDBUtils();
        $this->buildFilters(array('perf_details' => array('default' => 1)));
        $charts = array();
        $clusters = array();
        $container = new Container();

        try {
            //TODO fix, initialize variables
            $dbUtil->get_exec_details('1', 'id_exec',$exec_rows,$id_exec_rows);

            //check the URL
            $execs = Utils::get_GET_intArray('execs');

            if(empty($execs)) {
                $whereClause = $this->filters->getWhereClause();
                $query = "SELECT e.id_exec FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
                          LEFT JOIN aloja_ml.predictions p USING (id_exec)
                          WHERE 1 ". DBUtils::getFilterExecs()."$whereClause ";
                $query .= (isset($_GET['random'])) ? '' : 'LIMIT 1';
                $idExecs = $dbUtil->get_rows($query);
                if(isset($_GET['random']))
                    $execs = array($idExecs[rand(0,sizeof($idExecs)-1)]['id_exec']);
                else
                    $execs[] = $idExecs[0]['id_exec'];
            }

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

                $query = "SELECT e.*, (exe_time/3600)*(cost_hour) cost, name cluster_name, datanodes  FROM aloja2.execs e
        JOIN aloja2.clusters c USING (id_cluster)
        WHERE e.id_exec ='$exec'";

                $db = $container->getDBUtils();
                $exec_rows_tmp = $db->get_rows($query);

                $exec_title = $exec_rows_tmp[0]['exec'];

//                $pos_name = strpos($exec_title, '/');
//                $exec_title =
//                    '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'.
//                    strtoupper(substr($exec_title, ($pos_name+1))).
//                    '&nbsp;'.
//                    ((strpos($exec_title, '_az') > 0) ? 'AZURE':'LOCAL').
//                    "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ID_$exec ".
//                    substr($exec_title, 21, (strlen($exec_title) - $pos_name - ((strpos($exec_title, '_az') > 0) ? 21:18)))
//                ;

                $exec_details[$exec]['time']        = $exec_rows_tmp[0]['exe_time'];
                $exec_details[$exec]['start_time']  = $exec_rows_tmp[0]['start_time'];
                $exec_details[$exec]['end_time']    = $exec_rows_tmp[0]['end_time'];

                $id_cluster = $exec_rows_tmp[0]['id_cluster'];
                if (!in_array($id_cluster, $clusters)) $clusters[] = $id_cluster;

                //$end_time = get_exec_details($exec, 'init_time');

                # TODO check date problems (ie. id_exec =115259 seems to have a different timezone)
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
                        maps map,shuffle,merge,reduce,waste FROM aloja_logs.JOB_status
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
                        `%iowait`, $aggr(`%nice`) `%nice` FROM aloja_logs.SAR_cpu $where $group_by;",
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
                        FROM aloja_logs.SAR_load $where $group_by;",
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
                        FROM aloja_logs.SAR_load $where $group_by;",
                        'fields'    => array('runq-sz', 'blocked'),
                        'title'     => "CPU Queues ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Queues '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'load_tasks' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`plist-sz`) `plist-sz` FROM aloja_logs.SAR_load $where $group_by;",
                        'fields'    => array('plist-sz'),
                        'title'     => "Number of tasks for CPUs ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'Number of tasks for CPUs '."($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'switches' => array(
                        'metric'    => "CPU",
                        'query'     => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`proc/s`) `proc/s`, $aggr(`cswch/s`) `cswch/s` FROM aloja_logs.SAR_switches $where $group_by;",
                        'fields'    => array('proc/s', 'cswch/s'),
                        'title'     => "CPU Context Switches ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'CPU Context Switches'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'interrupts' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`intr/s`) `intr/s` FROM aloja_logs.SAR_interrupts $where $group_by;",
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
                        FROM aloja_logs.SAR_memory_util $where $group_by;",
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
                        FROM aloja_logs.SAR_memory_util $where $group_by;",
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
                    FROM aloja_logs.SAR_memory $where $group_by;",
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
                                    FROM aloja_logs.SAR_io_paging $where $group_by;",
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
                                    FROM aloja_logs.SAR_io_paging $where $group_by;",
                        'fields'    => array('fault/s', 'majflt/s', 'pgfree/s', 'pgscank/s', 'pgscand/s', 'pgsteal/s'),
                        'title'     => "I/O Paging ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'I/O Paging'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'io_pagging_vmeff' => array(
                        'metric'    => "Memory",
                        'query' => "SELECT time_to_sec(timediff(date, '{$exec_details[$exec]['start_time']}')) time, $aggr(`%vmeff`) `%vmeff` FROM aloja_logs.SAR_io_paging $where $group_by;",
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
                                                        FROM aloja_logs.SAR_io_rate $where $group_by;",
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
                                            FROM aloja_logs.SAR_io_rate $where $group_by;",
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
                    from aloja_logs.SAR_block_devices d WHERE id_exec = '$exec'
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
                        from aloja_logs.SAR_block_devices d WHERE id_exec = '$exec'
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
                                            from aloja_logs.SAR_block_devices d WHERE id_exec = '$exec'
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
                                        from aloja_logs.SAR_block_devices d WHERE id_exec = '$exec'
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
            FROM aloja_logs.VMSTATS $where_VMSTATS $group_by_vmstats;",
                        'fields'    => array('KB_IN', 'KB_OUT'),
                        'title'     => "VMSTATS KB I/O ($aggr_text, $hosts) $exec_title ",
                        'group_title' => 'VMSTATS KB I/O'." ($aggr_text, $hosts)",
                        'percentage'=> false,
                        'stacked'   => false,
                        'negative'  => false,
                    ),
                    'vmstats_rb' => array(
                        'metric'    => "CPU",
                        'query' => "SELECT time, $aggr(`r`) `runnable procs`, $aggr(`b`) `sleep procs` FROM aloja_logs.VMSTATS $where_VMSTATS $group_by_vmstats;",
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
                        FROM aloja_logs.VMSTATS $where_VMSTATS $group_by_vmstats;",
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
                        FROM aloja_logs.SAR_net_devices $where AND IFACE not IN ('') $group_by;",
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
                        FROM aloja_logs.SAR_net_devices $where AND IFACE not IN ('') $group_by;",
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
                                            FROM aloja_logs.SAR_net_devices $where AND IFACE not IN ('') $group_by;",
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
                                            FROM aloja_logs.SAR_net_devices $where AND IFACE not IN ('') $group_by;",
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
                                                    FROM aloja_logs.SAR_net_sockets $where $group_by;",
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
                                                                FROM aloja_logs.SAR_net_errors $where $group_by;",
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
                                                                                FROM aloja_logs.BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
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
                                                                                            FROM aloja_logs.BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
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
                                            FROM aloja_logs.BWM2 $where_BWM AND iface_name = 'total' $group_by_BWM;",
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
            if(empty($execs))
                $this->container->getTwig()->addGlobal('message',"No results for query!\n");
            else
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

        return $this->render('perfDetailsViews/perfcharts.html.twig',
            array(
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
        return $this->render('perfDetailsViews/metrics.html.twig',
            array(
                'theaders' => $show_in_result_metrics,
                'title' => 'Hadoop Performance Counters',
                'type' => $type ? $type : 'CPU',
                'discreteOptions' => $discreteOptions
            ));
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
                FROM aloja_logs.JOB_tasks t
                JOIN aloja2.execs e USING (id_exec)
                WHERE e.perf_details = 1
                #ORDER BY t.JOBID DESC
                LIMIT 100
            ;';
            $jobid = $db->get_rows($query)[rand(0,count($jobid))]['JOBID'];
        }

        echo $this->container->getTwig()->render('perfDetailsViews/dbscan.html.twig',
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
        $this->buildFilters(array('perf_details' => array('default' => 1)));
        $whereClause = $this->filters->getWhereClause(array('execs' => 'e', 'clusters' => 'c'));

        $jobid = Utils::get_GET_string("jobid");

        // if no job requested, show a random one
        if (strlen($jobid) == 0 || $jobid === "random") {
            $_GET['NO_CACHE'] = 1;  // Disable cache, otherwise random will not work
            $db = $this->container->getDBUtils();
            $query = "
                SELECT DISTINCT(t.JOBID)
                FROM aloja_logs.JOB_tasks t JOIN aloja2.execs e USING (id_exec)
                JOIN aloja2.clusters c USING (id_cluster)
                LEFT JOIN aloja_ml.predictions p USING (id_exec)
                WHERE 1=1 $whereClause
                LIMIT 100
            ;";
            $jobid = $db->get_rows($query)[rand(0,9)]['JOBID'];
        }

        list($bench, $job_offset, $id_exec) = $this->container->getDBUtils()->get_jobid_info($jobid);

        echo $this->render('perfDetailsViews/dbscanexecs.html.twig',
            array(
                'highcharts_js' => HighCharts::getHeader(),
                'jobid' => $jobid,
                'bench' => $bench,
                'job_offset' => $job_offset,
                'METRICS' => DBUtils::$TASK_METRICS,
            )
        );
    }

    public function histogramAction()
    {
        $idExec = '';
        $dbConn = $this->getContainer()->getDBUtils();
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec) {
                $idExec = $dbConn->get_rows("SELECT id_exec FROM aloja2.execs WHERE perf_details = 1 AND valid = 1 AND filter = 0 AND hadoop_version != 2 LIMIT 5")[rand(0,5)]['id_exec'];
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        if(!$idExec) {
            $this->container->getTwig()->addGlobal('message','No executions with performance details available');
            $exec = null;
        } else
            $exec = $dbConn->get_rows("SELECT * FROM aloja2.execs JOIN aloja2.clusters USING (id_cluster) WHERE id_exec = $idExec")[0];

        return $this->render('perfDetailsViews/histogram.html.twig',
            array(
                'idExec' => $idExec,
                'exec' => $exec
            ));
    }

    public function histogramHDIAction()
    {
        $idExec = '';
        $dbConn = $this->getContainer()->getDBUtils();
        try {
            $idExec = Utils::get_GET_string('id_exec');
            if(!$idExec)
                $idExec = @$dbConn->get_rows("SELECT id_exec FROM aloja2.execs WHERE perf_details = 1 AND valid = 1 AND filter = 0 AND hadoop_version = 2 LIMIT 5")[rand(0,5)]['id_exec'];
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        if(!$idExec) {
            $this->container->getTwig()->addGlobal('message','No executions of Hadoop 2 with performance details available');
            $exec = null;
        } else
            $exec = $dbConn->get_rows("SELECT * FROM aloja2.execs JOIN aloja2.clusters USING (id_cluster) WHERE id_exec = $idExec")[0];

        return $this->render('perfDetailsViews/histogramhdi.html.twig',
            array('idExec' => $idExec,
                'exec' => $exec
            ));
    }
}
