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
    global $where_configs, $configurations;

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

    $benchs         = read_params('benchs');
    $nets           = read_params('nets');
    $disks          = read_params('disks');
    $blk_sizes      = read_params('blk_sizes');
    $comps          = read_params('comps');
    $id_clusters    = read_params('id_clusters');
    $mapss           = read_params('mapss');
    
    $concat_config = join(',\'_\',', $configurations);

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
?>

<?=make_HTML_header('Normalized Price by Performance of Hadoop Hibench Executions')?>
    <?=HighCharts::getHeader()?>
    <script src="https://rawgithub.com/highslide-software/draggable-legend/master/draggable-legend.js"></script>
    <script>
        $(document).ready(function() {
            $('select').change(function() {
                $(this).parents('form').submit();
            });

            var chart = new Highcharts.Chart({
                chart: {
                    type: 'bar',
                    renderTo: 'chart',
                },
                title: {
                    text: 'Average speedup by config group to average execution time by benchmark'
                },
                subtitle: {
                    //text: 'subtitle'
                },
                xAxis: {
                    categories: [
<?php
foreach ($rows_config as $row_config) {
    echo "'{$row_config['conf']}_{$row_config['num']}',";}
?>
                    ],
                    title: {
                        text: 'Configuration group',
                    }
                },
                yAxis: {
                    min: 0,
                    //max: 1,
                    title: {
                        useHTML: true,
                        text: '&#8678; Slower &nbsp;&nbsp;&nbsp; Execution time Speedup over average for benchmark (more is better) &nbsp;&nbsp;&nbsp; Faster &#8680;',
                        //align: 'high'
                    },
                    labels: {
                        overflow: 'justify'
                    },
                    plotBands: [
                        {
                            from: 0,
                            to: 1,
                            color: 'rgba(255, 170, 213, .2)'
                        },
                        {
                            from: 1,
                            to: 10,
                            color: 'rgba(100, 170, 255, .2)'
                        }]
                },
                tooltip: {
                    //valueSuffix: ' millions'
                },
                plotOptions: {
                    bar: {
                        dataLabels: {
                            enabled: true
                        }
                    }
                },
                legend: {
                    layout: 'vertical',
                    align: 'right',
                    verticalAlign: 'top',
                    x: -5,
                    y: 100,
                    floating: true,
                    borderWidth: 1,
                    backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor || '#FFFFFF'),
                    shadow: true,
                    title: {
                        text: ':: Drag Legend ::',
                    },
                    draggable: true,
                },
                credits: {
                    enabled: false
                },
                series: [
<?php
$bench = '';

foreach ($rows as $row) {
    //close previous serie if not first one
    if ($bench && $bench != $row['bench']) {
        echo "]
                        }, ";
    }
    //starts a new series
    if ($bench != $row['bench']) {
        $bench = $row['bench'];
        echo "
                    {
                    name: '{$row['bench']}',
                    data: [";
    }
    echo "['{$row['conf']}',".
        //round((($row['AVG_exe_time']-$row['MIN_ALL_exe_time'])/(0.0001+$row['MAX_ALL_exe_time']-$row['MIN_ALL_exe_time'])), 3).
        //round(($row['AVG_exe_time']), 3).
        round(($row['AVG_ALL_exe_time']/$row['AVG_exe_time']), 3). //
        "],";

}
//close the last series
echo "]
             }, ";

?>
                ]
            });

//            chart.renderer.text('Slower', 130, 65)
//                .attr({
//                    //rotation: -25
//                })
//                .css({
//                    //color: '#4572A7',
//                    fontSize: '16px'
//                })
//                .add();
//
//            chart.renderer.text('Faster', 700, 65)
//                .attr({
//                    //rotation: -25
//                })
//                .css({
//                    //color:   '#4572A7',
//                    fontSize: '16px'
//                })
//                .add();

        });

        <?php
        //foreach ($rows as $row) {
        //
        //$exec = substr($row['exec'], 21);
        //
        //if (strpos($exec, '_az') > 0) {
        //    $exec = "AZURE ".$exec;
        //} else {
        //  $exec = "LOCAL ".$exec;
        //}
        //
        //echo "                    {
        //                    name: '".$exec."',
        //                    data: [[".round($row['exe_time_std'], 3).", ".round($row['cost_std'], 3)."]]
        //                    },";
        //}
        ////,[".round($row['exe_time'], 1).", ".round($row['cost'], 1)."]
        //
        ?>

    </script>

    <?=make_header('HiBench Executions on Hadoop', $message)?>
    <?=make_navigation('Cost Evaluation')?>
    <div id="navigation" style="text-align: center; vertical-align: top;">

        <table width="80%" align="center">
            <tr>
                <td>
                    <div id="chart" style="width: 800px; height: 600px; margin: 0 auto"></div>
                </td>
                <td width="50">
                    &nbsp;
                </td>
                <td valign="top" align="left">
                    <div >
                        <form method="get">
                            <h2>
                                <table>
                                    <tr>
                                        <td>
                                            <h2>Filters: <a href="<?=$_SERVER['PHP_SELF']?>">(reset)</a></h2>

                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Benchmarks:</br>
                                            <select name="benchs[]" multiple >

                                                <option value="pagerank"    <?php if (in_array('pagerank', $benchs)) echo "SELECTED"; ?>>pagerank</option>
                                                <option value="sort"        <?php if (in_array('sort', $benchs)) echo "SELECTED"; ?>>sort</option>
                                                <option value="terasort"    <?php if (in_array('terasort', $benchs)) echo "SELECTED"; ?>>terasort</option>
                                                <option value="wordcount"   <?php if (in_array('wordcount', $benchs)) echo "SELECTED"; ?>>wordcount</option>

                                                <option value="dfsioe_read" <?php if (in_array('dfsioe_read', $benchs)) echo "SELECTED"; ?>>dfsioe_read</option>
                                                <option value="dfsioe_write" <?php if (in_array('dfsioe_write', $benchs)) echo "SELECTED"; ?>>dfsioe_write</option>

                                                <!--<option value="kmeans"      <?php if (in_array('kmeans', $benchs)) echo "SELECTED"; ?>>kmeans</option>-->
                                                <!--<option value="bayes"       <?php if (in_array('bayes', $benchs)) echo "SELECTED"; ?>>bayes</option>-->

                                                <option value="None"   <?php if (!$nets) echo "SELECTED"; ?>>ALL</option>

                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Networks:</br>
                                            <select name="nets[]" multiple  >
                                                <option value="IB"    <?php if (in_array('IB', $nets)) echo "SELECTED"; ?>>InfiniBand</option>
                                                <option value="ETH"   <?php if (in_array( 'ETH', $nets)) echo "SELECTED"; ?>>GbEthernet</option>
                                                <option value="None"   <?php if (!$nets) echo "SELECTED"; ?>>Disabled</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Disks:</br>
                                            <select name="disks[]" multiple>
                                                <option value="SSD"    <?php if (in_array('SSD', $disks)) echo "SELECTED"; ?>>SSD</option>
                                                <option value="HDD"   <?php if (in_array( 'HDD', $disks)) echo "SELECTED"; ?>>HDD</option>
                                                <option value="RL1"   <?php if (in_array( 'RL1', $disks)) echo "SELECTED"; ?>>RL1</option>
                                                <option value="RL2"   <?php if (in_array( 'RL2', $disks)) echo "SELECTED"; ?>>RL2</option>
                                                <option value="RL3"   <?php if (in_array( 'RL3', $disks)) echo "SELECTED"; ?>>RL3</option>
                                                <option value="R1"   <?php if (in_array( 'R1', $disks)) echo "SELECTED"; ?>>R1</option>
                                                <option value="R2"   <?php if (in_array( 'R2', $disks)) echo "SELECTED"; ?>>R2</option>
                                                <option value="R3"   <?php if (in_array( 'R1', $disks)) echo "SELECTED"; ?>>R3</option>
                                                <!--                                    <option value="RR1"   --><?php //if (in_array( 'RR1', $disks)) echo "SELECTED"; ?><!-->RR1</option>-->
                                                <!--                                    <option value="RR2"   --><?php //if (in_array( 'RR2', $disks)) echo "SELECTED"; ?><!-->RR2</option>-->
                                                <!--                                    <option value="RR3"   --><?php //if (in_array( 'RR1', $disks)) echo "SELECTED"; ?><!-->RR3</option>-->
                                                <option value="None"   <?php if (!$disks) echo "SELECTED"; ?>>Disabled</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Clusters:</br>
                                            <select name="id_clusters[]" multiple >
                                                <option value="1"    <?php if (in_array('1', $id_clusters)) echo "SELECTED"; ?>>Local</option>
                                                <option value="2"    <?php if (in_array('2', $id_clusters)) echo "SELECTED"; ?>>Azure</option>
                                                <option value="None"   <?php if (!$id_clusters) echo "SELECTED"; ?>>Disabled</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Maps:</br>
                                            <select name="mapss[]" multiple >
                                                <option value="4"    <?php if (in_array('4', $mapss)) echo "SELECTED"; ?>>4</option>
                                                <option value="6"    <?php if (in_array('6', $mapss)) echo "SELECTED"; ?>>6</option>
                                                <option value="8"    <?php if (in_array('8', $mapss)) echo "SELECTED"; ?>>8</option>
                                                <option value="10"    <?php if (in_array('10', $mapss)) echo "SELECTED"; ?>>10</option>
                                                <option value="12"    <?php if (in_array('12', $mapss)) echo "SELECTED"; ?>>12</option>
                                                <option value="16"    <?php if (in_array('16', $mapss)) echo "SELECTED"; ?>>16</option>
                                                <option value="24"    <?php if (in_array('24', $mapss)) echo "SELECTED"; ?>>24</option>
                                                <option value="32"    <?php if (in_array('32', $mapss)) echo "SELECTED"; ?>>32</option>
                                                <option value="None"   <?php if (!$mapss) echo "SELECTED"; ?>>Disabled</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            Compression:</br>
                                            <select name="comps[]" multiple size="2">
                                                <option value="0"    <?php if (in_array('0', $comps)) echo "SELECTED"; ?>>None</option>
                                                <option value="1"   <?php if (in_array( '1', $comps)) echo "SELECTED"; ?>>ZLIB</option>
                                                <option value="2"   <?php if (in_array( '2', $comps)) echo "SELECTED"; ?>>BZIP2</option>
                                                <option value="3"   <?php if (in_array( '3', $comps)) echo "SELECTED"; ?>>Snappy</option>
                                                <option value="None"   <?php if (!$comps) echo "SELECTED"; ?>>Disabled</option>
                                            </select>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>

                                        </td>
                                    </tr>
                                </table>


                            </h2>
                        </form>
                    </div>
                </td>
            </tr>
        </table>


            </br>


    </div>
    </br></br>
<?php

echo $footer;
