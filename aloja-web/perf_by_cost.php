<?php

require_once 'inc/common.php';
require_once 'inc/HighCharts.php';

$message = '';

try {

    if (isset($_GET['bench']) and strlen($_GET['bench']) > 0) {
        $bench = $_GET['bench'];
        $bench_where = " AND bench = '$bench'";
    } else {
        $bench = '';
        $bench_where = "";
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

    $outliers = "(exe_time/3600)*$cost_hour_HDD_ETH < 100 $filter_execs $filter_execs_max_time";
    $avg_exe_time = "(select avg(exe_time) from execs e where $outliers $bench_where )";
    $std_exe_time = "(select std(exe_time) from execs e where $outliers $bench_where )";
    $max_exe_time = "(select max(exe_time) from execs e where $outliers $bench_where )";
    $min_exe_time = "(select min(exe_time) from execs e where $outliers $bench_where )";
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
                    ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*1)).",
                    if (locate('_ETH_R2_', exec) > 0 OR locate('_ETH_RR2_', exec) > 0,
                        ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*2)).",
                        if (locate('_ETH_R3_', exec) > 0 OR locate('_ETH_RR3_', exec) > 0,
                            ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*3)).",
                            if (locate('_RL1_', exec) > 0,
                                ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*1)).",
                                if (locate('_RL2_', exec) > 0,
                                    ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*2)).",
                                    if (locate('_RL3_', exec) > 0,
                                        ".($cost_hour_AZURE+($cost_hour_AZURE_1remote*3)).",
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
    $avg_cost_per_run = "(select avg($cost_per_run) from execs e where $outliers $bench_where )";
    $std_cost_per_run = "(select std($cost_per_run) from execs e where $outliers $bench_where )";
    $max_cost_per_run = "(select max($cost_per_run) from execs e where $outliers $bench_where )";
    $min_cost_per_run = "(select min($cost_per_run) from execs e where $outliers $bench_where )";

    //http://minerva.bsc.es:8099/aloja-web/perf_by_cost2.php?bench=wordcount&cost_hour_LOCAL=12&cost_hour_AZURE=7&cost_hour_SSD_IB=40&cost_hour_SSD_ETH=30&cost_hour_HDD_IB=22

    $query = "
SELECT
(exe_time - $min_exe_time)/($max_exe_time - $min_exe_time)  exe_time_std,
($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
exec, exe_time, $cost_per_run cost,
$min_exe_time min_exe_time, $max_exe_time max_exe_time, $min_exe_time min_exe_time
from execs e
where $outliers $bench_where and substr(exec, 1, 8) > '20131220';
";

    $rows = get_rows($query);

    if ($rows) {
        //var_dump($rows);
    } else {
        throw new Exception("No results for query!");
    }

} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
}

$seriesData = '';
foreach ($rows as $row) {

	$exec = substr($row['exec'], 21);

	if (strpos($exec, '_az') > 0) {
		$exec = "AZURE ".$exec;
	} else {
		$exec = "LOCAL ".$exec;
	}

	$seriesData .= "{
                    name: '".$exec."',
                    data: [[".round($row['exe_time_std'], 3).", ".round($row['cost_std'], 3)."]]
                    },";
}

echo $twig->render('perf_by_cost/perf_by_cost.html.twig',
		array('selected' => 'Cost Evaluation',
				'show_in_result' => count($show_in_result),
				'message' => $message,
				'seriesData' => $seriesData,
				'bench' => $bench,
				'cost_hour_SSD_IB' => $cost_hour_SSD_IB,
				'cost_hour_AZURE' => $cost_hour_AZURE,
				'cost_hour_AZURE_1remote' => $cost_hour_AZURE_1remote,
				'cost_hour_HDD_ETH' => $cost_hour_HDD_ETH,
				'cost_hour_HDD_IB' => $cost_hour_HDD_IB,
				'cost_hour_SSD_ETH' => $cost_hour_SSD_ETH,
				'title' => 'Normalized Price by Performance of Hadoop Hibench Executions'
				//'execs' => (isset($execs) && $execs ) ? make_execs($execs) : 'random=1'
		));
