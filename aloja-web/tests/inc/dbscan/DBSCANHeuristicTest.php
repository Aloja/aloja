<?php

namespace alojaweb\inc\dbscan;

use alojaweb\Container\Container;
use alojaweb\inc\DBUtils;

class DBSCANHeuristicTest extends \PHPUnit_Framework_TestCase
{

    protected static $db;

    public static function setUpBeforeClass()
    {
        $_SERVER['REMOTE_ADDR'] = '127.0.0.1';
        $container = new Container();
        self::$db = $container->getDBUtils();
    }

    public function testHeuristicWithCluster()
    {
        $points = new Cluster(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(10000, 10000),
            new Point(10000, 10001),
            new Point(10001, 10000),
            new Point(10001, 10001)
        );

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertEquals(10, $dbscan->getEps());
        $this->assertEquals(1, $dbscan->getMinPoints());
        $this->assertCount(2, $cluster);
        $this->assertCount(0, $noise);
    }

    public function testHeuristicWithArray()
    {
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(10000, 10000),
            new Point(10000, 10001),
            new Point(10001, 10000),
            new Point(10001, 10001),
        );

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertEquals(10, $dbscan->getEps());
        $this->assertEquals(1, $dbscan->getMinPoints());
        $this->assertCount(2, $cluster);
        $this->assertCount(0, $noise);
    }

    public function testHeuristicOverlappingPoints()
    {
        $points = new Cluster(
            new Point(10, 10),
            new Point(10, 10),
            new Point(10, 10),
            new Point(10, 10)
        );

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertEquals(1, $dbscan->getEps());
        $this->assertEquals(1, $dbscan->getMinPoints());
        $this->assertCount(1, $cluster);
        $this->assertCount(0, $noise);
    }

    /**
     * @dataProvider realPointsProvider
     */
    public function testHeuristicWithRealPoints($jobid, $metric_x, $metric_y, $num_clusters, $num_noise = 0)
    {
        $points = $this->getRealPoints($jobid, $metric_x, $metric_y);

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $assert_error = "";
        $assert_error .= "Check the chart here:\n";
        $assert_error .= "    http://127.0.0.1:8080/dbscan?jobid=$jobid\n";
        $assert_error .= "    Metric X: \"".DBUtils::$TASK_METRICS[$metric_x]."\"\n";
        $assert_error .= "    Metric Y: \"".DBUtils::$TASK_METRICS[$metric_y]."\"";
        $this->assertCount($num_clusters, $cluster, $assert_error);
        $this->assertCount($num_noise, $noise, $assert_error);
    }

    public function realPointsProvider()
    {
        // Array content:
        // jobid, metric_x, metric_y, num_clusters [, num_noise ]
        return array(
            array("job_201406271147_0002", 0, 1, 3),
        );
    }

    public function getRealPoints($jobid, $metric_x, $metric_y)
    {
        $query_select1 = self::$db->get_task_metric_query(DBUtils::$TASK_METRICS[$metric_x]);
        $query_select2 = self::$db->get_task_metric_query(DBUtils::$TASK_METRICS[$metric_y]);
        $query = "
            SELECT
                t.`TASKID` as TASK_ID,
                ".$query_select1('t')." as TASK_VALUE_X,
                ".$query_select2('t')." as TASK_VALUE_Y
            FROM `JOB_tasks` t
            WHERE t.`JOBID` = :jobid
            ORDER BY t.`TASKID`
        ;";
        $query_params = array(":jobid" => $jobid);

        $rows = self::$db->get_rows($query, $query_params);

        $points = new Cluster();
        foreach ($rows as $row) {
            $points[] = new Point(
                $row['TASK_VALUE_X'] ?: 0,
                $row['TASK_VALUE_Y'] ?: 0
            );
        }

        return $points;
    }

}
