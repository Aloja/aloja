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

    $outliers = "(exe_time/3600)*$cost_hour_HDD_ETH < 100 $filter_execs";
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
                    renderTo: 'chart',
                    defaultSeriesType: 'scatter',
                    zoomType: 'x'
                },
                credits: {
                    enabled: false
                },
                title: {
                    text: 'HiBench <?=$bench?> execution cost by performance (normalized)',
                    x: -20 //center
                },
                subtitle: {
                    text: 'Hover a marker to get execution configuration details.  Drag to zoom.',
                    x: -20
                },
                legend: {
                    enabled: false
                },
                yAxis: {
                    max: 1,
                    min: 0,
                    title: {
                        useHTML: true,
                        text: '&#8678; Economical &nbsp;&nbsp;&nbsp;  Normalized cost (higher is worse) &nbsp;&nbsp;&nbsp; Expensive &#8680;'

                    },
                    //lineWidth: 2,
//                    plotLines: [{
//                        value: 0,
//                        width: 1,
//                        color: '#808080'
//                    }],
                    plotBands: [{
                        from: 0.5,
                        to: 1,
                        color: 'rgba(255, 170, 213, .2)'
                    }]
                },
                xAxis: [{
                    max: 1,
                    min: 0,
                    title: {
                        useHTML: true,
                        text: '&#8678; Faster &nbsp;&nbsp;&nbsp;  Normalized execution time (higher is worse) &nbsp;&nbsp;&nbsp; Slower &#8680;'
                    },
                    //lineWidth: 2,
//                    plotLines: [{
//                        value: 0,
//                        width: 1,
//                        color: '#808080'
//                    }],
//                    plotLines: {
//                        //color: 'red', // Color value
//                        //dashStyle: 'longdashdot', // Style of the plot line. Default to solid
//                        value: '3', // Value of where the line will appear
//                        width: '2' // Width of the line
//                    }
                    plotBands: [
                    {
                        from: 0,
                        to: 0.5,
                        color: 'rgba(100, 170, 255, .2)'
                    },
                    {
                        from: 0.5,
                        to: 1,
                        color: 'rgba(255, 170, 213, .2)'
                    }]
                }
//                    ,{
//                    lineWidth: 1,
//                    offset: 70,
//                    title: {
//                        text: 'Seconds'
//                    },
//                    tickWidth: 1
//                }
                ],
                plotOptions: {
                    scatter: {
                        marker: {
                            radius: 5,
                            states: {
                                hover: {
                                    enabled: true,
                                    lineColor: 'rgb(100,100,100)'
                                }
                            }
                        },
                        states: {
                            hover: {
                                marker: {
                                    enabled: false
                                }
                            }
                        }
//                        ,
//                        dataLabels: {
//                            enabled: true,
//                            style: {
//                                textShadow: '0 0 3px white, 0 0 3px white'
//                            }
//                        }
                    }
                },

                series: [
<?php
foreach ($rows as $row) {

$exec = substr($row['exec'], 21);

if (strpos($exec, '_az') > 0) {
    $exec = "AZURE ".$exec;
} else {
  $exec = "LOCAL ".$exec;
}

echo "                    {
                    name: '".$exec."',
                    data: [[".round($row['exe_time_std'], 3).", ".round($row['cost_std'], 3)."]]
                    },";
}
//,[".round($row['exe_time'], 1).", ".round($row['cost'], 1)."]
?>
                ]
            });

            chart.renderer.text('Fast-Expensive', 180, 240)
                .attr({
                    //rotation: -25
                })
                .css({
                    color: '#4572A7',
                    fontSize: '16px'
                })
                .add();

            chart.renderer.text('Slow-Expensive', 560, 240)
                .attr({
                    //rotation: -25
                })
                .css({
                    color: '#4572A7',
                    fontSize: '16px'
                })
                .add();

            chart.renderer.text('Fast-Economical', 180, 590)
                .attr({
                    //rotation: -25
                })
                .css({
                    color: '#4572A7',
                    fontSize: '16px'
                })
                .add();

            chart.renderer.text('Slow-Economical', 560, 590)
                .attr({
                    //rotation: -25
                })
                .css({
                    color: '#4572A7',
                    fontSize: '16px'
                })
                .add();

            // the button action
            $('#button').click(function() {
                var chart = $('#container').highcharts();
                chart.xAxis[0].setExtremes(-3000, 3000);
                chart.yAxis[0].setExtremes(-20, 20);
            });
        });
    </script>

    <?=make_header('HiBench Executions on Hadoop', $message)?>
    <?=make_navigation('Cost Evaluation')?>
    <div id="navigation" style="text-align: center;">
        <form method="get">
            <h2>
                Benchmark:
                <select name="bench">
                    <!--<option value=""    <?php if ($bench == '') echo "SELECTED"; ?>>ALL</option>-->
                    <option value="terasort"    <?php if ($bench == 'terasort') echo "SELECTED"; ?>>terasort</option>
                    <option value="wordcount"   <?php if ($bench == 'wordcount') echo "SELECTED"; ?>>wordcount</option>
                    <option value="sort"        <?php if ($bench == 'sort') echo "SELECTED"; ?>>sort</option>
                    <option value="pagerank"    <?php if ($bench == 'pagerank') echo "SELECTED"; ?>>pagerank</option>
                    <!--<option value="kmeans"      <?php if ($bench == 'kmeans') echo "SELECTED"; ?>>kmeans</option>-->
                    <!--<option value="bayes"       <?php if ($bench == 'bayes') echo "SELECTED"; ?>>bayes</option>-->
                    <option value="dfsioe_read" <?php if ($bench == 'dfsioe_read') echo "SELECTED"; ?>>dfsioe_read</option>
                    <option value="dfsioe_write" <?php if ($bench == 'dfsioe_write') echo "SELECTED"; ?>>dfsioe_write</option>
                </select>
            </h2>
            <div id="chart" style="width: 800px; height: 800px; margin: 0 auto"></div>
            </br>
            <h1>Edit cluster configuration costs:</h1>
            <div style="text-align: center; margin-left: auto; margin-right: auto; width: 80%;">
                <table>
                    <tr>
                        <td>cost_hour_AZURE:</td>
                        <td><input type="text" name="cost_hour_AZURE" value="<?=$cost_hour_AZURE?>" size="4"></td>
                        <td>cost_hour_AZURE_1remote:</td>
                        <td><input type="text" name="cost_hour_AZURE_1remote" value="<?=$cost_hour_AZURE_1remote?>" size="4"></td>
                        <td>cost_hour_HDD_ETH:</td>
                        <td><input type="text" name="cost_hour_HDD_ETH" value="<?=$cost_hour_HDD_ETH?>" size="4"></td>
                    </tr>
                    <tr>
                        <td>cost_hour_HDD_IB:</td>
                        <td><input type="text" name="cost_hour_HDD_IB" value="<?=$cost_hour_HDD_IB?>" size="4"></td>
                        <td>cost_hour_SSD_ETH:</td>
                        <td><input type="text" name="cost_hour_SSD_ETH" value="<?=$cost_hour_SSD_ETH?>" size="4"></td>
                        <td>cost_hour_SSD_IB:</td>
                        <td><input type="text" name="cost_hour_SSD_IB" value="<?=$cost_hour_SSD_IB?>" size="4"></td>
                        <td></td>
                        <td style="text-align: right;"> <input type="submit" value="Submit"></td>
                    </tr>
                </table>
            </div>
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
