<?php

require_once 'inc/common.php';

try {

    //requiered params
    $id_exec        = 1;
    $title          = '';
    $fields         = null;
    $type           = 'cpu';
    $stacked        = false;
    $percentage     = false;

    //check the URL
    if (isset($_GET['id_exec']) &&
        ($tmp = filter_var($_GET['id_exec'], FILTER_SANITIZE_NUMBER_INT)) &&
        $tmp > 0) {
        $id_exec = $tmp;
        unset($tmp);
    }
    if (isset($_GET['title'])) {
        $title = filter_var($_GET['title'], FILTER_SANITIZE_STRING);
    }
    if (isset($_GET['fields'])) {
        $fields = filter_var(urldecode($_GET['fields']), FILTER_SANITIZE_STRING);

        if (!$title) $title = $fields;

        $fields = explode(',', $fields);
    }
    if (isset($_GET['percentage']) && $_GET['percentage']) $percentage = true;
    if (isset($_GET['stacked']) && $_GET['stacked']) $stacked = true;
    if (isset($_GET['type']) && $_GET['type']) $type = $_GET['type'];

    $queries = array (
        'cpu' => "SELECT * FROM SAR_cpu where id_exec = '$id_exec';",
        'memory_util' => "SELECT * FROM SAR_memory_util where id_exec = '$id_exec';",
    );

    if (!($query = $queries[$type])) throw new Exception("Chart type not set");
    $rows = get_rows($query);

    if (count($rows) > 0) {

        echo "Number of rows: ".count($rows)."Fields: ".print_r(array_keys($rows[0]), true);

        //print_r($fields);

    } else {
        throw new Exception("No results for query!");
    }

    if (!is_array($fields)) throw new Exception('No fields defined');


} catch(Exception $e) {
    print_r($e->getMessage());
    exit;
}
?>

<html>
    <head>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <script src="http://code.highcharts.com/highcharts.js"></script>
    <script src="http://code.highcharts.com/modules/exporting.js"></script>

    <script>
            $(document).ready(function() {

                $('#container_1').highcharts({
                    chart: {
                        zoomType: 'x',
                        spacingRight: 20
                    },
                    title: {
                        text: '<?=$title?>',
                        x: -20 //center
                    },
                    subtitle: {
                        text: 'Click to zoom',
                        x: -20
                    },
//                        xAxis: {
//                            categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
//                        },
//                    yAxis: {
//                        title: {
//                            text: 'Temperature (C)'
//                        },
//                        plotLines: [{
//                            value: 0,
//                            width: 1,
//                            color: '#808080'
//                        }]
//                    },
//                    tooltip: {
//                        valueSuffix: 'C'
//                    },
//                    legend: {
//                        layout: 'vertical',
//                        align: 'right',
//                        verticalAlign: 'middle',
//                        borderWidth: 0
//                    },
                    plotOptions: {
                        area: {
<?php
if ($stacked)
    echo "                            stacking: 'normal',
    ";
?>
//                            fillColor: {
//                                linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1},
//                                stops: [
//                                    [0, Highcharts.getOptions().colors[0]],
//                                    [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
//                                ]
//                            },
                            lineWidth: 1,
                            marker: {
                                enabled: false
                            },
                            shadow: false,
                            states: {
                                hover: {
                                    lineWidth: 1
                                }
                            },
                            threshold: null
                        }
                    },
<?php
if ($percentage)
echo '                    yAxis: {
                        max: 100,
                        min: 0
                    },';
?>

                    series: [
<?php
foreach ($fields as $field) {
echo "{
type: 'area',
name: '$field',
data: [".join(',', array_column($rows, $field))."]
},\n";
}
?>
                    ]
                });
            });

        </script>

    </head>
    <body>

        <div id="content" style="width: 80%;">
            <div id="container_1" style="min-width: 310px; height: 400px; margin: 0 auto"></div>
        </div>

    </body>

</html>



