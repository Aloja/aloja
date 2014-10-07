<?php

namespace alojaweb\inc\dbscan;

class DBSCANHeuristicTest extends \PHPUnit_Framework_TestCase
{

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

}
