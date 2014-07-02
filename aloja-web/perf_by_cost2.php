<?php

require_once 'inc/common.php';
require_once 'inc/HighCharts.php';

try {

    if (isset($_GET['bench']) and strlen($_GET['bench']) > 0) {
        $bench = $_GET['bench'];
        $bench_where = " AND bench = '$bench'";
    } else {
        $bench = '';
        $bench_where = "";
    }



    if (isset($_GET['cost'])) {
        $cost = $_GET['cost'];
    } else {
        $cost = 12;
    }

    if (isset($_GET['cost_cloud'])) {
        $cost = $_GET['cost_cloud'];
    } else {
        $cost = 7;
    }


//    $query = "
//    select bench, exe_time, (exe_time/3600)*cost_hour cost,
//exe_time -(select avg(exe_time) from execs e join clusters c using (id_cluster) where exe_time < 5000 $bench_where )
// exe_time_std,
// (exe_time/3600)*(if(locate('_SSD', exec) > 0, cost_hour*2.5, cost_hour))*(if(locate('_IB_', exec) > 0, 1.5, 1)) - (select avg((exe_time/3600)*cost_hour) from execs e join clusters c using (id_cluster) where exe_time < 5000 $bench_where )
// cost_std,
//exec from execs e join clusters c using (id_cluster)
//where (exe_time/3600)*cost_hour < 100 and exe_time < 5000 $bench_where;
//";

    if (isset($_GET['cost_hour_HDD_ETH'])) {
        $cost_hour_HDD_ETH = $_GET['cost_hour_HDD_ETH'];
    } else {
        $cost_hour_HDD_ETH = 12;
    }

    if (isset($_GET['cost_hour_AZURE'])) {
        $cost_hour_AZURE = $_GET['cost_hour_AZURE'];
    } else {
        $cost_hour_AZURE = 7;
    }

    if (isset($_GET['cost_hour_SSD_IB'])) {
        $cost_hour_SSD_IB = $_GET['cost_hour_SSD_IB'];
    } else {
        $cost_hour_SSD_IB = 40;
    }

    if (isset($_GET['cost_hour_SSD_ETH'])) {
        $cost_hour_SSD_ETH = $_GET['cost_hour_SSD_ETH'];
    } else {
        $cost_hour_SSD_ETH = 30;
    }

    if (isset($_GET['cost_hour_HDD_IB'])) {
        $cost_hour_HDD_IB = $_GET['cost_hour_HDD_IB'];
    } else {
        $cost_hour_HDD_IB = 22;
    }

    $avg_exe_time = "(select avg(exe_time) from execs e where exe_time < 5000 $bench_where )";
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
                $cost_hour_AZURE,
                $cost_hour_HDD_ETH
            )
       )
    )
)";

    //http://minerva.bsc.es:8099/aloja-web/perf_by_cost2.php?bench=wordcount&cost_hour_LOCAL=12&cost_hour_AZURE=7&cost_hour_SSD_IB=40&cost_hour_SSD_ETH=30&cost_hour_HDD_IB=22

    $query = "
SELECT
exe_time - $avg_exe_time  exe_time_std,
$cost_per_run - (select avg($cost_per_run) from execs e where exe_time < 5000 $bench_where )  cost_std,
exec
from execs e
where (exe_time/3600)*$cost_hour_HDD_ETH < 100 and exe_time < 5000 $bench_where and substr(exec, 1, 8) > '20131220';
";


    echo "<!-- $query -->";

    $rows = get_rows($query);

    if ($rows) {
        //print_r($rows);
    } else {
        throw new Exception("No results for query!");
    }

} catch(Exception $e) {
    print_r($e->getMessage());
    exit;
}
?>

<html>
<head>
    <?=HighCharts::getHeader()?>
    <script>
        $(document).ready(function() {
            var chart = new Highcharts.Chart({
                chart: {
                    renderTo: 'container',
                    defaultSeriesType: 'scatter',
                    zoomType: 'x'
                },
                title: {
                    text: 'HiBench <?=$bench?> execution cost by performance (absolute values)',
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
                    title: {
                        useHTML: true,
                        text: '&#8678; Less expensive &nbsp;&nbsp;&nbsp;  Actual cost - Average cost (higher is worse) &nbsp;&nbsp;&nbsp; More expensive &#8680;'

                    },
                    //lineWidth: 2,
//                    plotLines: [{
//                        value: 0,
//                        width: 1,
//                        color: '#808080'
//                    }],
                    plotBands: [{
                        from: 0,
                        to: 99999,
                        color: 'rgba(255, 170, 213, .2)'
                    }]
                },
                xAxis: {
                    title: {
                        useHTML: true,
                        text: '&#8678; Faster &nbsp;&nbsp;&nbsp;  Actual execution time - Average exection time (higher is worse) &nbsp;&nbsp;&nbsp; Slower &#8680;'
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
                        from: -99999,
                        to: -1,
                        color: 'rgba(100, 170, 255, .2)'
                    },
                    {
                        from: 1,
                        to: 99999,
                        color: 'rgba(255, 170, 213, .2)'
                    }]
                },
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
echo "                    {
                    name: '".substr($row['exec'], 21)."',
                    data: [[".round($row['exe_time_std'], 1).", ".round($row['cost_std'], 1)."]]
                    },";
}
?>
                ]
            });

            // the button action
            $('#button').click(function() {
                var chart = $('#container').highcharts();
                chart.xAxis[0].setExtremes(-3000, 3000);
                chart.yAxis[0].setExtremes(-20, 20);
            });
        });
    </script>

</head>
<body>
<div id="content" style="width: 80%;">
    <div id="container" style="min-width: 310px; height: 800px; margin: 0 auto"></div>
    <button id="button" class="autocompare">Fixed axis</button>
<?php
echo "</br></br>
cost_hour_AZURE: $cost_hour_AZURE </br>
cost_hour_HDD_ETH: $cost_hour_HDD_ETH  </br>
cost_hour_HDD_IB: $cost_hour_HDD_IB  </br>
cost_hour_SSD_ETH: $cost_hour_SSD_ETH  </br>
cost_hour_SSD_IB:$cost_hour_SSD_IB";
?>


</div>
</body>
</html>
