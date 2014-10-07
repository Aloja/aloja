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
            new Point(13300, 13300),
            new Point(13300, 13301),
            new Point(13301, 13300),
            new Point(13301, 13301)
        );

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertEquals(1000, $dbscan->getEps());
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
            new Point(13300, 13300),
            new Point(13300, 13301),
            new Point(13301, 13300),
            new Point(13301, 13301),
        );

        $dbscan = new DBSCAN();
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertEquals(1000, $dbscan->getEps());
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
            array("job_201406271147_0002", 0, 2, 2),
            array("job_201406271147_0002", 0, 3, 4),
            array("job_201406271147_0002", 0, 4, 3),
            array("job_201406271147_0002", 0, 5, 2),
            array("job_201406271147_0002", 0, 6, 3),
            array("job_201406271147_0002", 0, 7, 4),
            array("job_201406271147_0002", 0, 8, 4),
            array("job_201406271147_0002", 0, 9, 3),
            array("job_201406271147_0002", 0, 10, 3),
            array("job_201406271147_0002", 0, 11, 3),
            array("job_201406271147_0002", 0, 12, 3),
            array("job_201406271147_0002", 0, 13, 3),
            array("job_201406271147_0002", 0, 14, 2),
            array("job_201406271147_0002", 0, 15, 2),
            array("job_201406271147_0002", 0, 16, 2),
            array("job_201406271147_0002", 0, 17, 2),
            array("job_201406271147_0002", 0, 18, 4),
            array("job_201406271147_0002", 0, 19, 4),

            array("job_201406271147_0002", 1, 2, 4),
            array("job_201406271147_0002", 1, 3, 4),
            array("job_201406271147_0002", 1, 4, 4),
            array("job_201406271147_0002", 1, 5, 4),
            array("job_201406271147_0002", 1, 6, 3),
            array("job_201406271147_0002", 1, 7, 3),
            array("job_201406271147_0002", 1, 8, 3),
            array("job_201406271147_0002", 1, 9, 3),
            array("job_201406271147_0002", 1, 10, 3),
            array("job_201406271147_0002", 1, 11, 3),
            array("job_201406271147_0002", 1, 12, 3),
            array("job_201406271147_0002", 1, 13, 3),
            array("job_201406271147_0002", 1, 14, 3),
            array("job_201406271147_0002", 1, 15, 3),
            array("job_201406271147_0002", 1, 16, 3),
            array("job_201406271147_0002", 1, 17, 4),
            array("job_201406271147_0002", 1, 18, 3),
            array("job_201406271147_0002", 1, 19, 3),

            array("job_201406271147_0002", 2, 3, 4),
            array("job_201406271147_0002", 2, 4, 4),
            array("job_201406271147_0002", 2, 5, 2),
            array("job_201406271147_0002", 2, 6, 4),
            array("job_201406271147_0002", 2, 7, 2),
            array("job_201406271147_0002", 2, 8, 2),
            array("job_201406271147_0002", 2, 9, 2),
            array("job_201406271147_0002", 2, 10, 2),
            array("job_201406271147_0002", 2, 11, 4),
            array("job_201406271147_0002", 2, 12, 4),
            array("job_201406271147_0002", 2, 13, 4),
            array("job_201406271147_0002", 2, 14, 2),
            array("job_201406271147_0002", 2, 15, 2),
            array("job_201406271147_0002", 2, 16, 2),
            array("job_201406271147_0002", 2, 17, 2),
            array("job_201406271147_0002", 2, 18, 2),
            array("job_201406271147_0002", 2, 19, 2),

            array("job_201406271147_0002", 3, 4, 4),
            array("job_201406271147_0002", 3, 5, 4),
            array("job_201406271147_0002", 3, 6, 4),
            array("job_201406271147_0002", 3, 7, 4),
            array("job_201406271147_0002", 3, 8, 4),
            array("job_201406271147_0002", 3, 9, 4),
            array("job_201406271147_0002", 3, 10, 4),
            array("job_201406271147_0002", 3, 11, 4),
            array("job_201406271147_0002", 3, 12, 4),
            array("job_201406271147_0002", 3, 13, 4),
            array("job_201406271147_0002", 3, 14, 4),
            array("job_201406271147_0002", 3, 15, 4),
            array("job_201406271147_0002", 3, 16, 4),
            array("job_201406271147_0002", 3, 17, 4),
            array("job_201406271147_0002", 3, 18, 4),
            array("job_201406271147_0002", 3, 19, 4),

            array("job_201406271147_0002", 4, 5, 4),
            array("job_201406271147_0002", 4, 6, 4),
            array("job_201406271147_0002", 4, 7, 3),
            array("job_201406271147_0002", 4, 8, 3),
            array("job_201406271147_0002", 4, 9, 3),
            array("job_201406271147_0002", 4, 10, 3),
            array("job_201406271147_0002", 4, 11, 4),
            array("job_201406271147_0002", 4, 12, 4),
            array("job_201406271147_0002", 4, 13, 4),
            array("job_201406271147_0002", 4, 14, 3),
            array("job_201406271147_0002", 4, 15, 3),
            array("job_201406271147_0002", 4, 16, 3),
            array("job_201406271147_0002", 4, 17, 4),
            array("job_201406271147_0002", 4, 18, 3),
            array("job_201406271147_0002", 4, 19, 3),

            array("job_201406271147_0002", 5, 6, 4),
            array("job_201406271147_0002", 5, 7, 2),
            array("job_201406271147_0002", 5, 8, 2),
            array("job_201406271147_0002", 5, 9, 2),
            array("job_201406271147_0002", 5, 10, 2),
            array("job_201406271147_0002", 5, 11, 4),
            array("job_201406271147_0002", 5, 12, 4),
            array("job_201406271147_0002", 5, 13, 4),
            array("job_201406271147_0002", 5, 14, 2),
            array("job_201406271147_0002", 5, 15, 2),
            array("job_201406271147_0002", 5, 16, 2),
            array("job_201406271147_0002", 5, 17, 2),
            array("job_201406271147_0002", 5, 18, 2),
            array("job_201406271147_0002", 5, 19, 2),

            array("job_201406271147_0002", 6, 7, 3),
            array("job_201406271147_0002", 6, 8, 3),
            array("job_201406271147_0002", 6, 9, 3),
            array("job_201406271147_0002", 6, 10, 3),
            array("job_201406271147_0002", 6, 11, 3),
            array("job_201406271147_0002", 6, 12, 3),
            array("job_201406271147_0002", 6, 13, 3),
            array("job_201406271147_0002", 6, 14, 3),
            array("job_201406271147_0002", 6, 15, 3),
            array("job_201406271147_0002", 6, 16, 3),
            array("job_201406271147_0002", 6, 17, 4),
            array("job_201406271147_0002", 6, 18, 3),
            array("job_201406271147_0002", 6, 19, 3),

            array("job_201406271147_0002", 7, 8, 4),
            array("job_201406271147_0002", 7, 9, 4),
            array("job_201406271147_0002", 7, 10, 4),
            array("job_201406271147_0002", 7, 11, 3),
            array("job_201406271147_0002", 7, 12, 3),
            array("job_201406271147_0002", 7, 13, 3),
            array("job_201406271147_0002", 7, 14, 4),
            array("job_201406271147_0002", 7, 15, 4),
            array("job_201406271147_0002", 7, 16, 4),
            array("job_201406271147_0002", 7, 17, 2),
            array("job_201406271147_0002", 7, 18, 4),
            array("job_201406271147_0002", 7, 19, 4),

            array("job_201406271147_0002", 8, 9, 3),
            array("job_201406271147_0002", 8, 10, 3),
            array("job_201406271147_0002", 8, 11, 3),
            array("job_201406271147_0002", 8, 12, 3),
            array("job_201406271147_0002", 8, 13, 3),
            array("job_201406271147_0002", 8, 14, 2),
            array("job_201406271147_0002", 8, 15, 2),
            array("job_201406271147_0002", 8, 16, 2),
            array("job_201406271147_0002", 8, 17, 2),
            array("job_201406271147_0002", 8, 18, 2),
            array("job_201406271147_0002", 8, 19, 2),

            array("job_201406271147_0002", 9, 10, 3),
            array("job_201406271147_0002", 9, 11, 3),
            array("job_201406271147_0002", 9, 12, 3),
            array("job_201406271147_0002", 9, 13, 3),
            array("job_201406271147_0002", 9, 14, 4),
            array("job_201406271147_0002", 9, 15, 4),
            array("job_201406271147_0002", 9, 16, 4),
            array("job_201406271147_0002", 9, 17, 2),
            array("job_201406271147_0002", 9, 18, 3),
            array("job_201406271147_0002", 9, 19, 3),

            array("job_201406271147_0002", 10, 11, 3),
            array("job_201406271147_0002", 10, 12, 3),
            array("job_201406271147_0002", 10, 13, 3),
            array("job_201406271147_0002", 10, 14, 4),
            array("job_201406271147_0002", 10, 15, 4),
            array("job_201406271147_0002", 10, 16, 4),
            array("job_201406271147_0002", 10, 17, 2),
            array("job_201406271147_0002", 10, 18, 3),
            array("job_201406271147_0002", 10, 19, 3),

            array("job_201406271147_0002", 11, 12, 3),
            array("job_201406271147_0002", 11, 13, 3),
            array("job_201406271147_0002", 11, 14, 3),
            array("job_201406271147_0002", 11, 15, 3),
            array("job_201406271147_0002", 11, 16, 3),
            array("job_201406271147_0002", 11, 17, 4),
            array("job_201406271147_0002", 11, 18, 3),
            array("job_201406271147_0002", 11, 19, 3),

            array("job_201406271147_0002", 12, 13, 3),
            array("job_201406271147_0002", 12, 14, 3),
            array("job_201406271147_0002", 12, 15, 3),
            array("job_201406271147_0002", 12, 16, 3),
            array("job_201406271147_0002", 12, 17, 4),
            array("job_201406271147_0002", 12, 18, 3),
            array("job_201406271147_0002", 12, 19, 3),

            array("job_201406271147_0002", 13, 14, 3),
            array("job_201406271147_0002", 13, 15, 3),
            array("job_201406271147_0002", 13, 16, 3),
            array("job_201406271147_0002", 13, 17, 4),
            array("job_201406271147_0002", 13, 18, 3),
            array("job_201406271147_0002", 13, 19, 3),

            array("job_201406271147_0002", 14, 15, 2),
            array("job_201406271147_0002", 14, 16, 2),
            array("job_201406271147_0002", 14, 17, 2),
            array("job_201406271147_0002", 14, 18, 2),
            array("job_201406271147_0002", 14, 19, 2),

            array("job_201406271147_0002", 15, 16, 2),
            array("job_201406271147_0002", 15, 17, 2),
            array("job_201406271147_0002", 15, 18, 2),
            array("job_201406271147_0002", 15, 19, 2),

            array("job_201406271147_0002", 16, 17, 2),
            array("job_201406271147_0002", 16, 18, 2),
            array("job_201406271147_0002", 16, 19, 2),

            array("job_201406271147_0002", 17, 18, 2),
            array("job_201406271147_0002", 17, 19, 2),

            array("job_201406271147_0002", 18, 19, 1, 0),


            array("job_201406271147_0002", 1, 2, 4),
            array("job_201402172244_0002", 0, 1, 3),
            array("job_201402172338_0001", 0, 1, 1),
            array("job_201402180048_0001", 0, 1, 3),
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
