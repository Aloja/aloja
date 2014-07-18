<?php

require_once 'inc/common.php';
require_once 'inc/HighCharts.php';

$message = '';

function delete_none($array) {
   if (($key = array_search('None', $array)) !== false) {
       unset ($array[$key]);
   }
   return $array;
}


function read_params($item_name) {
    global $where_configs, $configurations, $concat_config;

    $single_item_name = substr($item_name, 0, -1);

    if (isset($_GET[$item_name])) {
        $items = $_GET[$item_name];
        $items = delete_none($items);
    } else {
        if ($item_name == 'benchs') {
            $items = array('pagerank', 'terasort', 'wordcount');
        } elseif ($item_name == 'nets') {
            $items = array('IB', 'ETH');
        } elseif ($item_name == 'disks') {
            $items = array('SSD', 'HDD');
        } else {
            $items = array();
        }

    }
    if ($items) {
        if ($item_name != 'benchs') {
            $configurations[] = $single_item_name;
            if ($concat_config) $concat_config .= ",'_',";

            if ($item_name == 'id_clusters') {
                $conf_prefix = 'CL';
            } elseif ($item_name == 'iofilebufs') {
                $conf_prefix = 'I';
            } else {
                $conf_prefix = substr($single_item_name, 0, 1);
            }

            //avoid alphanumeric fields
            if (!in_array($item_name, array('nets', 'disks'))) {
                $concat_config .= "'".$conf_prefix."', $single_item_name";
            } else {
                $concat_config .= " $single_item_name";
            }
        }
        $where_configs .=
            ' AND '.
            $single_item_name. //remove trailing 's'
            ' IN ("'.join('","', $items).'")';
    }
    
    return $items;
}


try {

    $configurations = array();
    $where_configs = '';
    $concat_config = "";

    $benchs         = read_params('benchs');
    $nets           = read_params('nets');
    $disks          = read_params('disks');
    $blk_sizes      = read_params('blk_sizes');
    $comps          = read_params('comps');
    $id_clusters    = read_params('id_clusters');
    $mapss          = read_params('mapss');
    $replications   = read_params('replications');
    $iosfs          = read_params('iosfs');
    $iofilebufs     = read_params('iofilebufs');

    
    //$concat_config = join(',\'_\',', $configurations);
    //$concat_config = substr($concat_config, 1);

    //make sure there are some defaults
    if (!$concat_config) {
        $concat_config = 'disk';
        $disks = array('HDD');
    }

    $order_conf = 'LENGTH(conf), conf';
    //get configs first (categories)
    $query = "SELECT count(*) num, concat($concat_config) conf from execs e
              WHERE 1 $filter_execs $where_configs
              GROUP BY conf ORDER BY $order_conf #AVG(exe_time)
              ;";
              
    $rows_config = get_rows($query);

    //get the result rows
    $query = "SELECT #count(*),
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

    $rows = get_rows($query);

    if ($rows) {
        //print_r($rows);
    } else {
        throw new Exception("No results for query!");
    }

} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
}

$categories = '';
$count = 0;
foreach ($rows_config as $row_config) {
    $categories .= "'{$row_config['conf']} #{$row_config['num']}',";
    $count += $row_config['num'];
}

$series = '';
$bench = '';
if ($rows) {
    foreach ($rows as $row) {
        //close previous serie if not first one
        if ($bench && $bench != $row['bench']) {
            $series .= "]
                }, ";
        }
        //starts a new series
        if ($bench != $row['bench']) {
            $bench = $row['bench'];
            $series .= "
                {
                    name: '{$row['bench']}',
                        data: [";
        }
        $series .= "['{$row['conf']}',".
            //round((($row['AVG_exe_time']-$row['MIN_ALL_exe_time'])/(0.0001+$row['MAX_ALL_exe_time']-$row['MIN_ALL_exe_time'])), 3).
            //round(($row['AVG_exe_time']), 3).
            round(($row['AVG_ALL_exe_time']/$row['AVG_exe_time']), 3). //
            "],";

    }
    //close the last series
    $series .= "]
            }, ";
}
echo $twig->render('config_improvement/config_improvement.html.twig',
     array('selected' => 'Config Improvement',
        'message' => $message,
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
     )
);

