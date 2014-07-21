<?php

require_once('inc/common.php');

try {
	$table_fields = null;
	$exec_rows = get_execs();

	if (count($exec_rows) > 0) {
		$jsonData = generateJSONTable($exec_rows, $show_in_result);
	} else {
		throw new Exception("No results for query!");
	}
	header('Content-Type: application/json');
	ob_start('ob_gzhandler');
	echo $jsonData;

} catch(Exception $e) {
	$noData = array();
	for($i = 0; $i<18; ++$i)
		$noData[] = $e->getMessage();
	
	echo json_encode(array('aaData' => $noData));
}