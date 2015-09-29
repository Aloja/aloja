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

	$this->buildFilters(array(
		'current_model' => array(
			'type' => 'selectOne',
			'default' => null,
			'label' => 'Reference Model: ',
			'generateChoices' => function() {
				$query = "SELECT DISTINCT id_learner FROM aloja_ml.predictions";
			        $db = $this->container->getDBUtils();
				$retval = $db->get_rows ($query);
				return array_column($retval,"id_learner");
			},
			'parseFunction' => function() {
				$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'upred' => array(
			'type' => 'checkbox',
			'default' => 0,
			'label' => 'Use predictions',
			'parseFunction' => function() {
				$choice = (!isset($_GET['upred'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'uobsr' => array(
			'type' => 'checkbox',
			'default' => 1,
			'label' => 'Use observations',
			'parseFunction' => function() {
				$choice = (!isset($_GET['uobsr'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		)
	));
	$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','upred','uobsr'))));
	$this->buildGroupFilters(); // FIXME - WHY?! ALSO NO DEFAULTS ON CHECKBOX?!
        $whereClause = $this->filters->getWhereClause();

	$model_html = '';
	$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
	foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

        $rows_config = '';
        try {
           	$concat_config = Utils::getConfig($this->filters->getGroupFilters());

		$filter_execs = DBUtils::getFilterExecs();
		$order_conf = 'LENGTH(conf), conf';

		$params = $this->filters->getFiltersSelectedChoices(array('current_model','upred','uobsr'));

		//get configs first (categories)
		if ($params['uobsr'] == 1 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
			$query = "
				SELECT SUM(u1.num) AS num, u1.conf as conf
				FROM (				
					(SELECT COUNT(*) AS num, CONCAT($concat_config) conf
					FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
					WHERE 1 $filter_execs $whereClause
					GROUP BY conf ORDER BY $order_conf)
					UNION
					(SELECT COUNT(*) AS num, CONCAT($concat_config) conf 
					FROM aloja_ml.predictions AS p
					WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
					GROUP BY conf ORDER BY $order_conf)
				) AS u1
				GROUP BY conf ORDER BY $order_conf
			";
		}
		else if ($params['uobsr'] == 0 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
			$query = "SELECT COUNT(*) num, CONCAT($concat_config) conf 
				FROM aloja_ml.predictions AS e
				WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
				GROUP BY conf ORDER BY $order_conf";
		}
		else
		{
			$query = "SELECT COUNT(*) num, CONCAT($concat_config) conf
				FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
				WHERE 1 $filter_execs $whereClause
				GROUP BY conf ORDER BY $order_conf #AVG(exe_time)";
		}
		$rows_config = $db->get_rows($query);

		$height = 600;

		if (count($rows_config) > 4) {
			$num_configs = count($rows_config);
			$height = round($height + (10*($num_configs-4)));
		}

		//get the result rows
		if ($params['uobsr'] == 1 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$query = "
				SELECT u1.id_exec AS id_exec, u1.conf AS conf, u1.bench AS bench, AVG(u1.exe_time) AVG_exe_time, MAX(u1.exe_time) MAX_exe_time, MIN(u1.exe_time) MIN_exe_time,
				(
					SELECT AVG(u2.exe_time)
					FROM (
						(SELECT exe_time, bench as b1
						FROM aloja2.execs
						WHERE 1 $whereClause)
						UNION
						(SELECT pred_time AS exe_time, bench as b1
						FROM aloja_ml.predictions
						WHERE 1 $whereClauseML AND id_learner = '".$params['current_model']."')
					) as u2
					WHERE bench = b1
				) AVG_ALL_exe_time,'none'
				FROM (
					(SELECT id_exec, concat($concat_config) conf, bench, exe_time
					FROM aloja2.execs e JOIN aloja2.clusters USING (id_cluster)
					WHERE 1 $whereClause)
					UNION
					(SELECT id_exec, CONCAT($concat_config) conf, bench, pred_time AS exe_time
					FROM aloja_ml.predictions AS p
					WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."')
				) AS u1
				GROUP BY conf, bench ORDER BY bench, $order_conf
			";
		}
		else if ($params['uobsr'] == 0 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
			$query = "
				SELECT id_exec, CONCAT($concat_config) conf, bench, AVG(pred_time) AVG_exe_time, max(pred_time) MAX_exe_time, min(pred_time) MIN_exe_time,
				(
					SELECT AVG(pred_time)
					FROM aloja_ml.predictions
					WHERE bench = p.bench $whereClauseML AND id_learner = '".$params['current_model']."'
				) AVG_ALL_exe_time, 'none'
				FROM aloja_ml.predictions AS p
				WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
				GROUP BY conf, bench ORDER BY bench, $order_conf
			";
		}
		else
		{
			if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

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
			      (select AVG(exe_time) FROM aloja2.execs WHERE bench = e.bench $whereClause) AVG_ALL_exe_time,
			      #(select MAX(exe_time) FROM aloja2.execs WHERE bench = e.bench $whereClause) MAX_ALL_exe_time,
			      #(select MIN(exe_time) FROM aloja2.execs WHERE bench = e.bench $whereClause) MIN_ALL_exe_time,
			      'none'
			      from aloja2.execs e JOIN aloja2.clusters USING (id_cluster)
			      WHERE 1 $filter_execs $whereClause
			      GROUP BY conf, bench order by bench, $order_conf";
		}
		$rows = $db->get_rows($query);

		if (!$rows) throw new \Exception("No results for query!");

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

        return $this->render ( 'configEvaluationViews/config_improvement.html.twig', array (
                'title'     => 'Improvement of Hadoop Execution by SW and HW Configurations',
                'highcharts_js' => HighCharts::getHeader(),
                'categories' => $categories,
                'series' => $series,
		'models' => $model_html
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
		),
		'current_model' => array(
			'type' => 'selectOne',
			'default' => null,
			'label' => 'Reference Model: ',
			'generateChoices' => function() {
				$query = "SELECT DISTINCT id_learner FROM aloja_ml.predictions";
			        $db = $this->container->getDBUtils();
				$retval = $db->get_rows ($query);
				return array_column($retval,"id_learner");
			},
			'parseFunction' => function() {
				$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'upred' => array(
			'type' => 'checkbox',
			'default' => 0,
			'label' => 'Use predictions',
			'parseFunction' => function() {
				$choice = (!isset($_GET['upred'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'uobsr' => array(
			'type' => 'checkbox',
			'default' => 1,
			'label' => 'Use observations',
			'parseFunction' => function() {
				$choice = (!isset($_GET['uobsr'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		)
	));
	$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','upred','uobsr'))));
        $whereClause = $this->filters->getWhereClause();

	$model_html = '';
	$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
	foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

        $clusterCosts = Utils::generateCostsFilters($db);

        $bestexec = '';
        $cluster = '';
        try {
		$order_type = Utils::get_GET_string ( 'ordertype' );
		if (! $order_type)
		$order_type = 'exe_time';

		$filterExecs = DBUtils::getFilterExecs();

		$params = $this->filters->getFiltersSelectedChoices(array('current_model','upred','uobsr'));

		// get the result rows
		if ($params['uobsr'] == 1 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
			$query = "
				(SELECT (e.exe_time/3600)*c.cost_hour as cost, e.id_exec,e.exec,e.bench,e.exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version, c.*
				FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
				WHERE 1 $filterExecs $whereClause
				GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version)
				UNION
				(SELECT (e.exe_time/3600)*c.cost_hour AS cost,e.id_exec,e.exec,e.bench,e.pred_time AS exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,c.*
				FROM aloja_ml.predictions AS e JOIN aloja2.clusters AS c USING (id_cluster)
				WHERE 1 $filterExecs $whereClauseML AND id_learner = '".$params['current_model']."'
				GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version)
				ORDER BY $order_type ASC
			";
		}
		else if ($params['uobsr'] == 0 && $params['upred'] == 1)
		{
			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);
			$query = "
				SELECT (e.exe_time/3600)*c.cost_hour AS cost,e.id_exec,e.exec,e.bench,e.pred_time AS exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version,c.*
				FROM aloja_ml.predictions AS e JOIN aloja2.clusters AS c USING (id_cluster)
				WHERE 1 $filterExecs $whereClauseML AND id_learner = '".$params['current_model']."'
				GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
				ORDER BY $order_type ASC
			";
		}
		else
		{
			if ($params['uobsr'] == 0 && $params['upred'] == 0)
				$this->container->getTwig ()->addGlobal ( 'message', "Warning: No data selected (Predictions|Observations) from the ML Filters. Adding the Observed executions to the figure by default.\n" );

			$query = "
				SELECT (e.exe_time/3600)*c.cost_hour as cost, e.id_exec,e.exec,e.bench,e.exe_time,e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version, c.*
				FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster)
				WHERE 1 $filterExecs $whereClause
				GROUP BY e.net,e.disk,e.bench_type,e.maps,e.iosf,e.replication,e.iofilebuf,e.comp,e.blk_size,e.hadoop_version
				ORDER BY $order_type ASC
			";
		}

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
		'current_model' => array(
			'type' => 'selectOne',
			'default' => null,
			'label' => 'Reference Model: ',
			'generateChoices' => function() {
				$query = "SELECT DISTINCT id_learner FROM aloja_ml.predictions";
			        $db = $this->container->getDBUtils();
				$retval = $db->get_rows ($query);
				return array_column($retval,"id_learner");
			},
			'parseFunction' => function() {
				$choice = isset($_GET['current_model']) ? $_GET['current_model'] : array("");
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'upred' => array(
			'type' => 'checkbox',
			'default' => 0,
			'label' => 'Use predictions',
			'parseFunction' => function() {
				$choice = (!isset($_GET['upred'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		),
		'uobsr' => array(
			'type' => 'checkbox',
			'default' => 1,
			'label' => 'Use observations',
			'parseFunction' => function() {
				$choice = (!isset($_GET['uobsr'])) ? 0 : 1;
				return array('whereClause' => '', 'currentChoice' => $choice);
			},
			'filterGroup' => 'MLearning'
		)
	));
	$this->buildFilterGroups(array('MLearning' => array('label' => 'Machine Learning', 'tabOpenDefault' => true, 'filters' => array('current_model','upred','uobsr'))));
        $whereClause = $this->filters->getWhereClause();

	$model_html = '';
	$model_info = $db->get_rows("SELECT id_learner, model, algorithm, dataslice FROM aloja_ml.learners");
	foreach ($model_info as $row) $model_html = $model_html."<li><b>".$row['id_learner']."</b> => ".$row['algorithm']." : ".$row['model']." : ".$row['dataslice']."</li>";

        $categories = '';
        $series = '';
        try {

			$paramEval = (isset($_GET['parameval']) && Utils::get_GET_string('parameval') != '') ? Utils::get_GET_string('parameval') : 'maps';
			$minExecs = (isset($_GET['minexecs'])) ? Utils::get_GET_int('minexecs') : -1;
			$this->filters->changeCurrentChoice('minexecs',($minExecs == -1) ? null : $minExecs);

			$minExecsFilter = "";
			if($minExecs > 0)
			$minExecsFilter = "HAVING COUNT(*) > $minExecs";

			$filter_execs = DBUtils::getFilterExecs();

			$options = $this->filters->getFiltersArray()[$paramEval]['choices'];

			$benchOptions = "SELECT DISTINCT bench FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause GROUP BY $paramEval, bench order by $paramEval";

			$params = $this->filters->getFiltersSelectedChoices(array('current_model','upred','uobsr'));

			$whereClauseML = str_replace("exe_time","pred_time",$whereClause);
			$whereClauseML = str_replace("start_time","creation_time",$whereClauseML);

			$query = "SELECT COUNT(*) AS count, $paramEval, bench, avg(exe_time) avg_exe_time, min(exe_time) min_exe_time
					  FROM aloja2.execs AS e JOIN aloja2.clusters AS c USING (id_cluster)
					  WHERE 1 $filter_execs $whereClause
					  GROUP BY $paramEval, bench $minExecsFilter ORDER BY bench, $paramEval";

			$queryPredictions = "
					SELECT COUNT(*) AS count, $paramEval, CONCAT('pred_',bench) as bench, avg(pred_time) as avg_exe_time, min(pred_time) as min_exe_time
						FROM aloja_ml.predictions AS e
						WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
						GROUP BY $paramEval, bench $minExecsFilter ORDER BY bench, $paramEval";


			// get the result rows
			if ($params['uobsr'] == 1 && $params['upred'] == 1)
			{
				$query = "($query) UNION ($queryPredictions)";
				$benchOptions = "SELECT DISTINCT bench FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 $filter_execs $whereClause GROUP BY $paramEval, bench
								 UNION
								 (SELECT DISTINCT CONCAT('pred_', bench) as bench FROM aloja_ml.predictions AS e
								 WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
								 GROUP BY $paramEval, bench $minExecsFilter)
								 ORDER BY bench";
				$optionsPredictions = "SELECT DISTINCT $paramEval FROM aloja_ml.predictions AS e WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."' ORDER BY $paramEval";
				$optionsPredictions = $db->get_rows($optionsPredictions);
				foreach($optionsPredictions as $predOption)
					$options[] = $predOption[$paramEval];
			}
			else if ($params['uobsr'] == 0 && $params['upred'] == 1)
			{
				$query = $queryPredictions;
				$benchOptions = "SELECT DISTINCT CONCAT('pred_', bench) as bench FROM aloja_ml.predictions AS e
								 WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."'
								 GROUP BY $paramEval, bench $minExecsFilter ORDER BY bench, $paramEval";

				$options = array();
				$optionsPredictions = "SELECT DISTINCT $paramEval FROM aloja_ml.predictions AS e WHERE 1 $filter_execs $whereClauseML AND id_learner = '".$params['current_model']."' ORDER BY $paramEval";
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
