<?php

namespace alojaweb\Controller;

use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use alojaweb\inc\dbscan\DBSCAN;
use alojaweb\inc\dbscan\Cluster;
use alojaweb\inc\dbscan\Point;

class RestController extends AbstractController
{
    public function benchExecutionsDataAction()
    {
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
            'run_num' => 'Run. Num.',
            'iofilebuf' => 'IO FBuf',
            'comp' => 'Comp',
            'blk_size' => 'Blk size',
            'id_cluster' => 'Cluster',
            'vm_OS' => 'OS',
            'cdesc' => 'Cluster description',
        	'datanodes' => 'Datanodes',
            'exec_type' => 'Type',
            'prv' => 'PARAVER',
            'init_time' => 'End time',
        	'hadoop_version' => 'H Version',
            'bench_type' => 'Bench',
            'counters' => 'Counters',
            'perf_details' => 'Perf details',
        );

        try {
            $dbUtils = $this->container->getDBUtils();
            $this->buildFilters(array(
                'bench_type' => array('default' => null),
                'bench' => array('default' => null)
            ));
            $whereClause = $this->filters->getWhereClause();

            $type = Utils::get_GET_string('pageTab');
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
            			'init_time' => 'End time',
            			'hadoop_version' => 'H Version',
            			'bench_type' => 'Bench',
                    'perf_details' => 'Perf details',

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
            			'init_time' => 'End time',
            			'hadoop_version' => 'H Version',
            			'bench_type' => 'Bench',
                    'perf_details' => 'Perf details',

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
                    'run_num' => 'Run. Num.',
					'iofilebuf' => 'IO FBuf',
					'comp' => 'Comp',
					'blk_size' => 'Blk size',
					'id_cluster' => 'Cluster',
                    'vm_OS' => 'OS',
                    'cdesc' => 'Cluster description',
					'datanodes' => 'Datanodes',
					'prv' => 'PARAVER',
					'init_time' => 'End time',
                    'hadoop_version' => 'H Version',
					'bench_type' => 'Bench',
                    'perf_details' => 'Perf details',

                );
            }
            $whereClause = str_replace('%2F','/',$whereClause);
            
            $query = "SELECT e.id_exec,e.id_cluster,e.exec,e.bench,e.exe_time,e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,e.run_num,
                e.valid,e.filter,e.outlier,e.perf_details,e.exec_type,e.datasize,e.scale_factor,
                (e.exe_time/3600)*(c.cost_hour) as cost, c.name cluster_name, c.vm_OS, CONCAT_WS(',',c.vm_size,CONCAT(c.vm_RAM,' GB RAM'),c.provider,c.type) as cdesc, c.datanodes  FROM aloja2.execs e
       	 		join aloja2.clusters c USING (id_cluster)
       	 		LEFT JOIN aloja_ml.predictions p USING (id_exec)
      		 	 WHERE 1 $whereClause" .DBUtils::getFilterExecs()." ORDER BY e.id_exec DESC";

            $queryPredicted = "SELECT e.id_exec,e.id_cluster,e.exec,CONCAT('pred_',e.bench) AS bench,e.exe_time,e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
                e.valid,e.filter,e.outlier,'null' as 'perf_details','null' as 'exec_type','null' as 'datasize','null' as 'scale_factor', (e.exe_time/3600)*(c.cost_hour) as cost, c.name cluster_name, c.vm_OS, CONCAT_WS(',',c.vm_size,CONCAT(c.vm_RAM,' GB RAM'),c.provider,c.type) as cdesc, c.datanodes  FROM aloja_ml.predictions e
       	 		join aloja2.clusters c USING (id_cluster)
      		 	 WHERE 1 ".$this->filters->getWhereClause(array('ml_predictions' => 'e')) .DBUtils::getFilterExecs()." ORDER BY e.id_exec DESC";

            $params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));

            //get configs first (categories)
            if ($params['uobsr'] == 1 && $params['upred'] == 1)
                $query = "($query) UNION ($queryPredicted)";
            else if ($params['uobsr'] == 0 && $params['upred'] == 1)
                $query = "$queryPredicted";

             $exec_rows = $dbUtils->get_rows($query);

            if (count($exec_rows) > 0) {
                $jsonData = Utils::generateJSONTable($exec_rows, $show_in_result);
            } else {
                throw new \Exception("No results for query!");
            }

            header('Content-Type: application/json');
            ob_start('ob_gzhandler');
            echo json_encode(array('aaData' => $jsonData));
        } catch (\Exception $e) {
            exit($e->getMessage());
            echo 'No data available';
        }
    }

    public function countersDataAction()
    {
        $db = $this->container->getDBUtils();
        $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
        $whereClause = $this->filters->getWhereClause();
        try {
            //check the URL
            $execs = Utils::get_GET_intArray('execs');

            if (!($type = Utils::get_GET_string('pageTab')))
                $type = 'SUMMARY';

            $join = "JOIN aloja2.execs e using (id_exec) JOIN aloja2.clusters c2 USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.valid = 1 AND JOBNAME NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links') $whereClause".
                ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':''). " LIMIT 10000";

            if ($type == 'SUMMARY') {
                $query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES, c.JOBNAME as CHARTS,
                e.perf_details
                FROM aloja2.JOB_details c $join";
            } elseif ($type == 'MAP') {
                $query = "SELECT e.bench, e.exe_time, c.id_exec, JOBID, JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, `Launched map tasks`,
                `Data-local map tasks`,
                `Rack-local map tasks`,
                `Spilled Records`,
                `Map input records`,
                `Map output records`,
                `Map input bytes`,
                `Map output bytes`,
                `Map output materialized bytes`,
                e.perf_details
                FROM aloja2.JOB_details c $join";
            } elseif ($type == 'REDUCE') {
                $query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME, c.TOTAL_REDUCES, c.FAILED_REDUCES,
                `Launched reduce tasks`,
                `Reduce input groups`,
                `Reduce input records`,
                `Reduce output records`,
                `Reduce shuffle bytes`,
                `Combine input records`,
                `Combine output records`,
                e.perf_details
                FROM aloja2.JOB_details c $join";
            } elseif ($type == 'FILE-IO') {
                $query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOBID, c.JOBNAME, c.SUBMIT_TIME, c.LAUNCH_TIME,
                c.FINISH_TIME,
                `SLOTS_MILLIS_MAPS`,
                `SLOTS_MILLIS_REDUCES`,
                `SPLIT_RAW_BYTES`,
                `FILE_BYTES_WRITTEN`,
                `FILE_BYTES_READ`,
                `HDFS_BYTES_WRITTEN`,
                `HDFS_BYTES_READ`,
                `Bytes Read`,
                `Bytes Written`,
                e.perf_details
                FROM aloja2.JOB_details c $join";
            } elseif ($type == 'DETAIL') {
                $query = "SELECT e.bench, e.exe_time, c.*, e.perf_details
                FROM aloja2.JOB_details c $join";
            } elseif ($type == 'TASKS') {
                $query = "SELECT e.bench, e.exe_time, j.JOBNAME, c.*,e.perf_details FROM aloja_logs.JOB_tasks c
                JOIN aloja2.JOB_details j USING(id_exec, JOBID) $join ";
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
                $jsonData = Utils::generateJSONTable($exec_rows, $show_in_result_counters, 0, 'COUNTER');

                header('Content-Type: application/json');
                echo json_encode(array('aaData' => $jsonData));
                //         if (count($exec_rows) > 10000) {
                //             $message .= 'WARNING, large resulset, please limit the query! Rows: '.count($exec_rows);
                //         }

            } else {
                echo 'No data available';
            }

        } catch (Exception $e) {
            echo 'No data available';
           /* $noData = array();
            for($i = 0; $i<=sizeof($show_in_result); ++$i)
            	$noData[] = 'error';
            
            echo json_encode(array('aaData' => array($noData)));*/
        }
    }

    public function export2prvAction()
    {
        //ini_set('memory_limit', '256M');
        error_reporting(512);

        try {
            $dbUtils = $this->container->getDBUtils();
            if (Utils::get_GET_int('id_exec')) {
                $id_exec = Utils::get_GET_string('id_exec');
            } else {
                throw new \Exception('id_execution not set!');
            }

            $exec_name = $dbUtils->get_exec_details($id_exec, 'exec');
            $exec_name = str_replace('/', '_', $exec_name);

            $dir = 'cache/prv';
            $zip_file = "$exec_name.zip";

            $full_name = "$dir/$zip_file";

            //check if it needs to be created
            if (true ) {  //Caching of file disabled !(file_exists($full_name) && is_readable($full_name) && file_exists($full_name))) {

                $query = 'SELECT
                        unix_timestamp(min(date)) ts
                        FROM aloja_logs.SAR_cpu t 
                        WHERE id_exec = "'.$id_exec.'"
                        order by ts asc
                        limit 1;';

                $AOP4Hadoop_initial_time_1 = $dbUtils->get_rows($query);

                $query = 'SELECT
                        unix_timestamp(min(date)) ts
                        FROM aloja_logs.SAR_cpu t 
                        WHERE id_exec = "'.$id_exec.'"
                        order by ts desc
                        limit 1;';

                $AOP4Hadoop_final_time_1 = $dbUtils->get_rows($query);

                $query = 'SELECT
                        timestamp
                        From aloja_logs.AOP4Hadoopv2 s
                        where id_exec = "'.$id_exec.'"
                        order by timestamp asc
                        limit 1;';

                $AOP4Hadoop_initial_time_2 = $dbUtils->get_rows($query);

                $query = 'SELECT
                        timestamp
                        From aloja_logs.AOP4Hadoopv2 s
                        where id_exec = "'.$id_exec.'"
                        order by timestamp desc
                        limit 1;';

                $AOP4Hadoop_final_time_2 = $dbUtils->get_rows($query);


                if (!isset($AOP4Hadoop_initial_time_1)) throw new \Exception('No data returned!');
                if (!isset($AOP4Hadoop_initial_time_2)) throw new \Exception('No data returned!');
                

                #throw new \Exception('Initial time 1: '.($AOP4Hadoop_initial_time_1[0]['ts']*1000).', Initial time 2: '.($AOP4Hadoop_initial_time_2[0]['timestamp']));
                
                $initial_time = min(($AOP4Hadoop_initial_time_1[0]['ts']*1000), ($AOP4Hadoop_initial_time_2[0]['timestamp']));
                $final_time = max(($AOP4Hadoop_final_time_1[0]['ts']*1000), ($AOP4Hadoop_final_time_2[0]['timestamp'])) - $initial_time;
                
                #throw new \Exception('Initial time: '.$initial_time.', final time: '.$final_time);

                #   2:cpu:app:task:thread:time:type:value
                $query = 'SELECT 
                        concat(
                        "2:",
                        (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                        ":2:",
                        PID,
                        ":1:",
                        s.timestamp - '.$initial_time.',":",event,":",value
                        ) as record,
                        s.timestamp - '.$initial_time.' 
                    From aloja_logs.AOP4Hadoopv2 s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host_name
                    where id_exec = "'.$id_exec.'" and event != 11112
                    order by timestamp asc;';
        		$AOP4Hadoop_daemon_rows = $dbUtils->get_rows($query);

                $query = 'SELECT 
                        concat(
                        "2:",
                        (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                        ":3:",
                        PID,
                        ":1:",
                        s.timestamp - '.$initial_time.',":",event,":",value
                        ) as record,
                        s.timestamp - '.$initial_time.' 
                    From aloja_logs.AOP4Hadoopv2 s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host_name
                    where id_exec = "'.$id_exec.'" and (event = 11112 and value != 1)
                    order by timestamp asc;';
                $AOP4Hadoop_task_rows = $dbUtils->get_rows($query);


                $query = 'SELECT 
                        distinct s.host_name,
                        (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1) as task_id,
                        PID
                    From aloja_logs.AOP4Hadoopv2 s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host_name
                    where id_exec = "'.$id_exec.'" and s.event = 11111;';

                $AOP4Hadoop_jt_ids = $dbUtils->get_rows($query);


                $query = 'SELECT 
                        distinct 
                            concat(
                                "tracker_",
                                substring(value, position("tracker" in value)+8, LENGTH(s.host_name)),
                                "-.*$"
                            ) as tracker_name,
                            (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )) as task_id
                        From aloja_logs.AOP4Hadoopv2 s
                        JOIN aloja2.execs e USING(id_exec) 
                        JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = substring(value, position("tracker" in value)+8, LENGTH(s.host_name))
                        where id_exec = "'.$id_exec.'" and s.event = 11119;';


                $AOP4Hadoop_tt_ids = $dbUtils->get_rows($query);
                
                $dbUtils->executeQuery('SET @a:=0;');
                $query = 'SELECT @a:=@a+1 task_id, output.*
                        FROM (
                            select distinct PID, (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1) as host_id
                             from aloja_logs.AOP4Hadoopv2 s
                             JOIN aloja2.execs e USING(id_exec)
                             JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host_name
                             where id_exec="'.$id_exec.'" and event=11112 and s.value != 1
                        ) output;';

                $AOP4Hadoop_task_ids = $dbUtils->get_rows($query);

                //2:cpu:app:task:thread:time:type:value
                $query = 'SELECT
                    concat(
                    "2:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (unix_timestamp(date)*1000 - "'.$initial_time.'"),
                    ":2001:",`%user`,
                    ":2002:",`%system`,
                    ":2003:",`%steal`,
                    ":2004:",`%iowait`,
                    ":2005:",`%nice`
                    ) prv
                    FROM aloja_logs.SAR_cpu s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host
                    WHERE id_exec = "'.$id_exec.'"
                    ORDER by date, host;';

                $prv_cpu_rows = $dbUtils->get_rows($query);
                if (!isset($prv_cpu_rows)) throw new \Exception('No data returned for prv_cpu_rows!');


                $query = 'SELECT
                    concat(
                    "2:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (unix_timestamp(date)*1000 - "'.$initial_time.'"),
                    ":3001:", `ldavg-1`,
                    ":3002:", `ldavg-5`,
                    ":3003:", `ldavg-15`
                    ) prv
                    FROM aloja_logs.SAR_load s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host
                    WHERE id_exec = "'.$id_exec.'"
                    ORDER by date, host;';

                $prv_load_rows = $dbUtils->get_rows($query);
                if (!isset($prv_load_rows)) throw new \Exception('No data returned for prv_load_rows!');

                $query = 'SELECT
                    concat(
                    "2:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (unix_timestamp(date)*1000 - "'.$initial_time.'"),
                    ":4001:", kbmemused,
                    ":4002:", kbmemfree
                    ) prv
                    FROM aloja_logs.SAR_memory_util s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host
                    WHERE id_exec = "'.$id_exec.'"
                    ORDER by date, host;';

                $prv_mem_rows = $dbUtils->get_rows($query);
                if (!isset($prv_mem_rows)) throw new \Exception('No data returned for prv_mem_rows!');

                $query = 'SELECT
                    concat(
                    "2:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (cast(substring(id_host,(LENGTH(e.id_cluster)+1)) AS UNSIGNED )+1),
                    ":1:",
                    (unix_timestamp(date)*1000 - "'.$initial_time.'"),
                    ":5001:", `fault/s`,
                    ":5002:", `majflt/s`,
                    ":5003:", `pgfree/s`
                    ) prv
                    FROM aloja_logs.SAR_io_paging s
                    JOIN aloja2.execs e USING(id_exec)
                    JOIN aloja2.hosts h ON e.id_cluster = h.id_cluster and h.host_name = s.host
                    WHERE id_exec = "'.$id_exec.'"
                    ORDER by date, host;';

                $prv_pg_fault_rows = $dbUtils->get_rows($query);
                if (!isset($prv_pg_fault_rows)) throw new \Exception('No data returned for prv_pg_fault_rows!');


                /*
                #$query_job_history = 'select time, maps, reduce from JOB_job_history where id_exec = "'.$id_exec.'" ORDER by time';
                $query_job_history = 'select date, maps, reduce FROM aloja_logs.JOB_status where id_exec = "'.$id_exec.'" ORDER by date';

                $job_history_rows = $dbUtils->get_rows($query_job_history);

                //$test = "count ".count($prv_rows)." count2 ".count($job_history_rows);

                if ($job_history_rows) {
                    $key_job_history = 0;
                    $current_time = 0; //skip first second
                    foreach ($prv_rows as $key_prv_row=>$prv_row) {
                        $parts = explode(':', $prv_row['prv']);

                        //only one time per time and group of hosts
                        if (!$current_time || $parts[5] != $current_time) {
                            $current_time = $parts[5];
                            if (isset($job_history_rows[$key_job_history])) {
                                $prv_rows[$key_prv_row]['prv'] =
                                $prv_rows[$key_prv_row]['prv'].
                                ":1001:".round($job_history_rows[$key_job_history]['maps']).
                                ":1002:".round($job_history_rows[$key_job_history]['reduce'])
                                ;
                            }
                            $key_job_history++;
                        }
                    }
                }*/

                $query = 'SELECT
                    concat(
                    "2:0:3:1:1:",
                    (unix_timestamp(date)*1000 - "'.$initial_time.'"),
                    ":1001:", `maps`,
                    ":1002:", `reduce`,
                    ":1003:", `shuffle`,
                    ":1004:", `merge`,
                    ":1005:", `waste`
                    ) prv
                    FROM aloja_logs.JOB_status s
                    WHERE id_exec = "'.$id_exec.'"
                    ORDER by date;';
                $prv_job_history = $dbUtils->get_rows($query);
                if (!isset($prv_job_history)) throw new \Exception('No data returned for prv_job_history!');

/* 4 apps (1 CPU system / 1 hadoop daemons / Hadoop Tasks / 1 Net devices / 1 IO devices ), poner datos por CPU solo en la app de CPU system. 
   Todo el resto lo mapeamos a CPU 0.
*/

                $NUM_PRV_APPS=5;
                //create the Row file according to the cluster size
                $query = 'SELECT id_host, host_name, role
                            FROM aloja2.execs e
                            JOIN aloja2.hosts h USING(id_cluster)
                            WHERE id_exec = "'.$id_exec.'" and id_host != id_cluster order by role;';
                $hosts_rows = $dbUtils->get_rows($query);
                if (!isset($hosts_rows)) throw new \Exception('No data returned to create the Row file!');

                $NUM_NODES = count($hosts_rows);
                
                $header = "#Paraver (".date('d/m/y \a\t H:i')."):".$final_time.":$NUM_NODES(";
                for ($node_number = 1; $node_number < ($NUM_NODES+1); $node_number++) {
                    $header .= "1,"; # IMPROVE: We should have per CPU stats!
                }
                $header = substr($header,0,-1); //remove trailing ,

                $header .= "):$NUM_PRV_APPS";


                //APP1 -> System STATS
                $header .= ":$NUM_NODES(";
                for ($node_number = 1; $node_number < ($NUM_NODES+1); $node_number++) {
                    $header .= "1:$node_number,";
                }
                $header = substr($header,0,-1); //remove trailing ,
                $header .= ")";

                //APP2 -> Hadoop Daemons
                $DAEMONS_COUNT=($NUM_NODES*2);
                $header .= ":$DAEMONS_COUNT(";
                $current_daemon = 0;
                for ($daemon_number = 1; $daemon_number < ($DAEMONS_COUNT+1); $daemon_number++) {
                    $current_daemon += $daemon_number%2;
                    $header .= "1:".($current_daemon).",";
                }
                $header = substr($header,0,-1); //remove trailing ,
                $header .= ")";


                //APP3 -> Hadoop Tasks
                $TASK_COUNT=count($AOP4Hadoop_task_ids);
                $header .= ":$TASK_COUNT(";
                /*for ($task_number = 1; $task_number < ($TASK_COUNT+1); $task_number++) {
                    $header .= "1:1,";
                }*/
                foreach ($AOP4Hadoop_task_ids as $AOP4Hadoop_task_id) {
                    $header .= $AOP4Hadoop_task_id['task_id'].":".$AOP4Hadoop_task_id['host_id'].",";
                }
                $header = substr($header,0,-1); //remove trailing ,
                $header .= ")";            

                //APP4 -> NET devices
                $header .= ":$NUM_NODES(";
                for ($node_number = 1; $node_number < ($NUM_NODES+1); $node_number++) {
                    $header .= "1:$node_number,";
                }
                $header = substr($header,0,-1); //remove trailing ,
                $header .= ")";

                //APP5-> IO devices
                $header .= ":$NUM_NODES(";
                for ($node_number = 1; $node_number < ($NUM_NODES+1); $node_number++) {
                    $header .= "1:$node_number,";
                }
                $header = substr($header,0,-1); //remove trailing ,
                $header .= ")";



                $row_file = "LEVEL CPU SIZE $row_size";
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    $row_file .= "\nCPU_{$prv_row['role']}_{$prv_row['host_name']}";
                }

                $row_file .= "\n\nLEVEL APPL SIZE $NUM_PRV_APPS
SYSTEM STATS
HADOOP DAEMONS
HADOOP TASKS
NET_DEVICES
IO_DEVICES

TASK LEVEL SIZE ".($NUM_NODES*3 + $TASK_COUNT + $DAEMONS_COUNT);

                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nSTATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nSTATS_SLAVE_{$prv_row['host_name']}";
                    }
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nJT_{$prv_row['host_name']}";
                        $row_file .="\nNN_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nTT_{$prv_row['host_name']}";
                        $row_file .="\nDN_{$prv_row['host_name']}";
                    }
                }

                foreach($AOP4Hadoop_task_ids as $key_prv_row=>$prv_row) {                    
                        $row_file .="\nMR_TASK_{$prv_row['task_id']}";
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nNET_STATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nNET_STATS_SLAVE_{$prv_row['host_name']}";
                    }
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nIO_STATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nIO_STATS_SLAVE_{$prv_row['host_name']}";
                    }
                }





                $row_file .= "\n\nLEVEL NODE SIZE $NUM_NODES";

                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    $row_file .="\n".strtoupper($prv_row['role'])."_{$prv_row['host_name']}";
                }

                $row_file .="\n\nLEVEL THREAD SIZE ".($NUM_NODES*3 + $TASK_COUNT + $DAEMONS_COUNT);
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nSTATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nSTATS_SLAVE_{$prv_row['host_name']}";
                    }
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nJT_{$prv_row['host_name']}";
                        $row_file .="\nNN_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nTT_{$prv_row['host_name']}";
                        $row_file .="\nDN_{$prv_row['host_name']}";
                    }
                }


                foreach($AOP4Hadoop_task_ids as $key_prv_row=>$prv_row) {                    
                        $row_file .="\nMR_TASK_{$prv_row['task_id']}";
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nNET_STATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nNET_STATS_SLAVE_{$prv_row['host_name']}";
                    }
                }
                foreach($hosts_rows as $key_prv_row=>$prv_row) {
                    if ($prv_row['role'] == 'master') {
                        $row_file .="\nIO_STATS_MASTER_{$prv_row['host_name']}";
                    } else {
                        $row_file .="\nIO_STATS_SLAVE_{$prv_row['host_name']}";
                    }
                }



                $pcf_file =
                'DEFAULT_OPTIONS

LEVEL               NODE
UNITS               NANOSEC
LOOK_BACK           100
SPEED               1
FLAG_ICONS          ENABLED
NUM_OF_STATE_COLORS 1000
YMAX_SCALE          37


DEFAULT_SEMANTIC

THREAD_FUNC          State As Is


STATES
0    Idle
1    Running
2    Not created
3    Waiting a message
4    Blocking Send
5    Synchronization
6    Test/Probe
7    Scheduling and Fork/Join
8    Wait/WaitAll
9    Blocked
10    Immediate Send
11    Immediate Receive
12    I/O
13    Group Communication
14    Tracing Disabled
15    Others
16    Send Receive
17    Memory transfer

STATES_COLOR
0    {117,195,255}
1    {0,0,255}
2    {255,255,255}
3    {255,0,0}
4    {255,0,174}
5    {179,0,0}
6    {0,255,0}
7    {255,255,0}
8    {235,0,0}
9    {0,162,0}
10    {255,0,255}
11    {100,100,177}
12    {172,174,41}
13    {255,144,26}
14    {2,255,177}
15    {192,224,0}
16    {66,66,66}
17    {255,0,96}

EVENT_TYPE
6   1001        Number of running Map Tasks
6   1002        Number of running Reduce Tasks
6   1003        Number of running Shuffle Tasks
6   1004        Number of running Merge Tasks
6   1005        Number of running Waste Tasks

EVENT_TYPE
6   2001        CPU Usage - User (%)
6   2002        CPU Usage - System (%)
6   2003        CPU Usage - Steal (%)
6   2004        CPU Usage - IOwait (%)
6   2005        CPU Usage - Nice (%)

EVENT_TYPE
6   3001        System Load Avg-1min
6   3002        System Load Avg-5min
6   3003        System Load Avg-15min

EVENT_TYPE
6   4001        Mem KB used
6   4002        Mem KB free

EVENT_TYPE
6   5001        Page faults per second
6   5002        Major Page faults per second
6   5003        Pages freed per second

EVENT_TYPE
0 11111 JobTracker
VALUES
0 End
1 Start

EVENT_TYPE
0 11112 TaskTracker
VALUES
0 End
1 Start
8 RunMapper
9 RunReducer
10 ReducerCopyPhase
11 ReducerSortPhase
12 ReducerReducePhase

EVENT_TYPE
0 11113 NameNode
VALUES
0 End
1 Start

EVENT_TYPE
0 11114 SecondaryNameNode
VALUES
0 End
1 Start

EVENT_TYPE
0 11115 DataNode
VALUES
0 End
1 Start

EVENT_TYPE
0 11119 HeartBeat

EVENT_TYPE
0 33333 MapOutputBuffer
VALUES
0 End
1 Flush
2 SortAndSpill
3 Sort
4 Combine
5 CreateSpillIndexFile
6 TotalIndexCacheMemory
7 SpillRecordDumped

EVENT_TYPE
0 44444 MapTaskOutputSize

GRADIENT_COLOR
0    {0,255,2}
1    {0,244,13}
2    {0,232,25}
3    {0,220,37}
4    {0,209,48}
5    {0,197,60}
6    {0,185,72}
7    {0,173,84}
8    {0,162,95}
9    {0,150,107}
10    {0,138,119}
11    {0,127,130}
12    {0,115,142}
13    {0,103,154}
14    {0,91,166}


GRADIENT_NAMES
0    Gradient 0
1    Grad. 1/MPI Events
2    Grad. 2/OMP Events
3    Grad. 3/OMP locks
4    Grad. 4/User func
5    Grad. 5/User Events
6    Grad. 6/General Events
7    Grad. 7/Hardware Counters
8    Gradient 8
9    Gradient 9
10    Gradient 10
11    Gradient 11
12    Gradient 12
13    Gradient 13
14    Gradient 14


EVENT_TYPE
9    40000018    Tracing mode:
VALUES
1      Detailed
2      CPU Bursts';

                $prv_file = $header."\n";
                foreach ($prv_cpu_rows as $prv_row) {
                    $prv_file .= $prv_row['prv']."\n";
                }
                foreach ($prv_mem_rows as $prv_row) {
                    $prv_file .= $prv_row['prv']."\n";
                }
                foreach ($prv_load_rows as $prv_row) {
                    $prv_file .= $prv_row['prv']."\n";
                }
                foreach ($prv_pg_fault_rows as $prv_row) {
                    $prv_file .= $prv_row['prv']."\n";
                }
                foreach ($prv_job_history as $prv_row) {
                    $prv_file .= $prv_row['prv']."\n";
                }

                foreach ($AOP4Hadoop_daemon_rows as $AOP4Hadoop_row) {
                    $prv_file .= $AOP4Hadoop_row['record']."\n";
                }

                foreach ($AOP4Hadoop_task_rows as $AOP4Hadoop_row) {
                    $prv_file .= $AOP4Hadoop_row['record']."\n";
                }

                foreach ($AOP4Hadoop_jt_ids as $AOP4Hadoop_jt_id) {
                    $aop4h_jt_ids_file .= ":".$AOP4Hadoop_jt_id['PID'].":/:".$AOP4Hadoop_jt_id['task_id'].":\n";
                }

                foreach ($AOP4Hadoop_tt_ids as $AOP4Hadoop_tt_id) {
                    $aop4h_tt_ids_file .= ":".$AOP4Hadoop_tt_id['tracker_name']."/:".$AOP4Hadoop_tt_id['task_id']."\n";
                }

                
                foreach ($AOP4Hadoop_task_ids as $AOP4Hadoop_task_id) {
                    $aop4h_task_ids_file .= ":".$AOP4Hadoop_task_id['PID'].":/:".$AOP4Hadoop_task_id['task_id'].":\n";
                }

                $replace_file='foo=`sh replace_string.sh`
#echo $foo
eval $foo';

                $replace_string_file='echo -n "cat '.$exec_name.'.tmp.prv |  tail -n +2 | sort -t \":\" -k 6n | perl"
for line in `cat *.tmp.tt.ids`
do
    echo -n " -pe \"s/$line/g;\""
done
for line in `cat *.tmp.jt.ids`
do
    echo -n " -pe \"s/$line/g;\""
done
for line in `cat *.tmp.task.ids`
do
    echo -n " -pe \"s/$line/g;\""
done
echo';

                //create the file
                if (!is_dir("$dir/$exec_name/")) {
                    mkdir("$dir/$exec_name/", 0777, true);
                }
                $prv_tmp_filename="$exec_name.tmp.prv";
                $prv_filename="$exec_name.prv";
                $replace_filename="replace.sh";
                file_put_contents($dir."/$exec_name/$exec_name.pcf", $pcf_file);
                file_put_contents($dir."/$exec_name/$exec_name.row", $row_file);
                file_put_contents($dir."/$exec_name/$prv_tmp_filename", $prv_file);
                file_put_contents($dir."/$exec_name/$exec_name.tmp.jt.ids", $aop4h_jt_ids_file);
                file_put_contents($dir."/$exec_name/$exec_name.tmp.tt.ids", $aop4h_tt_ids_file);
                file_put_contents($dir."/$exec_name/$exec_name.tmp.task.ids", $aop4h_task_ids_file);
                file_put_contents($dir."/$exec_name/replace.sh", $replace_file);
                file_put_contents($dir."/$exec_name/replace_string.sh", $replace_string_file);
                //exec("cd $dir/$exec_name &&  head -1 $prv_tmp_filename > $prv_filename && sh replace.sh >> $prv_filename && rm  -f *.tmp.*");
                exec("cd $dir/$exec_name &&  head -1 $prv_tmp_filename > $prv_filename && sh replace.sh >> $prv_filename");

                //if (!exec("cd $dir &&  zip -r $zip_file $exec_name && rm -rf $exec_name") || !file_exists("$dir/$zip_file")) {
                if (!exec("cd $dir &&  zip -r $zip_file $exec_name") || !file_exists("$dir/$zip_file")) {
                    throw new \Exception('Could not create .zip');
                }
            }

            //donwload the file
            if (file_exists($full_name) && is_readable($full_name) && file_exists($full_name)) {
                header("Content-Disposition: attachment; filename=".basename(str_replace(' ', '_', $full_name)));
                header("Content-Type: application/force-download");
                header("Content-Type: application/octet-stream");
                header("Content-Type: application/download");
                header("Content-Description: File Transfer");
                header("Content-Length: " . filesize($full_name));
                flush(); // this doesn't really matter.

                $fp = fopen($full_name, "r");
                while (!feof($fp)) {
                    echo fread($fp, 65536);
                    flush(); // this is essential for large downloads
                }
                fclose($fp);
                exit;
            } else {
                throw new \Exception('Could not read zip file');
            }

        } catch (\Exception $e) {
            die('Unexpected error: '.$e->getMessage());
            $message .= $e->getMessage()."\n";
            echo $message;
            exit;
        }
    }
    
    public function metricsDataAction()
    {
        $show_in_result_metrics = array();
        $query = '';
        $dbUtil = $this->container->getDBUtils();
        $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
        $whereClause = $this->filters->getWhereClause();
        
        try {
            $type = Utils::get_GET_string('pageTab');
            $filter_execs = DBUtils::getFilterExecs();
            if(!$type || $type == 'CPU') {

                $insertInto = "
                INSERT INTO aloja2.precal_cpu_metrics(id_exec,
                `avg%user`,`max%user`,`min%user`,`stddev_pop%user`,`var_pop%user`,
                `avg%nice`,`max%nice`,`min%nice`,`stddev_pop%nice`,`var_pop%nice`,
                `avg%system`,`max%system`,`min%system`,`stddev_pop%system`,`var_pop%system`,
                `avg%iowait`,`max%iowait`,`min%iowait`,`stddev_pop%iowait`,`var_pop%iowait`,
                `avg%steal`,`max%steal`,`min%steal`,`stddev_pop%steal`,`var_pop%steal`,
                `avg%idle`,`max%idle`,`min%idle`,`stddev_pop%idle`,`var_pop%idle`)
                 SELECT e.id_exec,
                 AVG(s.`%user`), MAX(s.`%user`), MIN(s.`%user`), STDDEV_POP(s.`%user`), VAR_POP(s.`%user`),
                 AVG(s.`%nice`), MAX(s.`%nice`), MIN(s.`%nice`), STDDEV_POP(s.`%nice`), VAR_POP(s.`%nice`),
                 AVG(s.`%system`), MAX(s.`%system`), MIN(s.`%system`), STDDEV_POP(s.`%system`), VAR_POP(s.`%system`),
                 AVG(s.`%iowait`), MAX(s.`%iowait`), MIN(s.`%iowait`), STDDEV_POP(s.`%iowait`), VAR_POP(s.`%iowait`),
                 AVG(s.`%steal`), MAX(s.`%steal`), MIN(s.`%steal`), STDDEV_POP(s.`%steal`), VAR_POP(s.`%steal`),
                 AVG(s.`%idle`), MAX(s.`%idle`), MIN(s.`%idle`), STDDEV_POP(s.`%idle`), VAR_POP(s.`%idle`)
                 FROM aloja2.execs e JOIN aloja_logs.SAR_cpu s USING (id_exec) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.id_exec NOT IN (SELECT id_exec FROM precal_cpu_metrics) AND e.valid = 1 $filter_execs $whereClause GROUP BY (e.id_exec)
                ";
                $dbUtil->executeQuery($insertInto);

                $query = "SELECT e.id_exec, e.exec, e.bench, e.net, e.disk, e.maps, e.comp, e.replication, e.blk_size,
                s.`avg%user`,s.`max%user`, s.`min%user`, s.`stddev_pop%user`, s.`var_pop%user`,
                s.`avg%nice`,s.`max%nice`, s.`min%nice`, s.`stddev_pop%nice`, s.`var_pop%nice`,
                s.`avg%system`,s.`max%system`, s.`min%system`, s.`stddev_pop%system`, s.`var_pop%system`,
                s.`avg%iowait`,s.`max%iowait`, s.`min%iowait`, s.`stddev_pop%iowait`, s.`var_pop%iowait`,
                s.`avg%steal`,s.`max%steal`, s.`min%steal`, s.`stddev_pop%steal`, s.`var_pop%steal`,
                s.`avg%idle`,s.`max%idle`, s.`min%idle`, s.`stddev_pop%idle`, s.`var_pop%idle`,
                e.id_cluster,e.end_time,c.name cluster_name
                FROM aloja2.precal_cpu_metrics s JOIN aloja2.execs e USING (id_exec) JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause
                ";
        
            } else if($type == 'DISK') {

                $insertInto = "
                 INSERT INTO aloja2.precal_disk_metrics (id_exec,
                    DEV, avgtps, maxtps, mintps,
                    `avgrd_sec/s`,`maxrd_sec/s`,`minrd_sec/s`,`stddev_poprd_sec/s`,`var_poprd_sec/s`,`sumrd_sec/s`,
                    `avgwr_sec/s`,`maxwr_sec/s`,`minwr_sec/s`,`stddev_popwr_sec/s`,`var_popwr_sec/s`,`sumwr_sec/s`,
                    `avgrq_sz`,`maxrq_sz`,`minrq_sz`,`stddev_poprq_sz`,`var_poprq_sz`,
                    `avgqu_sz`,`maxqu_sz`,`minqu_sz`,`stddev_popqu_sz`,`var_popqu_sz`,
                    `avgawait`,`maxawait`,`minawait`,`stddev_popawait`,`var_popawait`,
                    `avg%util`,`max%util`,`min%util`,`stddev_pop%util`,`var_pop%util`,
                    `avgsvctm`,`maxsvctm`,`minsvctm`,`stddev_popsvctm`,`var_popsvctm`)
                  SELECT  e.id_exec, s.DEV,AVG(s.tps), MAX(s.tps), MIN(s.tps),
                    AVG(s.`rd_sec/s`), MAX(s.`rd_sec/s`), MIN(s.`rd_sec/s`), STDDEV_POP(s.`rd_sec/s`), VAR_POP(s.`rd_sec/s`), SUM(s.`rd_sec/s`),
                    AVG(s.`wr_sec/s`), MAX(s.`wr_sec/s`), MIN(s.`wr_sec/s`), STDDEV_POP(s.`wr_sec/s`), VAR_POP(s.`wr_sec/s`), SUM(s.`wr_sec/s`),
                    AVG(s.`avgrq-sz`), MAX(s.`avgrq-sz`), MIN(s.`avgrq-sz`), STDDEV_POP(s.`avgrq-sz`), VAR_POP(s.`avgrq-sz`),
                    AVG(s.`avgqu-sz`), MAX(s.`avgqu-sz`), MIN(s.`avgqu-sz`), STDDEV_POP(s.`avgqu-sz`), VAR_POP(s.`avgqu-sz`),
                    AVG(s.await), MAX(s.`await`), MIN(s.`await`), STDDEV_POP(s.`await`), VAR_POP(s.`await`),
                    AVG(s.`%util`), MAX(s.`%util`), MIN(s.`%util`), STDDEV_POP(s.`%util`), VAR_POP(s.`%util`),
                    AVG(s.svctm), MAX(s.`svctm`), MIN(s.`svctm`), STDDEV_POP(s.`svctm`), VAR_POP(s.`svctm`)
                    FROM aloja2.execs e JOIN  aloja_logs.SAR_block_devices s USING (id_exec) JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.id_exec NOT IN (SELECT id_exec FROM precal_disk_metrics) $filter_execs $whereClause GROUP BY (e.id_exec)
                ";

                $dbUtil->executeQuery($insertInto);

                $query = "SELECT e.id_exec, e.exec, e.bench, e.net, e.disk, e.maps, e.comp, e.replication, e.blk_size,
                    s.DEV, s.avgtps, s.maxtps, s.mintps,
                    `avgrd_sec/s`,`maxrd_sec/s`,`minrd_sec/s`,`stddev_poprd_sec/s`,`var_poprd_sec/s`,`sumrd_sec/s`,
                    `avgwr_sec/s`,`maxwr_sec/s`,`minwr_sec/s`,`stddev_popwr_sec/s`,`var_popwr_sec/s`,`sumwr_sec/s`,
                    `avgrq_sz`,`maxrq_sz`,`minrq_sz`,`stddev_poprq_sz`,`var_poprq_sz`,
                    `avgqu_sz`,`maxqu_sz`,`minqu_sz`,`stddev_popqu_sz`,`var_popqu_sz`,
                    `avgawait`,`maxawait`,`minawait`,`stddev_popawait`,`var_popawait`,
                    `avg%util`,`max%util`,`min%util`,`stddev_pop%util`,`var_pop%util`,
                    `avgsvctm`,`maxsvctm`,`minsvctm`,`stddev_popsvctm`,`var_popsvctm`,
                    e.id_cluster,e.end_time,
                    c.name cluster_name
                    FROM aloja2.precal_disk_metrics s JOIN aloja2.execs e USING (id_exec) JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause GROUP BY (e.id_exec)
                    ";
            } else if($type == 'MEMORY') {

                $insertInto = "
                    INSERT INTO aloja2.precal_memory_metrics (id_exec,
                       avgkbmemfree,maxkbmemfree,minkbmemfree,stddev_popkbmemfree,var_popkbmemfree,
                       avgkbmemused,maxkbmemused,minkbmemused,stddev_popkbmemused,var_popkbmemused,
                       `avg%memused`,`max%memused`,`min%memused`,`stddev_pop%memused`,`var_pop%memused`,
                       avgkbbuffers,maxkbbuffers,minkbbuffers,stddev_popkbbuffers,var_popkbbuffers,
                       avgkbcached,maxkbcached,minkbcached,stddev_popkbcached,var_popkbcached,
                       avgkbcommit,maxkbcommit,minkbcommit,stddev_popkbcommit,var_popkbcommit,
                       `avg%commit`,`max%commit`,`min%commit`,`stddev_pop%commit`,`var_pop%commit`,
                       avgkbactive,maxkbactive,minkbactive,stddev_popkbactive,var_popkbactive,
                       avgkbinact,maxkbinact,minkbinact,stddev_popkbinact,var_popkbinact
                       )

                     SELECT e.id_exec,
                         AVG(su.kbmemfree), MAX(su.kbmemfree), MIN(su.kbmemfree), STDDEV_POP(su.kbmemfree), VAR_POP(su.kbmemfree),
                         AVG(su.kbmemused), MAX(su.kbmemused), MIN(su.kbmemused), STDDEV_POP(su.kbmemused), VAR_POP(su.kbmemused),
                         AVG(su.`%memused`), MAX(su.`%memused`), MIN(su.`%memused`), STDDEV_POP(su.`%memused`), VAR_POP(su.`%memused`),
                         AVG(su.kbbuffers), MAX(su.kbbuffers), MIN(su.kbbuffers), STDDEV_POP(su.kbbuffers), VAR_POP(su.kbbuffers),
                         AVG(su.kbcached), MAX(su.kbcached), MIN(su.kbcached), STDDEV_POP(su.kbcached), VAR_POP(su.kbcached),
                         AVG(su.kbcommit), MAX(su.kbcommit), MIN(su.kbcommit), STDDEV_POP(su.kbcommit), VAR_POP(su.kbcommit),
                         AVG(su.`%commit`), MAX(su.`%commit`), MIN(su.`%commit`), STDDEV_POP(su.`%commit`), VAR_POP(su.`%commit`),
                         AVG(su.kbactive), MAX(su.kbactive), MIN(su.kbactive), STDDEV_POP(su.kbactive), VAR_POP(su.kbactive),
                         AVG(su.kbinact), MAX(su.kbinact), MIN(su.kbinact), STDDEV_POP(su.kbinact), VAR_POP(su.kbinact)
                    FROM aloja_logs.SAR_memory_util su
                    JOIN aloja2.execs e USING (id_exec) JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.id_exec NOT IN (SELECT id_exec FROM aloja2.precal_memory_metrics) AND 1 $filter_execs $whereClause GROUP BY (e.id_exec)";

                $dbUtil->executeQuery($insertInto);

                $query = "SELECT e.id_exec, e.exec, e.bench, e.net, e.disk, e.maps, e.comp, e.replication, e.blk_size,
                       su.avgkbmemfree,su.maxkbmemfree,su.minkbmemfree,su.stddev_popkbmemfree,su.var_popkbmemfree,
                       su.avgkbmemused,su.maxkbmemused,su.minkbmemused,su.stddev_popkbmemused,su.var_popkbmemused,
                       su.`avg%memused`,su.`max%memused`,su.`min%memused`,su.`stddev_pop%memused`,su.`var_pop%memused`,
                       su.avgkbbuffers,su.maxkbbuffers,su.minkbbuffers,su.stddev_popkbbuffers,su.var_popkbbuffers,
                       su.avgkbcached,su.maxkbcached,su.minkbcached,su.stddev_popkbcached,su.var_popkbcached,
                       su.avgkbcommit,su.maxkbcommit,su.minkbcommit,su.stddev_popkbcommit,su.var_popkbcommit,
                       su.`avg%commit`,su.`max%commit`,su.`min%commit`,su.`stddev_pop%commit`,su.`var_pop%commit`,
                       su.avgkbactive,su.maxkbactive,su.minkbactive,su.stddev_popkbactive,su.var_popkbactive,
                       su.avgkbinact,su.maxkbinact,su.minkbinact,su.stddev_popkbinact,su.var_popkbinact,
                       e.id_cluster,e.end_time, c.name cluster_name
                    FROM aloja2.execs e JOIN aloja2.precal_memory_metrics su USING (id_exec) JOIN aloja2.clusters c USING (id_cluster)
                     LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause GROUP BY (e.id_exec)";

            } else if($type == 'NETWORK') {

                $insertInto = "
                  INSERT INTO precal_network_metrics(id_exec,
                    IFACE,
                    `avgrxpck/s`,`maxrxpck/s`,`minrxpck/s`,`stddev_poprxpck/s`,`var_poprxpck/s`,`sumrxpck/s`,
                    `avgtxpck/s`,`maxtxpck/s`,`mintxpck/s`,`stddev_poptxpck/s`,`var_poptxpck/s`,`sumtxpck/s`,
                    `avgrxkB/s`,`maxrxkB/s`,`minrxkB/s`,`stddev_poprxkB/s`,`var_poprxkB/s`,`sumrxkB/s`,
                    `avgtxkB/s`,`maxtxkB/s`,`mintxkB/s`,`stddev_poptxkB/s`,`var_poptxkB/s`,`sumtxkB/s`,
                    `avgrxcmp/s`,`maxrxcmp/s`,`minrxcmp/s`,`stddev_poprxcmp/s`,`var_poprxcmp/s`,`sumrxcmp/s`,
                    `avgtxcmp/s`,`maxtxcmp/s`,`mintxcmp/s`,`stddev_poptxcmp/s`,`var_poptxcmp/s`,`sumtxcmp/s`,
                    `avgrxmcst/s`,`maxrxmcst/s`,`minrxmcst/s`,`stddev_poprxmcst/s`,`var_poprxmcst/s`,`sumrxmcst/s`
                  )
                  SELECT e.id_exec,
                    s.IFACE,AVG(s.`rxpck/s`),MAX(s.`rxpck/s`),MIN(s.`rxpck/s`),STDDEV_POP(s.`rxpck/s`),VAR_POP(s.`rxpck/s`),SUM(s.`rxpck/s`),
                    AVG(s.`txpck/s`),MAX(s.`txpck/s`),MIN(s.`txpck/s`),STDDEV_POP(s.`txpck/s`),VAR_POP(s.`txpck/s`),SUM(s.`txpck/s`),
                    AVG(s.`rxkB/s`),MAX(s.`rxkB/s`),MIN(s.`rxkB/s`),STDDEV_POP(s.`rxkB/s`),VAR_POP(s.`rxkB/s`),SUM(s.`rxkB/s`),
                    AVG(s.`txkB/s`),MAX(s.`txkB/s`),MIN(s.`txkB/s`),STDDEV_POP(s.`txkB/s`),VAR_POP(s.`txkB/s`),SUM(s.`txkB/s`),
                    AVG(s.`rxcmp/s`),MAX(s.`rxcmp/s`),MIN(s.`rxcmp/s`),STDDEV_POP(s.`rxcmp/s`),VAR_POP(s.`rxcmp/s`),SUM(s.`rxcmp/s`),
                    AVG(s.`txcmp/s`),MAX(s.`txcmp/s`),MIN(s.`txcmp/s`),STDDEV_POP(s.`txcmp/s`),VAR_POP(s.`txcmp/s`),SUM(s.`txcmp/s`),
                    AVG(s.`rxmcst/s`),MAX(s.`rxmcst/s`),MIN(s.`rxmcst/s`),STDDEV_POP(s.`rxmcst/s`),VAR_POP(s.`rxmcst/s`),SUM(s.`rxmcst/s`)
                    FROM aloja_logs.SAR_net_devices s
                    JOIN aloja2.execs e USING (id_exec) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE id_exec NOT IN (SELECT id_exec FROM precal_network_metrics) AND 1 $filter_execs $whereClause GROUP BY (e.id_exec)";

                $dbUtil->executeQuery($insertInto);
                
                $query = "SELECT e.id_exec, e.exec, e.bench, e.net, e.disk, e.maps, e.comp, e.replication, e.blk_size,
                    IFACE,
                    s.`avgrxpck/s`,s.`maxrxpck/s`,s.`minrxpck/s`,s.`stddev_poprxpck/s`,s.`var_poprxpck/s`,s.`sumrxpck/s`,
                    s.`avgtxpck/s`,s.`maxtxpck/s`,s.`mintxpck/s`,s.`stddev_poptxpck/s`,s.`var_poptxpck/s`,s.`sumtxpck/s`,
                    s.`avgrxkB/s`,s.`maxrxkB/s`,s.`minrxkB/s`,s.`stddev_poprxkB/s`,s.`var_poprxkB/s`,s.`sumrxkB/s`,
                    s.`avgtxkB/s`,s.`maxtxkB/s`,s.`mintxkB/s`,s.`stddev_poptxkB/s`,s.`var_poptxkB/s`,s.`sumtxkB/s`,
                    s.`avgrxcmp/s`,s.`maxrxcmp/s`,s.`minrxcmp/s`,s.`stddev_poprxcmp/s`,s.`var_poprxcmp/s`,s.`sumrxcmp/s`,
                    s.`avgtxcmp/s`,s.`maxtxcmp/s`,s.`mintxcmp/s`,s.`stddev_poptxcmp/s`,s.`var_poptxcmp/s`,s.`sumtxcmp/s`,
                    s.`avgrxmcst/s`,s.`maxrxmcst/s`,s.`minrxmcst/s`,s.`stddev_poprxmcst/s`,s.`var_poprxmcst/s`,s.`sumrxmcst/s`,
                    e.id_cluster,e.end_time,
                    c.name cluster_name
                    FROM aloja2.precal_network_metrics s
                    JOIN aloja2.execs e USING (id_exec) JOIN clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause GROUP BY (e.id_exec)
                    ";
            }
        
            $exec_rows = $dbUtil->get_rows($query);
            if (count($exec_rows) > 0) {          
               $show_in_result_metrics = Utils::generate_show($show_in_result_metrics,$exec_rows,0);     
               $jsonData = Utils::generateJSONTable($exec_rows, $show_in_result_metrics, 2);
            } else {
               throw new \Exception("No results for query!");
            }
        
            header('Content-Type: application/json');
            ob_start('ob_gzhandler');
            echo json_encode(array('aaData' => $jsonData));
                
        } catch (Exception $e) {
            echo 'No data available';
            /*
            $noData = array();
            $noData[] = $e->getMessage();

            echo json_encode(array('aaData' => $noData));*/
        }
    }
    
    public function histogramDataAction()
    {
		$db = $this->container->getDBUtils ();
		$execsDetails = array ();
		try {
			$idExec = Utils::get_GET_string('id_exec');
			if (!$idExec)
				throw new \Exception ( "No execution selected!" );
				
			// get the result rows
			$metric_duration = $db->get_task_metric_query("Duration");
			$query = "SELECT e.bench,j.*,".$metric_duration('j')." as Duration
			FROM aloja_logs.JOB_tasks j JOIN aloja2.execs e USING (id_exec)
			where e.valid = 1 AND j.id_exec = $idExec;";
			
			$this->getContainer ()->getLog ()->addInfo ( 'Histogram query: ' . $query );
			$rows = $db->get_rows ($query);
			if (!$rows) {
				throw new \Exception ( "No results for query!" );
			}
			
			$result = array();
			foreach ( $rows as $row ) {
				// Show only task id (not the whole string)
				$row['TASKID'] = substr($row['TASKID'], 23);

				$result[$row['JOBID'].'/'.$row['bench']]['tasks'][$row['TASKID']] = $row;
			}
			header('Content-Type: application/json');
			ob_start('ob_gzhandler');
			echo json_encode($result);
		} catch ( \Exception $e ) {
            echo 'No data available';
/*			$noData = array();
            $noData[] = $e->getMessage();

            echo json_encode(array('error' => $noData));*/
		}
    }

    public function histogramTasksDataAction()
    {
        $db = $this->container->getDBUtils();

        $jobid = Utils::get_GET_string("jobid");
        $metric = $db::$TASK_METRICS[Utils::get_GET_int("metric") ?: 0];
        $metric_select = $db->get_task_metric_query($metric);
        $task_type_select = $db->get_task_type_query(Utils::get_GET_string("task_type"));
        $group = Utils::get_GET_int("group") ?: 1;  // Group the rows in groups of this quantity
        $accumulated = Utils::get_GET_int("accumulated") ?: 0;
        $divided = Utils::get_GET_int("divided") ?: 0;

        // Accumulated and divided options don't support group
        if ($accumulated || $divided) {
            $group = 1;
        }

        if (!($group > 1)) {
            $query = "
                SELECT
                    t.`TASKID` as TASK_ID,
                    ".$metric_select('t')." as TASK_VALUE,
                    TIMESTAMPDIFF(SECOND, t.`START_TIME`, t.`FINISH_TIME`) as TASK_DURATION
                FROM aloja_logs.JOB_tasks as t
                WHERE t.`JOBID` = :jobid
                ".$task_type_select('t')."
                ORDER BY t.`TASKID`
            ;";
            $query_params = array(":jobid" => $jobid);

        } else {
            $query = "
                SELECT
                    MIN(t.`TASKID`) as TASK_ID,
                    AVG(".$metric_select('t').") as TASK_VALUE,
                    STDDEV(".$metric_select('t').") as TASK_VALUE_STDDEV,
                    t.`TASK_TYPE`,
                    CONVERT(SUBSTRING(t.`TASKID`, 26), UNSIGNED INT) DIV :group as MYDIV
                FROM aloja_logs.JOB_tasks t
                WHERE t.`JOBID` = :jobid
                ".$task_type_select('t')."
                GROUP BY MYDIV, t.`TASK_TYPE`
                ORDER BY MIN(t.`TASKID`)
            ;";
            $query_params = array(":jobid" => $jobid, ":group" => $group);
        }

        $rows = $db->get_rows($query, $query_params);

        $seriesData = array();
        $seriesError = array();
        $task_value_accum = 0;
        $task_duration_accum = 0;
        foreach ($rows as $row) {
            $task_id = $row['TASK_ID'];
            $task_value = $row['TASK_VALUE'];
            $task_value_stddev = array_key_exists('TASK_VALUE_STDDEV', $row) ? $row['TASK_VALUE_STDDEV'] : 0;
            $task_duration = array_key_exists('TASK_DURATION', $row) ? $row['TASK_DURATION'] : 0;

            // Show only task id (not the whole string)
            $task_id = substr($task_id, 23);

            if ($accumulated == 1) {
                $task_value_accum += $task_value;
                $task_value = $task_value_accum;
            }

            if ($divided == 1) {
                $task_duration_accum += $task_duration;
                $task_value = $task_value / $task_duration_accum;
            }

            $seriesData[] = array($task_id, $task_value);

            if ($group > 1) {
                $task_value_low = $task_value - $task_value_stddev;
                $task_value_high = $task_value + $task_value_stddev;

                $seriesError[] = array('low' => $task_value_low, 'high' => $task_value_high, 'stddev' => $task_value_stddev);
            }
        }

        $result = [
            'seriesData' => $seriesData,
            'seriesError' => $seriesError,
        ];

        header('Content-Type: application/json');
        ob_start('ob_gzhandler');
        echo json_encode($result, JSON_NUMERIC_CHECK);
    }
    
    public function histogramHDIDataAction()
    {
    	$db = $this->container->getDBUtils ();
    	$execsDetails = array ();
    	try {
    		$idExec = Utils::get_GET_string('id_exec');
    		if (!$idExec)
    			throw new \Exception ( "No execution selected!" );
    
    		// get the result rows
    		$metric_duration = $db->get_task_metric_query("Duration");
    		$query = "SELECT e.bench,j.*,".$metric_duration('c','LAUNCH_TIME')." as Duration
    		FROM aloja_logs.HDI_JOB_tasks j JOIN aloja2.execs e USING (id_exec)
    		JOIN HDI_JOB_details c USING (JOB_ID)
    		where e.valid = 1 AND j.id_exec = $idExec;";
    			
    		$this->getContainer ()->getLog ()->addInfo ( 'Histogram query: ' . $query );
    		$rows = $db->get_rows ($query);
    		if (!$rows) {
    			throw new \Exception ( "No results for query!" );
    		}
    			
    		$result = array();
    		foreach ( $rows as $row ) {
    			// Show only task id (not the whole string)
    			$row['TASK_ID'] = substr($row['TASK_ID'], 23);
    
    			$result[$row['JOB_ID'].'/'.$row['bench']]['tasks'][$row['TASK_ID']] = $row;
    		}
    		
    		header('Content-Type: application/json');
    		ob_start('ob_gzhandler');
    		echo json_encode($result);
    	} catch ( \Exception $e ) {
            echo 'No data available';
            /*
    		$noData = array();
    		$noData[] = $e->getMessage();
    
    		echo json_encode(array('error' => $noData));*/
    	}
    }
    
    public function histogramHDITasksDataAction()
    {
    	$db = $this->container->getDBUtils();
    
    	$jobid = Utils::get_GET_string("jobid");
    	$metric = $db::$TASK_METRICS[Utils::get_GET_int("metric") ?: 0];
    	$metric_select = $db->get_task_metric_query($metric);
    	$task_type_select = $db->get_task_type_query(Utils::get_GET_string("task_type"));
    	$group = Utils::get_GET_int("group") ?: 1;  // Group the rows in groups of this quantity
    	$accumulated = Utils::get_GET_int("accumulated") ?: 0;
    	$divided = Utils::get_GET_int("divided") ?: 0;
    
    	// Accumulated and divided options don't support group
    	if ($accumulated || $divided) {
    		$group = 1;
    	}
    
    	if (!($group > 1)) {
    		$query = "
                SELECT
                    t.`TASK_ID` as TASK_ID,
                    ".$metric_select('t','TASK_START_TIME','TASK_FINISH_TIME')." as TASK_VALUE,
                    SUM(".$metric_select('t2','TASK_START_TIME','TASK_FINISH_TIME').") as TASK_VALUE_ACCUM,
                    t.TASK_DURATION,
                    SUM(t2.`TASK_DURATION`) as TASK_DURATION_ACCUM,
                    1 as TASK_VALUE_STDDEV
                FROM (
                    SELECT *, TIMESTAMPDIFF(SECOND, `TASK_START_TIME`, `TASK_FINISH_TIME`) as TASK_DURATION
                    FROM `HDI_JOB_tasks`
                ) as t
                JOIN (
                    SELECT *, TIMESTAMPDIFF(SECOND, `TASK_START_TIME`, `TASK_FINISH_TIME`) as TASK_DURATION
                    FROM `HDI_JOB_tasks`
                ) as t2
                ON (t.`TASK_ID` >= t2.`TASK_ID` AND t2.`JOB_ID` = :jobid_repeated)
                WHERE t.`JOB_ID` = :jobid
                ".$task_type_select('t')."
                GROUP BY t.`TASK_ID`
                ORDER BY t.`TASK_ID`
            ;";
    		$query_params = array(":jobid" => $jobid, ":jobid_repeated" => $jobid);
    	} else {
    		$query = "
                SELECT
                    MIN(t.`TASK_ID`) as TASK_ID,
                    AVG(".$metric_select('t','TASK_START_TIME','TASK_FINISH_TIME').") as TASK_VALUE,
                    STDDEV(".$metric_select('t','TASK_START_TIME','TASK_FINISH_TIME').") as TASK_VALUE_STDDEV,
                    1 as TASK_VALUE_ACCUM,
                    1 as TASK_DURATION,
                    1 as TASK_DURATION_ACCUM,
                    t.`TASK_TYPE`,
                    CONVERT(SUBSTRING(t.`TASK_ID`, 26), UNSIGNED INT) DIV :group as MYDIV
                FROM `HDI_JOB_tasks` t
                WHERE t.`JOB_ID` = :jobid
                ".$task_type_select('t')."
                GROUP BY MYDIV, t.`TASK_TYPE`
                ORDER BY MIN(t.`TASK_ID`)
            ;";
    		$query_params = array(":jobid" => $jobid, ":group" => $group);
    	}
    	
    	$rows = $db->get_rows($query, $query_params);

    	$seriesData = array();
    	$seriesError = array();
    	foreach ($rows as $row) {
    		$task_id = $row['TASK_ID'];
    		$task_value = $row['TASK_VALUE'] ?: 0;
    		$task_value_accum = $row['TASK_VALUE_ACCUM'] ?: 0;
    		$task_value_stddev = $row['TASK_VALUE_STDDEV'] ?: 0;
    		$task_duration = $row['TASK_DURATION'] ?: 0;
    		$task_duration_accum = $row['TASK_DURATION_ACCUM'] ?: 0;
    
    		// Show only task id (not the whole string)
    		$task_id = substr($task_id, 23);
    
    		if ($accumulated == 1) {
    			$task_value = $task_value_accum;
    		}
    
    		if ($divided == 1) {
    			$task_value = $task_value / $task_duration_accum;
    		}
    
    		$seriesData[] = array($task_id, $task_value);
    
    		if ($group > 1) {
    			$task_value_low = $task_value - $task_value_stddev;
    			$task_value_high = $task_value + $task_value_stddev;
    
    			$seriesError[] = array('low' => $task_value_low, 'high' => $task_value_high, 'stddev' => $task_value_stddev);
    		}
    	}
    
    	$result = [
    			'seriesData' => $seriesData,
    			'seriesError' => $seriesError,
    			];
    
    	
    	header('Content-Type: application/json');
    	ob_start('ob_gzhandler');
    	echo json_encode($result, JSON_NUMERIC_CHECK);
    }

    public function bestConfigDataAction()
    {
    	$db = $this->container->getDBUtils();
    	$rows_config = '';
    	try {
    		$configurations = array();
    		$where_configs = '';
    		$concat_config = "";
    		 
    		$benchs         = Utils::read_params('benchs',$where_configs);
    		$nets           = Utils::read_params('nets',$where_configs);
    		$disks          = Utils::read_params('disks',$where_configs);
    		$blk_sizes      = Utils::read_params('blk_sizes',$where_configs);
    		$comps          = Utils::read_params('comps',$where_configs);
    		$id_clusters    = Utils::read_params('id_clusters',$where_configs);
    		$mapss          = Utils::read_params('mapss',$where_configs);
    		$replications   = Utils::read_params('replications',$where_configs);
    		$iosfs          = Utils::read_params('iosfs',$where_configs);
    		$iofilebufs     = Utils::read_params('iofilebufs',$where_configs);
    		 
    		//$concat_config = join(',\'_\',', $configurations);
    		//$concat_config = substr($concat_config, 1);
    		 
    		//make sure there are some defaults
    		if (!$concat_config) {
    			$concat_config = 'disk';
    			$disks = array('HDD');
    		}
    		 
    		$filter_execs = DBUtils::getFilterExecs();
    		$order_conf = 'LENGTH(conf), conf';
    		 
    		//get best config
    		$query = "SELECT e2.* from aloja2.execs e2 WHERE e.id_exec IN ".
    				"(SELECT MIN(e2.exe_time) FROM aloja2.execs e WHERE 1 $filter_execs $where_configs LIMIT 1);";
    		 
    		$rows = $db->get_rows($query);
    		if(!$rows)
    			throw new \Exception("No results for query!");
    		 
    	} catch (\Exception $e) {
            echo 'No data available';
            /*
    		$noData = array();
            for($i = 0; $i<=sizeof($show_in_result); ++$i)
            	$noData[] = 'error';
            
            echo json_encode(array('aaData' => array($noData)));*/
    	}
    }

    public function dbscanDataAction()
    {
        $db = $this->container->getDBUtils();

        $jobid = Utils::get_GET_string("jobid");
        $metric_x = Utils::get_GET_int("metric_x") !== null ? Utils::get_GET_int("metric_x") : 0;
        $metric_y = Utils::get_GET_int("metric_y") !== null ? Utils::get_GET_int("metric_y") : 1;
        $task_type = $db->get_task_type(Utils::get_GET_string("task_type"));
        $heuristic = Utils::get_GET_int("heuristic") !== null ? Utils::get_GET_int("heuristic") : 1;
        $eps = Utils::get_GET_float("eps") !== null ? Utils::get_GET_float("eps") : 250000;
        $minPoints = Utils::get_GET_int("minPoints") !== null ? Utils::get_GET_int("minPoints") : 1;

        // Heuristic: let DBSCAN choose the parameters
        if ($heuristic) {
            $eps = $minPoints = null;
        }

        $dbscan = $db->get_dbscan($jobid, $metric_x, $metric_y, $task_type, $eps, $minPoints);

        $seriesData = array();
        foreach ($dbscan->getClusters() as $cluster) {

            $data = array();
            foreach ($cluster as $point) {
                $task_id = $point->info['task_id'];
                $task_value_x = $point->x;
                $task_value_y = $point->y;
                $data[] = array('x' => $task_value_x, 'y' => $task_value_y, 'task_id' => $task_id);
            }

            if ($data) {
                $seriesData[] = array(
                    'points' => $data,
                    'size' => $cluster->count(),
                    'x_min' => $cluster->getXMin(),
                    'x_max' => $cluster->getXMax(),
                    'y_min' => $cluster->getYMin(),
                    'y_max' => $cluster->getYMax(),
                );
            }
        }

        $noiseData = array();
        foreach ($dbscan->getNoise() as $point) {
            $task_id = $point->info['task_id'];
            $task_value_x = $point->x;
            $task_value_y = $point->y;
            $noiseData[] = array('x' => $task_value_x, 'y' => $task_value_y, 'task_id' => $task_id);
        }

        $result = [
            'seriesData' => $seriesData,
            'noiseData' => $noiseData,
            'heuristic' => $heuristic,
            'eps' => $dbscan->getEps(),
            'minPoints' => $dbscan->getMinPoints(),
        ];

        header('Content-Type: application/json');
        ob_start('ob_gzhandler');
        echo json_encode($result, JSON_NUMERIC_CHECK);
    }

    public function dbscanexecsDataAction()
    {
        //ini_set('memory_limit', '384M');

        $db = $this->container->getDBUtils();
        $this->buildFilters();
        $whereClause = $this->filters->getWhereClause(array('execs' => 'e', 'clusters' => 'c'));

        $table_name = "e";

        $jobid = Utils::get_GET_string("jobid");
        $metric_x = Utils::get_GET_int("metric_x") !== null ? Utils::get_GET_int("metric_x") : 0;
        $metric_y = Utils::get_GET_int("metric_y") !== null ? Utils::get_GET_int("metric_y") : 1;
        $task_type = $db->get_task_type(Utils::get_GET_string("task_type"));


        list($bench, $job_offset, $id_exec) = $db->get_jobid_info($jobid);
        // Calc pending dbscanexecs (if any)
        $pending = $db->get_dbscanexecs_pending($bench, $job_offset, $metric_x, $metric_y, $task_type, $whereClause);

        if (count($pending) > 0) {
            $db->get_dbscan($pending[0]['jobid'], $metric_x, $metric_y, $task_type);
        }

        // Retrieve calculated dbscanexecs from database
        $task_type_select = $db->get_task_type_query($task_type, $filter_null=true);
        $query = "
            SELECT
                d.`id_exec`,
                d.`centroid_x`,
                d.`centroid_y`
            FROM aloja2.JOB_dbscan d, aloja2.execs e
            JOIN aloja2.clusters c USING (id_cluster)
            LEFT JOIN aloja_ml.predictions p USING (id_exec)
            WHERE
                d.`id_exec` = e.`id_exec` AND
                d.`bench` = :bench AND
                d.`job_offset` = :job_offset AND
                d.`metric_x` = :metric_x AND
                d.`metric_y` = :metric_y
                ".$task_type_select('d')."
                $whereClause
        ;";
        $query_params = array(
            ":bench" => $bench,
            ":job_offset" => $job_offset,
            ":metric_x" => $metric_x,
            ":metric_y" => $metric_y
        );

        // Since we are calculating new results, we have to bypass the cache
        $_GET['NO_CACHE'] = 1;
        $rows = $db->get_rows($query, $query_params);

        $points = new Cluster();  // Used instead of a simple array to calc x/y min/max
        foreach ($rows as $row) {
            $points[] = new Point(
                $row['centroid_x'],
                $row['centroid_y'],
                array('id_exec' => $row['id_exec'])
            );
        }

        $dbscan = new DBSCAN();
        list($clusters, $noise) = $dbscan->execute((array)$points);

        $seriesData = array();
        foreach ($clusters as $cluster) {

            $data = array();
            foreach ($cluster as $point) {
                $data[] = array(
                    'x' => $point->x,
                    'y' => $point->y,
                    'id_exec' => $point->info['id_exec']
                );
            }

            if ($data) {
                $seriesData[] = array(
                    'points' => $data,
                    'size' => $cluster->count(),
                    'x_min' => $cluster->getXMin(),
                    'x_max' => $cluster->getXMax(),
                    'y_min' => $cluster->getYMin(),
                    'y_max' => $cluster->getYMax(),
                );
            }
        }

        $noiseData = array();
        foreach ($noise as $point) {
            $noiseData[] = array(
                'x' => $point->x,
                'y' => $point->y,
                'id_exec' => $point->info['id_exec']
            );
        }

        $result = [
            'seriesData' => $seriesData,
            'noiseData' => $noiseData,
            'pending' => max(0, count($pending) - 1),
        ];

        header('Content-Type: application/json');
        ob_start('ob_gzhandler');
        echo json_encode($result, JSON_NUMERIC_CHECK);
    }
    
    public function hdp2CountersDataAction()
    {
    	$db = $this->container->getDBUtils();
        $this->buildFilters(array('bench' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple')));
        $whereClause = $this->filters->getWhereClause();
    	try {
    		//check the URL
    		$execs = Utils::get_GET_intArray('execs');
    
    		if (!($type = Utils::get_GET_string('pageTab')))
    			$type = 'SUMMARY';
    
    		$join = "JOIN aloja2.execs e using (id_exec) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.valid = 1 AND job_name NOT IN
        ('TeraGen', 'random-text-writer', 'mahout-examples-0.7-job.jar', 'Create pagerank nodes', 'Create pagerank links') $whereClause".
            ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':''). " LIMIT 10000";
    
    		if ($type == 'SUMMARY') {
    			$query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, c.TOTAL_REDUCES, c.FAILED_REDUCES, c.job_name as CHARTS,
    			e.perf_details
    			FROM aloja2.HDI_JOB_details c $join";
    		} elseif ($type == 'MAP') {
    			$query = "SELECT e.bench, e.exe_time, c.id_exec, JOB_ID, job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_MAPS, c.FAILED_MAPS, c.FINISHED_MAPS, `TOTAL_LAUNCHED_MAPS`,
    			`RACK_LOCAL_MAPS`,
    			`SPILLED_RECORDS`,
    			`MAP_INPUT_RECORDS`,
    			`MAP_OUTPUT_RECORDS`,
    			`MAP_OUTPUT_BYTES`,
    			`MAP_OUTPUT_MATERIALIZED_BYTES`,
    			e.perf_details
    			FROM aloja2.HDI_JOB_details c $join";
    		} elseif ($type == 'REDUCE') {
    			$query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME, c.TOTAL_REDUCES, c.FAILED_REDUCES,
    			`TOTAL_LAUNCHED_REDUCES`,
    			`REDUCE_INPUT_GROUPS`,
    			`REDUCE_INPUT_RECORDS`,
    			`REDUCE_OUTPUT_RECORDS`,
    			`REDUCE_SHUFFLE_BYTES`,
    			`COMBINE_INPUT_RECORDS`,
    			`COMBINE_OUTPUT_RECORDS`,
    			e.perf_details
    			FROM aloja2.HDI_JOB_details c $join";
    		} elseif ($type == 'FILE-IO') {
    			$query = "SELECT e.bench, e.exe_time, c.id_exec, c.JOB_ID, c.job_name, c.SUBMIT_TIME, c.LAUNCH_TIME,
    			c.FINISH_TIME,
    			`SLOTS_MILLIS_MAPS`,
    			`SLOTS_MILLIS_REDUCES`,
    			`SPLIT_RAW_BYTES`,
    			`FILE_BYTES_WRITTEN`,
    			`FILE_BYTES_READ`,
    			`WASB_BYTES_WRITTEN`,
    			`WASB_BYTES_READ`,
    			`BYTES_READ`,
    			`BYTES_WRITTEN`,
    			e.perf_details
    			FROM aloja2.HDI_JOB_details c $join";
    		} elseif ($type == 'DETAIL') {
    			$query = "SELECT e.bench, e.exe_time, c.*,e.perf_details FROM aloja2.HDI_JOB_details c $join";
    		} elseif ($type == 'TASKS') {
    			$query = "SELECT e.bench, e.exe_time, j.job_name, c.*,e.perf_details FROM aloja_logs.HDI_JOB_tasks c
    			JOIN aloja2.HDI_JOB_details j USING(id_exec,JOB_ID) $join ";
    		} else {
    			throw new \Exception('Unknown type!');
    		}
    
    		$exec_rows = $db->get_rows($query);

    		if (count($exec_rows) > 0) {
    
    			$show_in_result_counters = array(
    					'id_exec'   => 'ID',
    					'JOB_ID'     => 'JOBID',
    					'bench'     => 'Bench',
    					'job_name'   => 'JOBNAME',
    			);
    
    			$show_in_result_counters = Utils::generate_show($show_in_result_counters, $exec_rows, 4);
    			$jsonData = Utils::generateJSONTable($exec_rows, $show_in_result_counters, 0, 'COUNTER');
    
    			header('Content-Type: application/json');
                echo json_encode(array('aaData' => $jsonData));
    			//         if (count($exec_rows) > 10000) {
    			//             $message .= 'WARNING, large resulset, please limit the query! Rows: '.count($exec_rows);
    			//         }
    
    		} else {
                echo 'No data available';
    		}
    
    	} catch (\Exception $e) {
            exit($e->getMessage());
            echo 'No data available';
    		/*$noData = array();
    		for($i = 0; $i<=sizeof($show_in_result); ++$i)
    			$noData[] = 'error';
    
    		echo json_encode(array('aaData' => array($noData)));*/
    	}
    }
}
