<?php

namespace alojaweb\Controller;

use alojaweb\inc\Utils;

class RepositoryController extends AbstractController
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

    public function benchExecutionsAction()
    {
        $dbUtils = $this->container->getDBUtils();
        $this->buildFilters(array('bench' => array('default' => null)));
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

    public function countersAction()
    {
        try {
            $db = $this->container->getDBUtils();
            $this->buildFilters(array('bench' => array('default' => null)));
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

            if (Utils::get_GET_string('pageTab')) {
                $type = Utils::get_GET_string('pageTab');
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

    public function hdp2CountersAction()
    {
        try {
            $db = $this->container->getDBUtils();
            $this->buildFilters(array('bench' => array('default' => null)));
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

            if (Utils::get_GET_string('pageTab')) {
                $type = Utils::get_GET_string('pageTab');
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
}
