<?php

require_once 'inc/common.php';
require_once 'inc/HighCharts.php';

$message = '';

try {

    if (isset($_GET['benchs'])) {
        $benchs = $_GET['benchs'];
    } else {
        $benchs = array('pagerank', 'sort', 'terasort', 'wordcount');
    }
    $where_benchs = ' AND bench IN ("'.join('","', $benchs).'")';

    if (isset($_GET['nets'])) {
        $nets = $_GET['nets'];
    } else {
        $nets = array('IB', 'ETH');
    }
    $where_nets = '';
    if ($nets) $where_nets = ' AND net IN ("'.join('","', $nets).'")';

    if (isset($_GET['disks'])) {
        $disks = $_GET['disks'];
    } else {
        $disks = array('SSD', 'HDD');
    }
    $where_disks = '';
    if ($disks) $where_disks = ' AND disk IN ("'.join('","', $disks).'")';

    //get configs first (categories)
    $query = "SELECT concat(net, '_', disk) conf from execs e
              WHERE 1 $where_benchs $where_nets $where_disks
              GROUP BY conf;";

    $rows_config = get_rows($query);

    //get the result rows
    $query = "SELECT concat(net, '_', disk) conf, bench,
              avg(exe_time) AVG_exe_time,
              max(exe_time) MAX_exe_time,
              min(exe_time) MIN_exe_time
              from execs e
              WHERE 1  $where_benchs $where_nets $where_disks
              GROUP BY conf, bench order by bench;";

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
                    text: 'Average execution time improvement by configuration'
                },
                subtitle: {
                    //text: 'subtitle'
                },
                xAxis: {
                    categories: [
<?php
foreach ($rows_config as $row_config) {
    echo "'{$row_config['conf']}',";}
?>
                    ],
                    title: {
                        //text: null
                    }
                },
                yAxis: {
                    min: 0,
                    max: 1,
                    title: {
                        text: 'Configuration',
                        align: 'high'
                    },
                    labels: {
                        overflow: 'justify'
                    }
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
                    x: 0,
                    y: 100,
                    floating: true,
                    borderWidth: 1,
                    backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor || '#FFFFFF'),
                    shadow: true
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
        round((($row['AVG_exe_time']-$row['MIN_exe_time'])/(0.0001+$row['MAX_exe_time']-$row['MIN_exe_time'])), 3).
        "],";

}
//close the last series
echo "]
             }, ";

?>
                ]
            });
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
        <form method="get">
            <h2>
                Benchmarks:
                <select name="benchs[]" multiple size="6">
                    <option value="dfsioe_read" <?php if (in_array( 'dfsioe_read', $benchs)) echo "SELECTED"; ?>>dfsioe_read</option>
                    <option value="dfsioe_write" <?php if (in_array( 'dfsioe_write', $benchs)) echo "SELECTED"; ?>>dfsioe_write</option>
                    <option value="pagerank"    <?php if (in_array( 'pagerank', $benchs)) echo "SELECTED"; ?>>pagerank</option>
                    <option value="sort"        <?php if (in_array( 'sort', $benchs)) echo "SELECTED"; ?>>sort</option>
                    <option value="terasort"    <?php if (in_array('terasort', $benchs)) echo "SELECTED"; ?>>terasort</option>
                    <option value="wordcount"   <?php if (in_array( 'wordcount', $benchs)) echo "SELECTED"; ?>>wordcount</option>

                    <!--<option value="kmeans"      <?php if (in_array( 'kmeans', $benchs)) echo "SELECTED"; ?>>kmeans</option>-->
                    <!--<option value="bayes"       <?php if (in_array( 'bayes', $benchs)) echo "SELECTED"; ?>>bayes</option>-->

                </select>
                Networks:
                <select name="nets[]" multiple size="2">
                    <option value="IB"    <?php if (in_array('IB', $nets)) echo "SELECTED"; ?>>InfiniBand</option>
                    <option value="ETH"   <?php if (in_array( 'ETH', $nets)) echo "SELECTED"; ?>>GbEthernet</option>
                </select>
                Disks:
                <select name="disks[]" multiple size="2">
                    <option value="SSD"    <?php if (in_array('SSD', $disks)) echo "SELECTED"; ?>>SSD</option>
                    <option value="HDD"   <?php if (in_array( 'HDD', $disks)) echo "SELECTED"; ?>>HDD</option>
                </select>
            </h2>
            <div id="chart" style="width: 800px; height: 800px; margin: 0 auto"></div>
            </br>

        </form>
    </div>
    </br></br>
<?php
//echo "</br></br>
//cost_hour_AZURE: $cost_hour_AZURE </br>
//cost_hour_HDD_ETH: $cost_hour_HDD_ETH  </br>
//cost_hour_HDD_IB: $cost_hour_HDD_IB  </br>
//cost_hour_SSD_ETH: $cost_hour_SSD_ETH  </br>
//cost_hour_SSD_IB:$cost_hour_SSD_IB";

echo $footer;
