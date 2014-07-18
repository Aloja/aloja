<?php

require_once('inc/common.php');

try {

	$message = null;

	//check the URL
	$execs = get_GET_execs();
	
	if (get_GET_string('type')) {
		$type = get_GET_string('type');
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
	} elseif  ($type == 'MAP') {
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
	} elseif  ($type == 'REDUCE') {
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
	} elseif  ($type == 'FILE-IO') {
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
	} elseif  ($type == 'DETAIL') {
		$query = "SELECT e.bench, exe_time, c.* FROM JOB_details c $join";
	} elseif  ($type == 'TASKS') {
		$query = "SELECT e.bench, exe_time, j.JOBNAME, c.* FROM JOB_tasks c
		JOIN JOB_details j USING(id_exec, JOBID) $join ";
	} else {
		throw new Exception('Unknown type!');
	}

	$exec_rows = get_rows($query);

	if (count($exec_rows) > 0) {

		$show_in_result_counters = array(
				'id_exec'   => 'ID',
				//'job_name'  => 'Job Name',
				//'exe_time' => 'Total Time',

				'JOBID'     => 'JOBID',
				'bench'     => 'Bench',
				'JOBNAME'   => 'JOBNAME',
		);

		$show_in_result_counters = generate_show($show_in_result_counters, $exec_rows, 4);
	}
} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
}

echo $twig->render('counters/counters.html.twig',
		array('selected' => 'Hadoop Job Counters',
				'show_in_result_counters' => $show_in_result_counters,
				'show_in_result' => $show_in_result,
				//'table_fields' => $table_fields,
				'message' => $message,
                'title' => 'Hadoop Jobs and Tasks Execution Counters',
				'type' => $type,
				'execs' => $execs,
				'execsParam' => (isset($_GET['execs'])) ? $_GET['execs'] : ''
				//'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
		));
?>