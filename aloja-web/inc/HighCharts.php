<?php

namespace alojaweb\inc;

class HighCharts
{
    protected $fields;
    protected $rows;
    protected $stacked;
    protected $percentage;
    protected $guid;
    protected $title;
    protected $negative_values;
    protected $max;
    protected $min;
    protected $maxX;

    public static $header =
'        <script src="//code.highcharts.com/highcharts.js"></script>
        <script src="//code.highcharts.com/highcharts-more.js"></script>
        <script src="//code.highcharts.com/modules/exporting.js"></script>
        <script src="//code.highcharts.com/modules/offline-exporting.js"></script>
        <script src="//code.highcharts.com/modules/no-data-to-display.js"></script>
        <script src="js/datatables/extras/export-csv/export-csv.js"></script>
        <script src="js/datatables/extras/draggable-legend/draggable-legend.js"></script>
';
    /*
     DOWN sample http://jsfiddle.net/sveinn_st/FMJAL/
    <script src="//rawgithub.com/RolandBanguiran/highcharts-scalable-yaxis/master/scalable-yaxis.js"></script>
     */

    public function HighCharts()
    {
    }

    public static function getHeader()
    {
        return self::$header;
    }

    public function getContainer($width)
    {
        return '<div id="'.$this->getGuid().'" align="left" style="width: '.$width.'%; height: 250px;"></div>'."\n";
    }

    public function getGuid()
    {
        if (!$this->guid) $this->guid = 'container_'.md5($this->title);
        return $this->guid;
    }

    public function setTitle($title)
    {
        $this->title = $title;
    }

    public function getTitle()
    {
        return $this->title;
    }

    public function setFields($fields)
    {
        $this->fields = $fields;
    }

    public function getFields()
    {
        return $this->fields;
    }

    public function setPercentage($percentage)
    {
        $this->percentage = $percentage;
    }

    public function getPercentage()
    {
        return $this->percentage;
    }

    public function setRows($rows)
    {
        $this->rows = $rows;
    }

    public function getRows()
    {
        return $this->rows;
    }

    public function setStacked($stacked)
    {
        $this->stacked = $stacked;
    }

    public function getStacked()
    {
        return $this->stacked;
    }

    public function setNegativeValues($negative_values)
    {
        $this->negative_values = $negative_values;
    }

    public function getNegativeValues()
    {
        return $this->negative_values;
    }

    public function setMax($max)
    {
        $this->max = $max;
    }

    public function getMax()
    {
        return $this->max;
    }

    public function setMin($min)
    {
        $this->min = $min;
    }

    public function getMin()
    {
        return $this->min;
    }

    public function getMaxYAxis()
    {
        $return ='';
        if ($this->getPercentage()) {
            $return = "max: ".round($this->getPercentage()*1).",";
        } elseif ($this->getMax()) {
            $return = "max: ".round($this->getMax()*1).",";
        }

        return $return;
    }

    public function setMaxX($maxX)
    {
        $this->maxX = $maxX;
    }

    public function getMaxX()
    {
        return $this->maxX;
    }

    public function getSetMax()
    {
        if(($value = Utils::get_GET_string('setmax_'.$this->getGuid())))
            return $value;
        else {
        	$max ='';
        	if ($this->getPercentage()) {
        		$max = round($this->getPercentage()*1);
        	} elseif ($this->getMax()) {
        		$max = round($this->getMax()*1);
        	}
        	
        	return $max;
        }   
    }
    
    public function getChartJS()
    {
        $JS =

"               window.chart_{$this->getGuid()} = new Highcharts.Chart({
                    chart: {
                        zoomType: 'x',
                        spacingRight: 20,
                        renderTo: '{$this->getGuid()}'
                    },
                    credits: {
                        enabled: false
                    },
                    title: {
                        useHTML: true,
                        text: '{$this->getTitle()}',
                        //align: 'left',
                        style: {
                            color: '#3E576F',
                            fontSize: '14px'
                        }
                        //x: -20 //center
                    },
                    subtitle: {
                        text: 'Click and drag to zoom',
                        style: {
                            fontSize: '10px'
                        }
                    },";

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

        $JS .= "                    plotOptions: {
                        area: {\n";

        if ($this->getStacked()) $JS .=
"                        stacking: 'normal',\n";

//                            fillColor: {
//                                linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1},
//                                stops: [
//                                    [0, Highcharts.getOptions().colors[0]],
//                                    [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
//                                ]
//                            },
        $JS .=
"                        lineWidth: 1,
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
                    },";
        $JS .= "
                    yAxis: {
                        title: {
                            text: ''
                        },
                        //scalable: false,
                        ".$this->getMaxYAxis()."
                        ".(!$this->getNegativeValues() ? "min: 0":"")."
                    },
                    xAxis: {
                        title: {
                            text: 'Execution time in seconds'
                        }".($this->getMaxX() ? ",\n\t\t\tmax: {$this->getMaxX()}":'')."
                    },
                    series: [";
        if ($this->getFields() && $this->getRows()) {
            foreach ($this->getFields() as $field) {
                $JS .= "
                    {
                        type: 'area',
                        name: '$field',".
                        "data: [".$this->generateData($field)."]
                    },\n";
            }
        }

        $JS .= "
                    ]
                });
";

        return $JS;
    }

    /**
     * Select the data format XY or Y
     * @param $field
     * @return string
     */
    private function generateData($field)
    {
        $return = '';
        if (isset(current($this->getRows())['time'])) {
            //"data: [[161.2, 0], [167.5, 10], [159.5, 30],  ]".
            foreach ($this->getRows() as $row) {
                $return .= "[{$row['time']},{$row[$field]}],";
            }
            $return = substr($return, 0, -1); //remove trailling coma

        } else {
            //data: [0,0,0,0,1,1,1]
            $return = join(',', array_column($this->getRows(), $field));
        }

        return $return;
    }

}
