<?php

namespace alojaweb\Controller;

use alojaweb\inc\HighCharts;
use alojaweb\inc\Utils;
use alojaweb\inc\DBUtils;
use Monolog\Handler\Curl\Util;

class ConfigEvaluationsController extends AbstractController
{
	public function configImprovementAction()
	{
		$db = $this->container->getDBUtils();
		$this->buildFilters();
		$this->buildGroupFilters();
		$whereClause = $this->filters->getWhereClause();
		$model_html = '';
		$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
		foreach ($model_info as $row)
			$model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

		$rows_config = '';

		try {
			$concat_config = Utils::getConfig($this->filters->getGroupFilters());
			$filter_execs = DBUtils::getFilterExecs();
			$order_conf = 'LENGTH(conf), conf';
			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));

			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$query = "SELECT COUNT(*) AS num, CONCAT($concat_config) conf
					FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions p USING (id_exec)
					WHERE 1 $filter_execs $whereClause
					GROUP BY conf ORDER BY $order_conf";
			$queryPredicted = "SELECT COUNT(*) AS num, CONCAT($concat_config) conf
					FROM aloja_ml.predictions AS e
					JOIN clusters c USING (id_cluster)
					WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
					GROUP BY conf ORDER BY $order_conf";

			//get configs first (categories)
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "
				SELECT SUM(u1.num) AS num, u1.conf as conf
				FROM (
					($query)
					UNION
					($queryPredicted)
				) AS u1
				GROUP BY conf ORDER BY $order_conf
			";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredicted;
			}

			$rows_config = $db->get_rows($query);
			$height = 600;
			if (count($rows_config) > 4) {
				$num_configs = count($rows_config);
				$height = round($height + (10*($num_configs-4)));
			}

			$query = "SELECT e.id_exec,
			 concat($concat_config) conf, e.bench as bench,
			 avg(e.exe_time) AVG_exe_time,
			 min(e.exe_time) MIN_exe_time,
			 max(e.exe_time) MAX_exe_time,
			 (select AVG(exe_time) FROM aloja2.execs ea JOIN aloja2.clusters ca using (id_cluster) WHERE 1 ".str_replace('c.','ca.',str_replace('e.','ea.',$whereClause)).") AVG_ALL_exe_time,
			 'none'
			 from aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
			 LEFT JOIN aloja_ml.predictions AS p USING (id_exec)
			 WHERE 1 $filter_execs $whereClause
			 GROUP BY conf, e.bench order by e.bench, $order_conf";
			$queryPredicted = "
				SELECT e.id_exec, CONCAT($concat_config) conf, CONCAT('pred_',e.bench) as bench, AVG(e.pred_time) AVG_exe_time, min(e.pred_time) MIN_exe_time,
				(
					SELECT AVG(p.pred_time)
					FROM aloja_ml.predictions p
					WHERE p.bench = e.bench ".str_replace("e.","p.",$whereClauseML)." AND p.id_learner = '".$params['prediction_model']."'
				) AVG_ALL_exe_time, 'none'
				FROM aloja_ml.predictions AS e
				JOIN clusters c USING (id_cluster)
				WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
				GROUP BY conf, e.bench ORDER BY e.bench, $order_conf
			";

			//get the result rows
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "SELECT j.id_exec, j.conf, j.bench, j.AVG_exe_time, j.MIN_exe_time, j.AVG_ALL_exe_time, 'none' FROM (
					($query) UNION ($queryPredicted)) AS j
				GROUP BY j.conf, j.bench ORDER BY j.bench, $order_conf
			";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredicted;
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

			$rows = $db->get_rows($query);

			if (!$rows)
				throw new \Exception("No results for query!");
		} catch (\Exception $e) {
			$this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
		}

		$categories = '';
		$count = 0;
		$confOrders = array();
		foreach ($rows_config as $row_config) {
			$categories .= "'{$row_config['conf']} ({$row_config['num']})',";
			$count += $row_config['num'];
			$confOrders[] = $row_config['conf'];
		}

		$series = '';
		$bench = '';
		if ($rows) {
			// Normal columns
			$seriesIndex = 0;
			foreach ($rows as $row) {
				//close previous serie if not first one
				if ($bench && $bench != strtolower($row['bench'])) {
                    $series .= "]
                        }, $error_bars ]
                        },
                        ";
				}
				//starts a new series
				if ($bench != strtolower($row['bench'])) {
					$seriesIndex = 0;
					$bench = strtolower($row['bench']);
					$series .= "
                        {
                            name: '".strtolower($row['bench'])."',
                                data: [";
                    $error_bars = "
                        {
                            name: '".strtolower($row['bench'])."',
                            type: 'errorbar',
                            stemColor: '#808080',
                            stemDashStyle: 'dot',
                            whiskerColor: '#808080',
                                data: [";
				}
				while($row['conf'] != $confOrders[$seriesIndex]) {
					$series .= "[null],";
					$seriesIndex++;
				}
				$series .= "['{$row['conf']}',".
					round(($row['AVG_ALL_exe_time']/$row['AVG_exe_time']), 2). //For average
					//round(($row['AVG_ALL_exe_time']/$row['MIN_exe_time']), 3). //For min
					"],";

                $error_bars .= "['{$row['conf']}',".
                    round($row['AVG_ALL_exe_time']/$row['MAX_exe_time'], 2).
                    ",".
                    round($row['AVG_ALL_exe_time']/$row['MIN_exe_time'], 2).
                    "],";

				$seriesIndex++;
			}
            //close the last series
            $series .= "]
                    },  $error_bars ]
                        },
                    ";
		}
		return $this->render ( 'configEvaluationViews/config_improvement.html.twig', array (
				'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
				'highcharts_js' => HighCharts::getHeader(),
				'categories' => $categories,
				'series' => $series,
				'models' => $model_html,
				'count' => $count,
			)
		);
	}
	public function execTimesAction()
	{
		$db = $this->container->getDBUtils();
		$this->buildFilters();
		$this->buildGroupFilters();
		$whereClause = $this->filters->getWhereClause();
		$model_html = '';
		$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
		foreach ($model_info as $row)
			$model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

		$rows_config = '';

		try {
			$concat_config = Utils::getConfig($this->filters->getGroupFilters());

			$filter_execs = DBUtils::getFilterExecs();
			$order_conf = 'LENGTH(conf), conf';
			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));

			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$query = "SELECT COUNT(*) AS num, CONCAT($concat_config) conf
					FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions p USING (id_exec)
					WHERE 1 $filter_execs $whereClause
					GROUP BY conf ORDER BY $order_conf";
			$queryPredicted = "SELECT COUNT(*) AS num, CONCAT($concat_config) conf
					FROM aloja_ml.predictions AS e
					JOIN clusters c USING (id_cluster)
					WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
					GROUP BY conf ORDER BY $order_conf";

			//get configs first (categories)
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "
				SELECT SUM(u1.num) AS num, u1.conf as conf
				FROM (
					($query)
					UNION
					($queryPredicted)
				) AS u1
				GROUP BY conf ORDER BY $order_conf
			";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredicted;
			}

			$rows_config = $db->get_rows($query);

			usort($rows_config, array('alojaweb\inc\Utils', 'cmp_conf'));

			$height = 600;
			if (count($rows_config) > 4) {
				$num_configs = count($rows_config);
				$height = round($height + (10*($num_configs-4)));
			}

			$query = "SELECT e.id_exec,
			 concat($concat_config) conf, e.bench as bench,
			 avg(e.exe_time) AVG_exe_time,
			 min(e.exe_time) MIN_exe_time,
			 max(e.exe_time) MAX_exe_time,
			 'none'
			 from aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
			 LEFT JOIN aloja_ml.predictions AS p USING (id_exec)
			 WHERE 1 $filter_execs $whereClause
			 GROUP BY conf, e.bench order by e.bench, $order_conf";
			$queryPredicted = "
				SELECT e.id_exec, CONCAT($concat_config) conf, CONCAT('pred_',e.bench) as bench, AVG(e.pred_time) AVG_exe_time, min(e.pred_time) MIN_exe_time,
				(
					SELECT AVG(p.pred_time)
					FROM aloja_ml.predictions p
					WHERE p.bench = e.bench ".str_replace("e.","p.",$whereClauseML)." AND p.id_learner = '".$params['prediction_model']."'
				) AVG_ALL_exe_time, 'none'
				FROM aloja_ml.predictions AS e
				JOIN clusters c USING (id_cluster)
				WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
				GROUP BY conf, e.bench ORDER BY e.bench, $order_conf
			";

			//get the result rows
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "SELECT j.id_exec, j.conf, j.bench, j.AVG_exe_time, j.MIN_exe_time, 'none' FROM (
					($query) UNION ($queryPredicted)) AS j
				GROUP BY j.conf, j.bench ORDER BY j.bench, $order_conf
			";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredicted;
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

			$rows = $db->get_rows($query);

			usort($rows, array('alojaweb\inc\Utils', 'cmp_conf'));

			if (!$rows)
				throw new \Exception("No results for query!");
		} catch (\Exception $e) {
			$this->container->getTwig()->addGlobal('message',$e->getMessage()."\n");
		}

		$categories = '';
		$count = 0;
		$confOrders = array();
		foreach ($rows_config as $row_config) {
			$categories .= "'{$row_config['conf']} ({$row_config['num']})',";
			$count += $row_config['num'];
			$confOrders[] = $row_config['conf'];
		}

		$series = '';
		$bench = '';
        $error_bars='';
		if ($rows) {
			// Normal columns
			$seriesIndex = 0;
			foreach ($rows as $row) {
				//close previous series if not first one
				if ($bench && $bench != strtolower($row['bench'])) {
					$series .= "]
                        }, $error_bars ]
                        },
                        ";
				}
				//starts a new series
				if ($bench != strtolower($row['bench'])) {
					$seriesIndex = 0;
					$bench = strtolower($row['bench']);
					$series .= "
                        {
                            name: '".strtolower($row['bench'])."',
                                data: [";
                    $error_bars = "
                        {
                            name: '".strtolower($row['bench'])."',
                            type: 'errorbar',
                            stemColor: '#808080',
                            stemDashStyle: 'dot',
                            whiskerColor: '#808080',
                                data: [";
				}
				while($row['conf'] != $confOrders[$seriesIndex]) {
					$series .= "[null],";
					$seriesIndex++;
				}
				$series .= "['{$row['conf']}',".
					round($row['AVG_exe_time'], 1). //For average
					"],";

                $error_bars .= "['{$row['conf']}',".
					round($row['MIN_exe_time'], 1).
					",".
					round($row['MAX_exe_time'], 1).
					"],";

				$seriesIndex++;
			}
			//close the last series
			$series .= "]
                    },  $error_bars ]
                        },
                    ";

		}
		return $this->render ( 'configEvaluationViews/exec_times.html.twig', array (
				'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
				'highcharts_js' => HighCharts::getHeader(),
				'categories' => $categories,
				'series' => $series,
				'models' => $model_html,
				'count' => $count,
			)
		);
	}

    public function bestConfigAction()
    {
        $db = $this->container->getDBUtils ();
        $this->buildFilters(array(
		'bench' => array(
			'default' => array('terasort'),
			'type' => 'selectOne', 'label' => 'Benchmark:'
		),
		'ordertype' => array(
			'default' => array('cost'),
			'type' => 'selectOne',
			'label' => 'Best config by:',
			'generateChoices' => function() {
			    return array('exe_time','cost');
			},
			'parseFunction' => function() {
			    $ordertype = isset($_GET['ordertype']) ? $_GET['ordertype'] : 'cost';
			    return array('currentChoice' => $ordertype, 'whereClause' => "");
			},
			'beautifier' => function($value) {
			   if($value == 'exe_time')
			       return 'Execution time';
			    else
			       return 'Cost-effectiveness';
			},
			'filterGroup' => 'basic'
		)
		));
		$whereClause = $this->filters->getWhereClause();

		$model_html = '';
		$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
		foreach ($model_info as $row)
			$model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

        $clusterCosts = Utils::generateCostsFilters($db);

        $bestexec = '';
        $cluster = '';
        try {
			$order_type = Utils::get_GET_string ( 'ordertype' );
			if (! $order_type)
			$order_type = 'exe_time';

			$filterExecs = DBUtils::getFilterExecs();

			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$queryObserved = "
					SELECT (e.exe_time/3600)*c.cost_hour as cost, e.id_exec,e.exec,e.bench,e.exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version, c.*
					FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
					LEFT JOIN aloja_ml.predictions AS p USING (id_exec)
					WHERE 1 $filterExecs $whereClause
					GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
					ORDER BY $order_type ASC
				";

			$queryPredictions = "SELECT (e.exe_time/3600)*c.cost_hour AS cost,e.id_exec,e.exec,CONCAT('Predicted ',e.bench) as bench,e.pred_time AS exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,c.*
					FROM aloja_ml.predictions AS e JOIN aloja2.clusters AS c USING (id_cluster)
					WHERE 1 $filterExecs ".str_replace("p.","e.",$whereClauseML)."
					GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
					ORDER BY $order_type ASC";

			$query = $queryObserved;

			// get the result rows
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{

				$query = "
					($queryObserved)
					UNION
					($queryPredictions)
					ORDER BY $order_type ASC
				";
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
				$query = $queryPredictions;
			else if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

	//		$this->getContainer ()->getLog ()->addInfo ( 'BestConfig query: ' . $query );
			$rows = $db->get_rows ( $query );

			if (!$rows) throw new \Exception ( "No results for query!" );

			$minCost = -1;
			$minCostIdx = 0;

			if ($rows) {
				$bestexec = $rows[0];
				if($order_type == 'cost') {
						foreach($rows as $key => &$exec) {
							$cost = Utils::getExecutionCost($exec,$clusterCosts);
						if(($cost < $minCost) || $minCost == -1) {
								$minCost = $cost;
								$minCostIdx = $key;
							}
						$exec['cost'] = $cost;
						}
						$bestexec = $rows[$minCostIdx];
				} else
					$bestexec['cost'] = Utils::getExecutionCost($bestexec,$clusterCosts);

				$cluster=$bestexec['name'];
				Utils::makeExecInfoBeauty($bestexec);
			}
        } catch ( \Exception $e ) {
            $this->container->getTwig ()->addGlobal ( 'message', $e->getMessage () . "\n" );
        }

        $clusters = $db->get_rows("SELECT * FROM aloja2.clusters WHERE id_cluster IN (SELECT DISTINCT id_cluster FROM aloja2.execs e WHERE 1 $filterExecs);");

        return $this->render ( 'configEvaluationViews/bestconfig.html.twig', array (
            'title' => 'Best Run Configuration',
            'bestexec' => $bestexec,
            'cluster' => $cluster,
            'order_type' => $order_type,
            'clusters' => $clusters,
            'clusterCosts' => $clusterCosts,
	    	'models' => $model_html
        ));
    }

    public function paramEvaluationAction() {
        $db = $this->container->getDBUtils ();
        $this->buildFilters(array(
			'minexecs' => array('default' => null, 'type' => 'inputNumber', 'label' => 'Minimum executions:',
				'parseFunction' => function() { return 0; },
				'filterGroup' => 'basic'
			),
		));
		$whereClause = $this->filters->getWhereClause();

		$model_html = '';
		$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
		foreach ($model_info as $row)
			$model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

        $categories = '';
        $series = '';
        try {

			$paramEval = (isset($_GET['parameval']) && Utils::get_GET_string('parameval') != '') ? Utils::get_GET_string('parameval') : 'maps';
			$minExecs = (isset($_GET['minexecs'])) ? Utils::get_GET_int('minexecs') : -1;
			$this->filters->changeCurrentChoice('minexecs',($minExecs == -1) ? null : $minExecs);

			$shortAliasParamEval = array('maps' => 'e', 'comp' => 'e', 'id_cluster' => 'c',
				'net' => 'e', 'disk' => 'e','replication' => 'e',
				'iofilebuf' => 'e', 'blk_size' => 'e', 'iosf' => 'e', 'vm_size' => 'c',
				'vm_cores' => 'c', 'vm_ram' => 'c', 'datanodes' => 'c', 'hadoop_version' => 'e',
				'type' => 'c', 'scale_factor' => 'e', 'run_num' => 'e');

			$minExecsFilter = "";
			if($minExecs > 0)
			$minExecsFilter = "HAVING COUNT(*) > $minExecs";

			$filter_execs = DBUtils::getFilterExecs();

			$options = $this->filters->getFiltersArray()[$paramEval]['choices'];

			$benchOptions = "SELECT DISTINCT e.bench FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench order by ${shortAliasParamEval[$paramEval]}.$paramEval";

			$params = $this->filters->getFiltersSelectedChoices(array('prediction_model','upred','uobsr'));

			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$query = "SELECT COUNT(*) AS count, ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench, avg(e.exe_time) avg_exe_time, min(e.exe_time) min_exe_time
					  FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
					  LEFT JOIN aloja_ml.predictions AS p USING (id_exec)
					  WHERE 1 $filter_execs $whereClause
					  GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench $minExecsFilter ORDER BY e.bench, ${shortAliasParamEval[$paramEval]}.$paramEval";

			$queryPredictions = "
					SELECT COUNT(*) AS count, ${shortAliasParamEval[$paramEval]}.$paramEval, CONCAT('pred_',e.bench) as bench,
						avg(e.pred_time) as avg_exe_time, min(e.pred_time) as min_exe_time
						FROM aloja_ml.predictions AS e
						JOIN clusters c USING (id_cluster)
						WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
						GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench $minExecsFilter ORDER BY e.bench, ${shortAliasParamEval[$paramEval]}.$paramEval";


			// get the result rows
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "($query) UNION ($queryPredictions)";
				$benchOptions = "SELECT DISTINCT e.bench FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 $filter_execs $whereClause GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench
								 UNION
								 (SELECT DISTINCT CONCAT('pred_', e.bench) as bench FROM aloja_ml.predictions AS e
								  JOIN clusters c USING (id_cluster)
								 WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
								 GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench $minExecsFilter)
								 ORDER BY bench";
				$optionsPredictions = "SELECT DISTINCT ${shortAliasParamEval[$paramEval]}.$paramEval FROM aloja_ml.predictions AS e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."' ORDER BY ${shortAliasParamEval[$paramEval]}.$paramEval";
				$optionsPredictions = $db->get_rows($optionsPredictions);
				foreach($optionsPredictions as $predOption)
					$options[] = $predOption[$paramEval];
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredictions;
				$benchOptions = "SELECT DISTINCT CONCAT('pred_', e.bench) as bench FROM aloja_ml.predictions AS e
 								 JOIN clusters c USING (id_cluster)
								 WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."'
								 GROUP BY ${shortAliasParamEval[$paramEval]}.$paramEval, e.bench $minExecsFilter ORDER BY e.bench, ${shortAliasParamEval[$paramEval]}.$paramEval";

				$options = array();
				$optionsPredictions = "SELECT DISTINCT ${shortAliasParamEval[$paramEval]}.$paramEval FROM aloja_ml.predictions AS e JOIN clusters c USING (id_cluster) WHERE 1 $filter_execs ".str_replace("p.","e.",$whereClauseML)." AND e.id_learner = '".$params['prediction_model']."' ORDER BY ${shortAliasParamEval[$paramEval]}.$paramEval";
				$optionsPredictions = $db->get_rows($optionsPredictions);
				foreach($optionsPredictions as $predOption)
					$options[] = $predOption[$paramEval];
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

			$rows = $db->get_rows($query);
			$benchOptions = $db->get_rows($benchOptions);

			if (!$rows) {
				throw new \Exception ( "No results for query!" );
			}

			$paramOptions = array();
			foreach($options as $option) {
				if($paramEval == 'id_cluster')
					$paramOptions[] = Utils::getClusterName($option,$db);
				else if($paramEval == 'comp')
					$paramOptions[] = Utils::getCompressionName($option);
				else if($paramEval == 'net')
					$paramOptions[] = Utils::getNetworkName($option);
				else if($paramEval == 'disk')
					$paramOptions[] = Utils::getDisksName($option);
				else if($paramEval == 'vm_ram')
					$paramOptions[] = Utils::getBeautyRam($option);
				else
					$paramOptions[] = $option;
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

        return $this->render ('configEvaluationViews/parameval.html.twig', array (
            'title' => 'Improvement of Hadoop Execution by SW and HW Configurations',
            'minexecs' => $minExecs,
            'categories' => $categories,
            'series' => $series,
            'paramEval' => $paramEval,
	    	'models' => $model_html
        ) );
    }
}
