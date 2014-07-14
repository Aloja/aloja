<?php

require_once('inc/common.php');

try {
    $table_fields = null;
    $exec_rows = get_execs();

    if (count($exec_rows) > 0) {
        $table_fields = generate_table($exec_rows, $show_in_result);
    } else {
        throw new Exception("No results for query!");
    }

} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
}

echo $twig->render('datatable/datatable.html.twig',
		array('selected' => 'HiBench Runs Details',
			  'show_in_result' => count($show_in_result),
			  'table_fields' => $table_fields,
			  'message' => $message
			  //'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
			));
