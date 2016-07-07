<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;

class CostPerfEvaluationController extends AbstractController
{
	private $whereClause;

	private $clusterCosts;

	//Need to get container since overwritting parent constructor
	public function __construct($container) {
		parent::__construct($container);

		//All this screens are using this custom filters
		$this->buildFilters(array('bench' =>
			array('default' => array('terasort'),
				'type' => 'selectOne', 'label' => 'Benchmark:')));
		$this->whereClause = $this->filters->getWhereClause();
		$this->clusterCosts = Utils::generateCostsFilters($this->container->getDBUtils());
	}
	
    public function costPerfEvaluationAction()
    {
        $filter_execs = DBUtils::getFilterExecs();
        $dbUtils = $this->container->getDBUtils();
        
        try {
            /*
             * 1. Get execs and cluster associated costs
             * 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
             * 3. Calculate max and minimum costs
             * 4. calculate max and minimum exe times
             * 5. Normalize costs and exe times
             * 6. Print results
             */

            $minCost = -1;
            $maxCost = 0;
            $minExeTime = -1;
            $maxExeTime = 0;


            $execs = "SELECT e.id_exec,e.id_cluster,e.exec,e.bench,e.exe_time,e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
                e.valid,e.filter,e.outlier,e.perf_details,e.exec_type,e.datasize,e.scale_factor,e.run_num,
                c.* FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
                LEFT JOIN aloja_ml.predictions p USING (id_exec)
                WHERE 1 $filter_execs $this->whereClause ORDER BY rand() LIMIT 500";

			$mlWhere = $this->filters->getWhereClause(array('ml_predictions' => 'e'));

			$execsPred = "SELECT e.id_exec,e.id_cluster,CONCAT(CONCAT(CONCAT(CONCAT('pred','_'),e.bench),'_'),c.name) as 'exec' ,e.bench,e.exe_time, e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
                e.valid,e.filter,e.outlier,'null' as perf_details, 'prediction' as exec_type, 'null' as datasize,'null' as scale_factor,'null' as run_num,
                c.* FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
                WHERE 1 $filter_execs $mlWhere ORDER BY rand() LIMIT 500";

			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));
			if($params['uobsr'] && $params['upred']) {
				$execs = "($execs) UNION ($execsPred)";
			} else if($params['upred']) {
				$execs = "$execsPred";
			}

            $execs = $dbUtils->get_rows($execs);
            if(!$execs)
                throw new \Exception("No results for query!");

            foreach($execs as &$exec) {
                $exec['cost_std'] = Utils::getExecutionCost($exec, $this->clusterCosts);

                if($exec['cost_std'] > $maxCost)
                    $maxCost = $exec['cost_std'];
                if($exec['cost_std'] < $minCost || $minCost == -1)
                    $minCost = $exec['cost_std'];

                if($exec['exe_time']<$minExeTime || $minExeTime == -1)
                    $minExeTime = $exec['exe_time'];
                if($exec['exe_time']>$maxExeTime)
                    $maxExeTime = $exec['exe_time'];
            }
        } catch (\Exception $e) {
            $this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
        }

//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,

        $seriesData = '';
        foreach ($execs as $exec) {
        	$exeTimeStd = 0.01;
        	$costTimeStd = 0.01;
        	if(count($execs) > 1) {
        		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
        		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
        		
        		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
        		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
        	}

            $seriesData .= "{
            name: '" . $exec['exec'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . "]], idexec: ${exec['id_exec']}},";
        }

        $clusters = $dbUtils->get_rows("SELECT * FROM aloja2.clusters WHERE id_cluster IN (SELECT DISTINCT id_cluster FROM aloja2.execs e WHERE 1 $filter_execs);");

        return $this->render('costPerfEvaluationViews/perf_by_cost.html.twig', array(
            'selected' => 'Cost Evaluation',
            'highcharts_js' => HighCharts::getHeader(),
			'clusterCosts' => $this->clusterCosts,
            'seriesData' => $seriesData,
            'title' => 'Normalized Cost by Performance Evaluation of Hadoop Executions',
            'clusters' => $clusters,
            'select_multiple_benchs' => false
        ));
    }

    public function clusterCostEffectivenessAction()
    {
        $db = $this->container->getDBUtils ();

        $data = array();

        $filter_execs = DBUtils::getFilterExecs();

		$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
		$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
		$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);

		$whereML = $this->filters->getWhereClause(array('ml_predictions' => 'e'));
		$whereML = str_replace("p.","e.",$whereML);
		$innerQueryML = str_replace("e.","e2.",$whereML);
		$innerQueryML = str_replace("c.","c2.",$innerQueryML);

//        $query = "SELECT t.scount as count,e.id_exec,e.id_cluster,e.exec,e.bench,e.exe_time,e.start_time,
//                e.end_time,e.net,e.disk,e.bench_type,
//                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
//                e.valid,e.filter,e.outlier,e.perf_details,e.exec_type,e.datasize,e.scale_factor,e.run_num,
//                c.*,c.name as 'name' from execs e JOIN aloja2.clusters c USING (id_cluster)
// 				  LEFT JOIN aloja_ml.predictions p USING (id_exec)
//						INNER JOIN (SELECT count(*) as scount, MIN(e2.exe_time) minexe FROM aloja2.execs e2 JOIN aloja2.clusters c2 USING(id_cluster)
//									LEFT JOIN aloja_ml.predictions p2 USING (id_exec)
//									 WHERE  1 $innerQueryWhere GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
//        		  t ON e.exe_time = t.minexe WHERE 1 $filter_execs $this->whereClause GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

        $query = "SELECT count(*) as count,e.id_exec,e.id_cluster,e.exec,e.bench,avg(e.exe_time) exe_time,e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
                e.valid,e.filter,e.outlier,e.perf_details,e.exec_type,e.datasize,e.scale_factor,e.run_num,
                c.*,c.vm_size as 'name' from execs e JOIN aloja2.clusters c USING (id_cluster)
 				  LEFT JOIN aloja_ml.predictions p USING (id_exec)
WHERE 1 $filter_execs $this->whereClause GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";


		$queryPredicted = "SELECT t.scount as count, e.id_exec,e.id_cluster,e.exec, CONCAT(CONCAT('pred','_'),e.bench) as 'bench',e.exe_time, e.start_time,
                e.end_time,e.net,e.disk,e.bench_type,
                e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.zabbix_link,e.hadoop_version,
                e.valid,e.filter,e.outlier,'null' as perf_details, 'prediction' as exec_type, 'null' as datasize,'null' as scale_factor,'null' as run_num,
                c.*,CONCAT('pred_', c.name) as 'name' from aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
						INNER JOIN (SELECT count(*) as scount, MIN(e2.exe_time) minexe FROM aloja_ml.predictions e2 JOIN aloja2.clusters c2 USING(id_cluster)
									 WHERE  1 $innerQueryML GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
        		  t ON e.exe_time = t.minexe WHERE 1 $filter_execs $whereML GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

		$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));
		if($params['uobsr'] && $params['upred']) {
			$query = "($query) UNION ($queryPredicted)";
		} else if($params['upred']) {
			$query = "$queryPredicted";
		}

    	try {
    		$rows = $db->get_rows($query);
    		$minCost = -1;
    		$minCostKey = 0;
    		$sumCount = 0;
    		$previousCluster = "none";
    		$bestExecs = array();
    		foreach($rows as $key => &$row) {
    			$cost = Utils::getExecutionCost($row, $this->clusterCosts);
    			$row['cost_std'] = $cost;
    			if($previousCluster != "none" && $previousCluster != $row['name']) {
    				$min = $rows[$minCostKey];
    				array_push($bestExecs,$min);
    				$clusterDesc = "${min['datanodes']} datanodes,  ".round($min['vm_RAM'],0)." GB memory, ${min['vm_OS']}, ${min['provider']} ${min['type']}";
    				$set = array(round($min['exe_time'],0), round($minCost,2), $sumCount);
    				array_push($data, array('data' => array($set), 'name' => $min['name'], 'clusterdesc' => $clusterDesc, 'counts' => $sumCount));
    				$previousCluster = $row['name'];
    				$minCost = -1;
    				$sumCount = 0;
    			} else if($previousCluster == "none")
    				$previousCluster = $row['name'];
    			
    			if($minCost == -1 || $cost < $minCost) {
    				$minCost = $cost;
    				$minCostKey = $key;
    			}
    			
    			$sumCount += $row['count'];
    		}
    		$min = $rows[$minCostKey];
    		array_push($bestExecs,$min);
    		$clusterDesc = "${min['datanodes']} datanodes,  ".round($min['vm_RAM'],0)." GB memory, ${min['vm_OS']}, ${min['provider']} ${min['type']}";
    		$set = array(round($min['exe_time'],0), round($minCost,2), $sumCount);
    		array_push($data, array('data' => array($set), 'name' => $min['name'], 'clusterdesc' => $clusterDesc, 'counts' => $sumCount));
    		
    		//This is to order the cluster by cost-effectiveness (ascending)
    		//This way the labels in the cart are ordered
    		usort($data,function($a, $b) {
                $costA = $a['data'][0][1];
                $costB = $b['data'][0][1];
                //$costA = $a['data'][0][0] * $a['data'][0][1];
    			//$costB = $b['data'][0][0] * $b['data'][0][1];
    			return $costA >= $costB;
    		});
    		
    		//Sorting clusters by size
    		usort($bestExecs, function($a,$b) {
                return $a['cost_std'] > $b['cost_std'];
    			//return ($a['cost_std']*$a['exe_time']) > ($b['cost_std']*$b['exe_time']);
    		});

			$clusters = $db->get_rows("SELECT * FROM aloja2.clusters WHERE id_cluster IN (SELECT DISTINCT id_cluster FROM aloja2.execs e WHERE 1 $filter_execs);");

		} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
    	}

		return $this->render('costPerfEvaluationViews/clustercosteffectiveness.html.twig', array(
    			'series' => json_encode($data),
    			'select_multiple_benchs' => false,
                'bestExecs' => $bestExecs,
				'clusterCosts' => $this->clusterCosts,
				'clusters' => $clusters,
				'highcharts_js' => HighCharts::getHeader(),
    		));
    }
    
    public function costPerfClusterEvaluationAction()
    {
    	$filter_execs = DBUtils::getFilterExecs();
    	$dbUtils = $this->container->getDBUtils();
		
    	try {
    		/*
    		 * 1. Get execs and cluster associated costs
    		* 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
    		* 3. Calculate max and minimum costs
    		* 4. calculate max and minimum exe times
    		* 5. Normalize costs and exe times
    		* 6. Print results
    		*/
    
    		$minCost = -1;
    		$maxCost = 0;
    		$minExeTime = -1;
    		$maxExeTime = 0;
    		$sumCount = 0;

			$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
			$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
			$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);

			$whereML = $this->filters->getWhereClause(array('ml_predictions' => 'e'));
			$whereML = str_replace("p.","e.",$whereML);
			$innerQueryML = str_replace("e.","e2.",$whereML);
			$innerQueryML = str_replace("c.","c2.",$innerQueryML);

    		$execs = "SELECT e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,e.exec,e.run_num, c.name as clustername,c.*
    		  FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
    		  LEFT JOIN aloja_ml.predictions p USING (id_exec)
      		  INNER JOIN (SELECT MIN(e2.exe_time) minexe FROM aloja2.execs e2 JOIN aloja2.clusters c2 USING(id_cluster)
      		  				LEFT JOIN aloja_ml.predictions p2 USING (id_exec)
        					 WHERE  1 ".DBUtils::getFilterExecs('e2')." $innerQueryWhere GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $this->whereClause
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

			$execsPred = "SELECT e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,CONCAT(CONCAT(CONCAT(CONCAT('pred','_'),e.bench),'_'),c.name) as 'exec', c.name as clustername,c.*
    		  FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
      		  INNER JOIN (SELECT MIN(e2.exe_time) minexe FROM aloja_ml.predictions e2 JOIN aloja2.clusters c2 USING(id_cluster)
        					 WHERE  1 ".DBUtils::getFilterExecs('e2')." $innerQueryML GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $whereML
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));
			if($params['uobsr'] && $params['upred']) {
				$execs = "($execs) UNION ($execsPred)";
			} else if($params['upred']) {
				$execs = "$execsPred";
			}

    		$execs = $dbUtils->get_rows($execs);
    		if(!$execs)
    			throw new \Exception("No results for query!");
    
    		foreach($execs as &$exec) {
				$exec['cost_std'] = Utils::getExecutionCost($exec, $this->clusterCosts);
    
    			if($exec['cost_std'] > $maxCost)
    				$maxCost = $exec['cost_std'];
    			if($exec['cost_std'] < $minCost || $minCost == -1)
    				$minCost = $exec['cost_std'];
    
    			if($exec['exe_time']<$minExeTime || $minExeTime == -1)
    				$minExeTime = $exec['exe_time'];
    			if($exec['exe_time']>$maxExeTime)
    				$maxExeTime = $exec['exe_time'];
    		}
    	} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
    	}
    
    	//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
    	//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
    
    	$seriesData = '';
    	foreach ($execs as $exec) {
    		$exeTimeStd = 0.01;
    		$costTimeStd = 0.01;
    		if(count($execs) > 1) {
	    		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
	    		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
	    		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
	    		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
    		}
    
    		$seriesData .= "{
            name: '" . $exec['exec'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . ", ". round($costTimeStd*$exeTimeStd, 3) ."]]
        },";
    	}
    
    	$clusters = $dbUtils->get_rows("SELECT * FROM aloja2.clusters c WHERE id_cluster IN (SELECT DISTINCT(id_cluster) FROM aloja2.execs e WHERE 1 $filter_execs);");
    
    	//Sorting clusters by size
    	usort($execs, function($a,$b) {
    		return ($a['cost_std']) > ($b['cost_std']);
    	});
    	return $this->render('costPerfEvaluationViews/perf_by_cost_cluster.html.twig', array(
    			'highcharts_js' => HighCharts::getHeader(),
				'clusterCosts' => $this->clusterCosts,
    			'seriesData' => $seriesData,
    			'execs' => $execs,
    			'title' => 'Normalized Cost by Performance Evaluation of Hadoop Executions',
    			'clusters' => $clusters,
    	));
    }
    
    public function BestCostPerfClusterEvaluationAction()
    {
    	$filter_execs = DBUtils::getFilterExecs();
    	$dbUtils = $this->container->getDBUtils();

    	try {
    		

    		/*
    		 * 1. Get execs and cluster associated costs
    		* 2. For each exec calculate cost, exe_time/3600 * (cost_cluster + clust_remote|ssd|ib|eth)
    		* 3. Calculate max and minimum costs
    		* 4. calculate max and minimum exe times
    		* 5. Normalize costs and exe times
    		* 6. Print results
    		*/
    
    		$minCost = -1;
    		$maxCost = 0;
    		$minExeTime = -1;
    		$maxExeTime = 0;

			$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
			$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
			$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);

			$whereML = $this->filters->getWhereClause(array('ml_predictions' => 'e'));
			$whereML = str_replace("p.","e.",$whereML);
			$innerQueryML = str_replace("e.","e2.",$whereML);
			$innerQueryML = str_replace("c.","c2.",$innerQueryML);

    		$execs = "SELECT t.scount as count, e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,e.exec, c.name as clustername,c.*,c.name
    		  FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
    		  LEFT JOIN aloja_ml.predictions p USING (id_exec)
      		  INNER JOIN (SELECT count(*) as scount, MIN(e2.exe_time) minexe FROM aloja2.execs e2 JOIN aloja2.clusters c2 USING(id_cluster)
        					 LEFT JOIN aloja_ml.predictions p2 USING (id_exec) WHERE  1 ".DBUtils::getFilterExecs('e2')." $innerQueryWhere GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $this->whereClause
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

			$execsPred = "SELECT t.scount as count, e.exe_time,e.net,e.disk,e.bench,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,e.exec, c.name,c.*,CONCAT('pred_',c.name) as name
    		  FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
      		  INNER JOIN (SELECT count(*) as scount, MIN(e2.exe_time) minexe FROM aloja_ml.predictions e2 JOIN aloja2.clusters c2 USING(id_cluster)
        					WHERE  1 ".DBUtils::getFilterExecs('e2')." $innerQueryML GROUP BY c2.name,e2.net,e2.disk ORDER BY c2.name ASC)
        		t ON e.exe_time = t.minexe  WHERE 1 $filter_execs $whereML
    		  GROUP BY c.name,e.net,e.disk ORDER BY c.name ASC";

			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));
			if($params['uobsr'] && $params['upred']) {
				$execs = "($execs) UNION ($execsPred)";
			} else if($params['upred']) {
				$execs = "$execsPred";
			}

    		$execs = $dbUtils->get_rows($execs);
    		if(!$execs)
    			throw new \Exception("No results for query!");
    
    		$minCostKey = 0;
    		$tmpMinCost = -1;
    		$previousCluster = "none";
    		$bestExecs = array();
    		$sumCount = 0;
    		foreach($execs as $key => &$exec) {
    			if($previousCluster != "none" && $previousCluster != $exec['name']) {
    				$previousCluster = $exec['name'];
    				$tmpMinCost = -1;
    				
    				if($execs[$minCostKey]['cost_std'] > $maxCost)
    					$maxCost = $execs[$minCostKey]['cost_std'];
    				if($execs[$minCostKey]['cost_std'] < $minCost || $minCost == -1)
    					$minCost = $execs[$minCostKey]['cost_std'];
    				
    				if($execs[$minCostKey]['exe_time']<$minExeTime || $minExeTime == -1)
    					$minExeTime = $execs[$minCostKey]['exe_time'];
    				if($execs[$minCostKey]['exe_time']>$maxExeTime)
    					$maxExeTime = $execs[$minCostKey]['exe_time'];
    				
    				$execs[$minCostKey]['countexecs'] = $sumCount;
    				
    				array_push($bestExecs, $execs[$minCostKey]);
    				$sumCount = 0;
    			} else if($previousCluster == "none")
    				$previousCluster = $exec['name'];
    
    			$exec['cost_std'] = Utils::getExecutionCost($exec, $this->clusterCosts);
    			
    			if($tmpMinCost == -1 || $exec['cost_std'] < $tmpMinCost) {
    				$tmpMinCost = $exec['cost_std'];
    				$minCostKey = $key;
    			}
    			
    			$sumCount += $exec['count'];
    		}    		
    		if($execs[$minCostKey]['cost_std'] > $maxCost)
    			$maxCost = $execs[$minCostKey]['cost_std'];
    		if($execs[$minCostKey]['cost_std'] < $minCost || $minCost == -1)
    			$minCost = $execs[$minCostKey]['cost_std'];
    		
    		if($execs[$minCostKey]['exe_time']<$minExeTime || $minExeTime == -1)
    			$minExeTime = $execs[$minCostKey]['exe_time'];
    		if($execs[$minCostKey]['exe_time']>$maxExeTime)
    			$maxExeTime = $execs[$minCostKey]['exe_time'];
    		
    		$execs[$minCostKey]['countexecs'] = $sumCount;
    		array_push($bestExecs, $execs[$minCostKey]);
    	} catch (\Exception $e) {
    		$this->container->getTwig()->addGlobal('message', $e->getMessage() . "\n");
    	}
    
    	//         (exe_time - $min_exe_time)/($max_exe_time - $min_exe_time) exe_time_std,
    	//         ($cost_per_run - $min_cost_per_run)/($max_cost_per_run - $min_cost_per_run) cost_std,
    
    	$seriesData = '';
    	foreach ($bestExecs as $exec) {
    		$exeTimeStd = 0.01;
    		$costTimeStd = 0.01;
    		if(count($bestExecs) > 1) {
	    		$exeTimeStd = ($exec['exe_time'] - $minExeTime)/($maxExeTime - $minExeTime);
	    		$costTimeStd = ($exec['cost_std'] - $minCost)/($maxCost - $minCost);
	    		if($costTimeStd <= 0.01) $costTimeStd = 0.01;
	    		if($exeTimeStd <= 0.01) $exeTimeStd = 0.01;
    		}
    
    		$clusterDesc = "${exec['datanodes']} datanodes,  ".round($exec['vm_RAM'],0)." GB memory, ${exec['vm_OS']}, ${exec['provider']} ${exec['type']}";
    		$seriesData .= "{
            name: '" . $exec['name'] . "',
                data: [[" . round($exeTimeStd, 3) . ", " . round($costTimeStd, 3) . ", ". $exec['countexecs'] ."]],
            clusterdesc: '$clusterDesc', countExecs: '${exec['countexecs']}'
        },";
    	}
    
    	$clusters = $dbUtils->get_rows("SELECT * FROM aloja2.clusters c WHERE id_cluster IN (SELECT DISTINCT(id_cluster) FROM aloja2.execs e WHERE 1 $filter_execs);");

    	//Sorting clusters by size
    	usort($bestExecs, function($a,$b) {
    		return ($a['cost_std']) > ($b['cost_std']);
    	});
    	
    	return $this->render('costPerfEvaluationViews/best_perf_by_cost_cluster.html.twig', array(
    			'highcharts_js' => HighCharts::getHeader(),
    			'clusterCosts' => $this->clusterCosts,
    			'seriesData' => $seriesData,
    			'bestExecs' => $bestExecs,
    			'clusters' => $clusters,
    	));
    }

	public function nodesEvaluationAction()
	{
		$dbUtils = $this->container->getDBUtils();

		return $this->render('costPerfEvaluationViews/nodes_evaluation.html.twig', array_merge(array(
			'highcharts_js' => HighCharts::getHeader()),
			$this->nodesEvalCore("Datanodes",$dbUtils))
		);
	}

	public function datasizesEvaluationAction()
	{
		$dbUtils = $this->container->getDBUtils();

		return $this->render('costPerfEvaluationViews/nodes_evaluation.html.twig', array_merge(array(
				'highcharts_js' => HighCharts::getHeader()),
				$this->nodesEvalCore("Datasize",$dbUtils))
		);
	}

	public function coresEvaluationAction()
	{
		$dbUtils = $this->container->getDBUtils();
		return $this->render('costPerfEvaluationViews/cores_evaluation.html.twig', array_merge(array(
				'highcharts_js' => HighCharts::getHeader()),
				$this->coresEval($dbUtils))
		);
	}

	public function RAMEvaluationAction()
	{
		$dbUtils = $this->container->getDBUtils();
		return $this->render('costPerfEvaluationViews/RAM_evaluation.html.twig', array_merge(array(
				'highcharts_js' => HighCharts::getHeader()),
				$this->RAMEval($dbUtils))
		);
	}

	private function nodesEvalCore($scalabilityType,$dbUtils) {
		$categories = array();
		$series = array();
		$datanodes = array();

		try {
			$filter_execs = DBUtils::getFilterExecs();

			$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
			$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
			$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);
//			$execs = "SELECT c.datanodes as 'category',e.exec_type,c.vm_OS,c.vm_size,(e.exe_time * (c.cost_hour/3600)) as cost,e.exe_time,c.*
//					FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
//					LEFT JOIN aloja_ml.predictions p USING (id_exec)
//					INNER JOIN ( SELECT c2.datanodes as 'category',e2.exec_type,c2.vm_OS,c2.vm_size as vmsize,MIN(e2.exe_time) as minexe
//								from execs e2 JOIN aloja2.clusters c2 USING (id_cluster)
//								LEFT JOIN aloja_ml.predictions p2 USING (id_exec)
//								WHERE 1 $innerQueryWhere GROUP BY c2.datanodes,e2.exec_type,c2.vm_OS,c2.vm_size ) t ON t.minexe = e.exe_time
//					AND t.category = category AND t.vmsize = c.vm_size
//					WHERE 1 $this->whereClause $filter_execs  GROUP BY c.datanodes,e.exec_type,c.vm_OS,c.vm_size
//					ORDER BY c.datanodes ASC,c.vm_OS,c.vm_size DESC";

			$execs = "SELECT c.datanodes as 'category',e.exec_type,c.vm_OS,c.vm_size,(avg(e.exe_time) * (c.cost_hour/3600)) as cost,avg(e.exe_time) exe_time,c.*
					FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions p USING (id_exec)

					WHERE 1 $this->whereClause $filter_execs  GROUP BY c.datanodes,e.exec_type,c.vm_OS,c.vm_size
					ORDER BY c.datanodes ASC,c.vm_OS,c.vm_size DESC";


			$predExecs = "SELECT c.datanodes as 'category','predicted' as 'exec_type',c.vm_OS,c.vm_size,(e.exe_time * (c.cost_hour/3600)) as cost,e.exe_time,c.*
					FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
					INNER JOIN ( SELECT c2.datanodes as 'category','default' as 'exec_type',c2.vm_OS,c2.vm_size as vmsize,MIN(p2.exe_time) as minexe
								from aloja_ml.predictions p2 JOIN aloja2.clusters c2 USING (id_cluster)
								WHERE 1 ".str_replace("e2.","p2.",$innerQueryWhere)." GROUP BY c2.datanodes,exec_type,c2.vm_OS,c2.vm_size ) t ON t.minexe = e.exe_time
					AND t.category = category AND t.vmsize = c.vm_size
					WHERE 1 $this->whereClause $filter_execs  GROUP BY c.datanodes,exec_type,c.vm_OS,c.vm_size
					ORDER BY c.datanodes ASC,c.vm_OS,c.vm_size DESC";

			if($scalabilityType == 'Datasize') {
				$execs = str_replace("c2.datanodes", "e2.datasize",$execs);
				$execs = str_replace("c.datanodes", "e.datasize",$execs);

				$predExecs = str_replace("c2.datanodes", "p2.datasize",$predExecs);
				$predExecs = str_replace("c.datanodes", "e.datasize",$predExecs);
			}

			$params = $this->filters->getFiltersSelectedChoices(array('upred','uobsr'));
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$execs = "($execs) UNION ($predExecs)";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$execs = $predExecs;
			}

			$execs = $dbUtils->get_rows($execs);

			$vmSizes = array();
			$dataNodes = array();
			$vmOS = array();
			$execTypes = array();
			foreach ($execs as &$exec) {
				if (!isset($dataNodes[$exec['category']])) {
					$dataNodes[$exec['category']] = 1;
					$categories[] = $exec['category'];
				}
				if(!isset($vmOS[$exec['vm_OS']]))
					$vmOS[$exec['vm_OS']] = 1;
				if(!isset($execTypes[$exec['exec_type']]))
					$execTypes[$exec['exec_type']] = 1;


				//Change VM names for SaaS tests
				if($scalabilityType != 'Datasize') {
					if (strstr($exec['vm_size'],'DWU')) {
						$vm_name = preg_replace('/\d+DWU/', 'DWU', $exec['vm_size']); //for DW
					} else if (strstr($exec['vm_size'],'RS')){
						$vm_name = preg_replace('/RS-+\d+/', 'RS-',  $exec['vm_size']);
					} else if (strstr($exec['vm_size'],'EMR')){
						$vm_name = preg_replace('/EMR-+\d+/', 'EMR-',  $exec['vm_size']);
					} else if (strstr($exec['vm_size'],'CBD')){
						$vm_name = substr($exec['vm_size'],0, 14);
					} else if (strstr($exec['vm_size'],'HDI')){
						$vm_name = substr($exec['vm_size'],0, 6);
					} else if (strstr($exec['vm_size'],'AU')){
						$vm_name = preg_replace('/\d+AU/', 'AU',  $exec['vm_size']);
					} else if (strstr($exec['vm_size'],'M100')){
						$vm_name = 'M100';
					} else {
						$vm_name = $exec['vm_size'];
					}
				} else {
					$vm_name = $exec['vm_size'];
				}

				$vmSizes[$vm_name][$exec['exec_type']][$exec['vm_OS']][$exec['category']] = array(round($exec['exe_time'],2), round($exec['cost'],2));
			}

			$i = 0;
			$seriesColors = array('#7cb5ec', '#434348', '#90ed7d', '#f7a35c', '#8085e9',
				'#f15c80', '#e4d354', '#2b908f', '#f45b5b', '#91e8e1');
			foreach($vmSizes as $vmSize => $value) {
				foreach($execTypes as $execType => $typevalue) {
					foreach ($vmOS as $OS => $osvalue) {
						if (isset($vmSizes[$vmSize][$execType][$OS])) {
							if ($i == sizeof($seriesColors))
								$i = 0;
							$costSeries = array('name' => "$vmSize ", 'type' => 'spline', 'dashStyle' => 'longdash', 'yAxis' => 0, 'data' => array(), 'tooltip' => array('valueSuffix' => ' US$'), 'color' => $seriesColors[$i]);
							$timeSeries = array('name' => "$vmSize ", 'type' => 'spline', 'yAxis' => 1, 'data' => array(), 'tooltip' => array('valueSuffix' => ' s'), 'color' => $seriesColors[$i++]);
							foreach ($dataNodes as $datanode => $dvalue) {
								$datanodes[] = $datanode;
								if (!isset($value[$execType][$OS][$datanode])) {
									$costSeries['data'][] = "null";
									$timeSeries['data'][] = "null";
								} else {
									$costSeries['data'][] = $value[$execType][$OS][$datanode][1];
									$timeSeries['data'][] = $value[$execType][$OS][$datanode][0];
								}
							}
							$series[] = $timeSeries;
							$series[] = $costSeries;
						}
					}
				}
			}
		} catch(\Exception $e) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		}

		if($scalabilityType == 'Datasize') {
			foreach ($categories as &$category) {
				$category = Utils::beautifyDatasize($category);
			}
		}

		return array(
			'categories' => json_encode($categories),
			'seriesData' => str_replace('"null"','null',json_encode($series)),
			'datanodess' => $datanodes,
			'scalabilityType' => $scalabilityType
		);
	}

	private function coresEval($dbUtils) {
		$categories = array();
		$series = array();
		$datanodes = array();

		try {
			$filter_execs = DBUtils::getFilterExecs();

			$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
			$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
			$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);

			$execs = "SELECT if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)) as 'category',e.exec_type,c.vm_OS,c.vm_size,(avg(e.exe_time) * (c.cost_hour/3600)) as cost,avg(e.exe_time) exe_time,c.*
					FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions p USING (id_exec)

					WHERE 1 $this->whereClause $filter_execs  GROUP BY if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)),e.exec_type,c.vm_OS,c.vm_size
					ORDER BY if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)) ASC,c.vm_OS,c.vm_size DESC";


			$predExecs = "SELECT if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)) as 'category','predicted' as 'exec_type',c.vm_OS,c.vm_size,(e.exe_time * (c.cost_hour/3600)) as cost,e.exe_time,c.*
					FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
					INNER JOIN ( SELECT (c2.vm_cores*c2.datanodes) as 'category','default' as 'exec_type',c2.vm_OS,c2.vm_size as vmsize,MIN(p2.exe_time) as minexe
								from aloja_ml.predictions p2 JOIN aloja2.clusters c2 USING (id_cluster)
								WHERE 1 ".str_replace("e2.","p2.",$innerQueryWhere)." GROUP BY (c2.vm_cores*c2.datanodes),exec_type,c2.vm_OS,c2.vm_size ) t ON t.minexe = e.exe_time
					AND t.category = category AND t.vmsize = c.vm_size
					WHERE 1 $this->whereClause $filter_execs  GROUP BY if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)),exec_type,c.vm_OS,c.vm_size
					ORDER BY if (exec_type='ADLA_manual',c.vm_cores,(c.vm_cores*c.datanodes)) ASC,c.vm_OS,c.vm_size DESC";

			$params = $this->filters->getFiltersSelectedChoices(array('upred','uobsr'));
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$execs = "($execs) UNION ($predExecs)";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$execs = $predExecs;
			}

			$execs = $dbUtils->get_rows($execs);

			$vmSizes = array();
			$dataNodes = array();
			$vmOS = array();
			$execTypes = array();
			foreach ($execs as &$exec) {
				if (!isset($dataNodes[$exec['category']])) {
					$dataNodes[$exec['category']] = 1;
					$categories[] = $exec['category'];
				}
				if(!isset($vmOS[$exec['vm_OS']]))
					$vmOS[$exec['vm_OS']] = 1;
				if(!isset($execTypes[$exec['exec_type']]))
					$execTypes[$exec['exec_type']] = 1;

				//Change VM names for SaaS tests
				if (strstr($exec['vm_size'],'DWU')) {
					$vm_name = preg_replace('/\d+DWU/', 'DWU', $exec['vm_size']); //for DW
				} else if (strstr($exec['vm_size'],'RS')){
					$vm_name = preg_replace('/RS-+\d+/', 'RS-',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'EMR')){
					$vm_name = preg_replace('/EMR-+\d+/', 'EMR-',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'CBD')){
					$vm_name = substr($exec['vm_size'],0, 14);
				} else if (strstr($exec['vm_size'],'HDI')){
					$vm_name = substr($exec['vm_size'],0, 6);
				} else if (strstr($exec['vm_size'],'AU')){
					$vm_name = preg_replace('/\d+AU/', 'AU',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'M100')){
					$vm_name = 'M100';
				} else {
					$vm_name = $exec['vm_size'];
				}

				$vmSizes[$vm_name][$exec['exec_type']][$exec['vm_OS']][$exec['category']] = array(round($exec['exe_time'],2), round($exec['cost'],2));
			}


			$i = 0;
			$seriesColors = array('#7cb5ec', '#434348', '#90ed7d', '#f7a35c', '#8085e9',
				'#f15c80', '#e4d354', '#2b908f', '#f45b5b', '#91e8e1');
			foreach($vmSizes as $vmSize => $value) {
				foreach($execTypes as $execType => $typevalue) {
					foreach ($vmOS as $OS => $osvalue) {
						if (isset($vmSizes[$vmSize][$execType][$OS])) {
							if ($i == sizeof($seriesColors)) $i = 0;
							$costSeries = array('name' => "$vmSize", 'type' => 'spline', 'dashStyle' => 'longdash', 'yAxis' => 0, 'data' => array(), 'tooltip' => array('valueSuffix' => ' US$'), 'color' => $seriesColors[$i]);
							$timeSeries = array('name' => "$vmSize", 'type' => 'spline', 'yAxis' => 1, 'data' => array(), 'tooltip' => array('valueSuffix' => ' s'), 'color' => $seriesColors[$i++]);
							foreach ($dataNodes as $datanode => $dvalue) {
								$datanodes[] = $datanode;
								if (!isset($value[$execType][$OS][$datanode])) {
									$costSeries['data'][] = "null";
									$timeSeries['data'][] = "null";
								} else {
									$costSeries['data'][] = $value[$execType][$OS][$datanode][1];
									$timeSeries['data'][] = $value[$execType][$OS][$datanode][0];
								}
							}
							$series[] = $timeSeries;
							//$series[] = $costSeries;
						}
					}
				}
			}
		} catch(\Exception $e) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		}

		return array(
			'categories' => json_encode($categories),
			'seriesData' => str_replace('"null"','null',json_encode($series)),
			'datanodess' => $datanodes,
			'scalabilityType' => 'Cores'
		);
	}

	private function RAMEval($dbUtils) {
		$categories = array();
		$series = array();
		$datanodes = array();

		try {
			$filter_execs = DBUtils::getFilterExecs();

			$innerQueryWhere = str_replace("e.","e2.",$this->whereClause);
			$innerQueryWhere = str_replace("c.","c2.",$innerQueryWhere);
			$innerQueryWhere = str_replace("p.","p2.",$innerQueryWhere);

			$execs = "SELECT if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)) as 'category',e.exec_type,c.vm_OS,c.vm_size,(avg(e.exe_time) * (c.cost_hour/3600)) as cost,avg(e.exe_time) exe_time,c.*
					FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions p USING (id_exec)

					WHERE 1 $this->whereClause $filter_execs  GROUP BY if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)),e.exec_type,c.vm_OS,c.vm_size
					ORDER BY if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)) ASC,c.vm_OS,c.vm_size DESC";


			$predExecs = "SELECT if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)) as 'category','predicted' as 'exec_type',c.vm_OS,c.vm_size,(e.exe_time * (c.cost_hour/3600)) as cost,e.exe_time,c.*
					FROM aloja_ml.predictions e JOIN aloja2.clusters c USING (id_cluster)
					INNER JOIN ( SELECT (c2.vm_RAM*c2.datanodes) as 'category','default' as 'exec_type',c2.vm_OS,c2.vm_size as vmsize,MIN(p2.exe_time) as minexe
								from aloja_ml.predictions p2 JOIN aloja2.clusters c2 USING (id_cluster)
								WHERE 1 ".str_replace("e2.","p2.",$innerQueryWhere)." GROUP BY (c2.vm_RAM*c2.datanodes),exec_type,c2.vm_OS,c2.vm_size ) t ON t.minexe = e.exe_time
					AND t.category = category AND t.vmsize = c.vm_size
					WHERE 1 $this->whereClause $filter_execs  GROUP BY if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)),exec_type,c.vm_OS,c.vm_size
					ORDER BY if (exec_type='ADLA_manual',c.vm_RAM,(c.vm_RAM*c.datanodes)) ASC,c.vm_OS,c.vm_size DESC";

			$params = $this->filters->getFiltersSelectedChoices(array('upred','uobsr'));
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$execs = "($execs) UNION ($predExecs)";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$execs = $predExecs;
			}

			$execs = $dbUtils->get_rows($execs);

			$vmSizes = array();
			$dataNodes = array();
			$vmOS = array();
			$execTypes = array();
			foreach ($execs as &$exec) {
				if (!isset($dataNodes[$exec['category']])) {
					$dataNodes[$exec['category']] = 1;
					$categories[] = $exec['category'];
				}
				if(!isset($vmOS[$exec['vm_OS']]))
					$vmOS[$exec['vm_OS']] = 1;
				if(!isset($execTypes[$exec['exec_type']]))
					$execTypes[$exec['exec_type']] = 1;

				//Change VM names for SaaS tests
				if (strstr($exec['vm_size'],'DWU')) {
					$vm_name = preg_replace('/\d+DWU/', 'DWU', $exec['vm_size']); //for DW
				} else if (strstr($exec['vm_size'],'RS')){
					$vm_name = preg_replace('/RS-+\d+/', 'RS-',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'EMR')){
					$vm_name = preg_replace('/EMR-+\d+/', 'EMR-',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'CBD')){
					$vm_name = substr($exec['vm_size'],0, 14);
				} else if (strstr($exec['vm_size'],'HDI')){
					$vm_name = substr($exec['vm_size'],0, 6);
				} else if (strstr($exec['vm_size'],'AU')){
					$vm_name = preg_replace('/\d+AU/', 'AU',  $exec['vm_size']);
				} else if (strstr($exec['vm_size'],'M100')){
					$vm_name = 'M100';
				} else {
					$vm_name = $exec['vm_size'];
				}

				$vmSizes[$vm_name][$exec['exec_type']][$exec['vm_OS']][$exec['category']] = array(round($exec['exe_time'],2), round($exec['cost'],2));
			}


			$i = 0;
			$seriesColors = array('#7cb5ec', '#434348', '#90ed7d', '#f7a35c', '#8085e9',
				'#f15c80', '#e4d354', '#2b908f', '#f45b5b', '#91e8e1');
			foreach($vmSizes as $vmSize => $value) {
				foreach($execTypes as $execType => $typevalue) {
					foreach ($vmOS as $OS => $osvalue) {
						if (isset($vmSizes[$vmSize][$execType][$OS])) {
							if ($i == sizeof($seriesColors)) $i = 0;
							$costSeries = array('name' => "$vmSize", 'type' => 'spline', 'dashStyle' => 'longdash', 'yAxis' => 0, 'data' => array(), 'tooltip' => array('valueSuffix' => ' US$'), 'color' => $seriesColors[$i]);
							$timeSeries = array('name' => "$vmSize", 'type' => 'spline', 'yAxis' => 1, 'data' => array(), 'tooltip' => array('valueSuffix' => ' s'), 'color' => $seriesColors[$i++]);
							foreach ($dataNodes as $datanode => $dvalue) {
								$datanodes[] = $datanode;
								if (!isset($value[$execType][$OS][$datanode])) {
									$costSeries['data'][] = "null";
									$timeSeries['data'][] = "null";
								} else {
									$costSeries['data'][] = $value[$execType][$OS][$datanode][1];
									$timeSeries['data'][] = $value[$execType][$OS][$datanode][0];
								}
							}
							$series[] = $timeSeries;
							//$series[] = $costSeries;
						}
					}
				}
			}
		} catch(\Exception $e) {
			$this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
		}

		return array(
			'categories' => json_encode($categories),
			'seriesData' => str_replace('"null"','null',json_encode($series)),
			'datanodess' => $datanodes,
			'scalabilityType' => 'RAM'
		);
	}

}
