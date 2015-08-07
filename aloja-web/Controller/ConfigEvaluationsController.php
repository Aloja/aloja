<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class ConfigEvaluationsController extends AbstractController
{
    public function configImprovementAction()
    {
        $db = $this->container->getDBUtils();

        $this->buildFilters();
        $this->buildGroupFilters();
        $whereClause = $this->filters->getWhereClause();
       
        $rows_config = '';
        try {
           	$concat_config = Utils::getConfig($this->filters->getGroupFilters());

            $filter_execs = DBUtils::getFilterExecs();
            $order_conf = 'LENGTH(conf), conf';

            //get configs first (categories)
            $query = "SELECT count(*) num, concat($concat_config) conf from execs e
                      JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause
                      GROUP BY conf ORDER BY $order_conf #AVG(exe_time)
                      ;";

            $rows_config = $db->get_rows($query);

            $height = 600;

            if (count($rows_config) > 4) {
                $num_configs = count($rows_config);
                $height = round($height + (10*($num_configs-4)));
            }

            //get the result rows
            //#(select CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) FROM execs e WHERE bench = e.bench $filter_execs $whereClause) P50_ALL_exe_time,
            $query = "SELECT #count(*),
            		  e.id_exec,
                      concat($concat_config) conf, bench,
                      avg(exe_time) AVG_exe_time,
                      #max(exe_time) MAX_exe_time,
                      min(exe_time) MIN_exe_time,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 50/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P50_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 95/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P95_exe_time`,
                      #CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(exe_time ORDER BY exe_time SEPARATOR ','), ',', 05/100 * COUNT(*) + 1), ',', -1) AS DECIMAL) AS `P05_exe_time`,
                      (select AVG(exe_time) FROM execs WHERE bench = e.bench $whereClause) AVG_ALL_exe_time,
                      #(select MAX(exe_time) FROM execs WHERE bench = e.bench $whereClause) MAX_ALL_exe_time,
                      #(select MIN(exe_time) FROM execs WHERE bench = e.bench $whereClause) MIN_ALL_exe_time,
                      'none'
                      from execs e JOIN clusters USING (id_cluster)
                      WHERE 1 $filter_execs $whereClause
                      GROUP BY conf, bench order by bench, $order_conf;";

            $rows = $db->get_rows($query);

            if ($rows) {
                //print_r($rows);
            } else {
                throw new \Exception("No results for query!");
            }

        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
        }

        $categories = '';
        $count = 0;
        $confOrders = array();
        foreach ($rows_config as $row_config) {
            $categories .= "'{$row_config['conf']} #{$row_config['num']}',";
            $count += $row_config['num'];
            $confOrders[] = $row_config['conf'];
        }

        $series = '';
        $bench = '';
        if ($rows) {
            $seriesIndex = 0;
            foreach ($rows as $row) {
                //close previous serie if not first one
                if ($bench && $bench != strtolower($row['bench'])) {
                    $series .= "]
                        }, ";
                }
                //starts a new series
                if ($bench != strtolower($row['bench'])) {
                    $seriesIndex = 0;
                    $bench = strtolower($row['bench']);
                    $series .= "
                        {
                            name: '".strtolower($row['bench'])."',
                                data: [";
                }
                while($row['conf'] != $confOrders[$seriesIndex]) {
                    $series .= "[null],";
                    $seriesIndex++;
                }
                $series .= "['{$row['conf']}',".
                    //round((($row['AVG_exe_time']-$row['MIN_ALL_exe_time'])/(0.0001+$row['MAX_ALL_exe_time']-$row['MIN_ALL_exe_time'])), 3).
                    //round(($row['AVG_exe_time']), 3).
                    round(($row['AVG_ALL_exe_time']/$row['AVG_exe_time']), 3). //
                    "],";
                $seriesIndex++;

            }
            //close the last series
            $series .= "]
                    }, ";
        }

        return $this->render ( 'config_improvement/config_improvement.html.twig', array (
                'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
                'highcharts_js' => HighCharts::getHeader(),
                'categories' => $categories,
                'series' => $series,
            )
        );
    }

    public function bestConfigAction() {
        $db = $this->container->getDBUtils ();
        $this->buildFilters(array('bench' =>
            array('table' => 'execs', 'default' => array('terasort'),
                'type' => 'selectOne'))
        );

        $bestexec = '';
        $cluster = '';
        try {
            $whereClause = $this->filters->getWhereClause();

            $order_type = Utils::get_GET_string ( 'ordertype' );
            if (! $order_type)
                $order_type = 'exe_time';

            $filterExecs = DBUtils::getFilterExecs();

            // get the result rows
            $query = "SELECT (e.exe_time/3600)*c.cost_hour as cost, e.id_exec,e.exec,e.bench,e.exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version, c.*
    		from execs e
    		join clusters c USING (id_cluster)
    		WHERE 1 $filterExecs $whereClause
    		GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
    		ORDER BY $order_type ASC;";

            $this->getContainer ()->getLog ()->addInfo ( 'BestConfig query: ' . $query );
            $rows = $db->get_rows ( $query );

            if (! $rows) {
                throw new \Exception ( "No results for query!" );
            }
            
            $minCost = -1;
            $minCostIdx = 0;
            
            if ($rows) {
            	$bestexec = $rows[0];
            	if($order_type == 'cost') {
	            	foreach($rows as $key => &$exec) {
	            		$cost = Utils::getExecutionCost($exec,$exec['cost_hour'],$exec['cost_remote'],$exec['cost_SSD'],$exec['cost_IB']);
                        if(($cost < $minCost) || $minCost == -1) {
	            			$minCost = $cost;
	            			$minCostIdx = $key;
	            		}
	            	}
	            	$bestexec = $rows[$minCostIdx];
            	}

                $cluster=$bestexec['name'];
                Utils::makeExecInfoBeauty($bestexec);
            }
        } catch ( \Exception $e ) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        return $this->render ( 'bestconfig/bestconfig.html.twig', array (
            'title' => 'Best Run Configuration',
            'bestexec' => $bestexec,
            'cluster' => $cluster,
            'order_type' => $order_type
        ));
    }

    public function paramEvaluationAction() {
        $db = $this->container->getDBUtils ();
        $this->buildFilters();
        $whereClause = $this->filters->getWhereClause();

        $categories = '';
        $series = '';
        try {
           /* if(!(isset($_GET['benchs']))) {
                $_GET['benchs'] = array('wordcount', 'terasort', 'sort');
            }*/

            $paramEval = (isset($_GET['parameval']) && $_GET['parameval'] != '') ? $_GET['parameval'] : 'maps';
            $minExecs = (isset($_GET['minexecs'])) ? $_GET['minexecs'] : -1;
            $minExecsFilter = "";
            if($minExecs > 0)
                $minExecsFilter = "HAVING COUNT(*) > $minExecs";

            $filter_execs = DBUtils::getFilterExecs();

            $paramOptions = array();
            foreach($options[$paramEval] as $option) {
                if($paramEval == 'id_cluster')
                    $paramOptions[] = $option['name'];
                else if($paramEval == 'comp')
                    $paramOptions[] = Utils::getCompressionName($option[$paramEval]);
                else if($paramEval == 'net')
                    $paramOptions[] = Utils::getNetworkName($option[$paramEval]);
                else if($paramEval == 'disk')
                    $paramOptions[] = Utils::getDisksName($option[$paramEval]);
                else if($paramEval == 'vm_ram')
                    $paramOptions[] = Utils::getBeautyRam($option['vm_RAM']);
                else
                    $paramOptions[] = $option[$paramEval];
            }

            $benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause GROUP BY $paramEval, bench order by $paramEval");

            // get the result rows
            $query = "SELECT count(*) as count, $paramEval, e.id_exec, exec as conf, bench, ".
                "exe_time, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time ".
                "from execs e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause".
                "GROUP BY $paramEval, bench $minExecsFilter order by bench,$paramEval";

            $rows = $db->get_rows ( $query );

            if (!$rows) {
                throw new \Exception ( "No results for query!" );
            }

            $categories = '';
            $arrayBenchs = array();
            foreach ( $paramOptions as $param ) {
                $categories .= "'$param".Utils::getParamevalUnit($paramEval)."',";
                foreach($benchOptions as $bench) {
                    $arrayBenchs[$bench['bench']][$param] = null;
                }
            }

            $series = array();
            foreach($rows as $row) {
                if($paramEval == 'comp')
                    $row[$paramEval] = Utils::getCompressionName($row['comp']);
                else if($paramEval == 'id_cluster') {
                    $row[$paramEval] = Utils::getClusterName($row[$paramEval],$db);
                } else if($paramEval == 'net')
                    $row[$paramEval] = Utils::getNetworkName($row['net']);
                else if($paramEval == 'disk')
                    $row[$paramEval] = Utils::getDisksName($row['disk']);
                else if($paramEval == 'vm_ram')
                    $row[$paramEval] = Utils::getBeautyRam($row['vm_ram']);

                $arrayBenchs[strtolower($row['bench'])][$row[$paramEval]]['y'] = round((int)$row['avg_exe_time'],2);
                $arrayBenchs[strtolower($row['bench'])][$row[$paramEval]]['count'] = (int)$row['count'];
            }

            foreach($arrayBenchs as $key => $arrayBench)
            {
                $series[] = array('name' => $key, 'data' => array_values($arrayBench));
            }
            $series = json_encode($series);
        } catch ( \Exception $e ) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        return $this->render ('parameval/parameval.html.twig', array (
            'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
            'categories' => $categories,
            'series' => $series,
            'paramEval' => $paramEval
        ) );
    }
}
