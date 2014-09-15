<?php

namespace alojaweb\inc\dbscan;

class DBSCANTest extends \PHPUnit_Framework_TestCase
{

    public function testSimple()
    {
        $eps = 10;
        $minPoints = 4;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(100, 100),
            new Point(100, 101),
            new Point(101, 100),
            new Point(101, 101),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(0, $noise);
        $this->assertCount(2, $cluster);
        $this->assertCount(4, $cluster[0]);
        $this->assertCount(4, $cluster[1]);
        $this->assertEquals($cluster[0], array_slice($points, 0, 4));
        $this->assertEquals($cluster[1], array_slice($points, 4, 4));
    }

    public function testNotEnoughMinPoints()
    {
        $eps = 10;
        $minPoints = 5;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(100, 100),
            new Point(100, 101),
            new Point(101, 100),
            new Point(101, 101),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(8, $noise);
        $this->assertCount(0, $cluster);
        $this->assertEquals($noise, $points);
    }

    public function testNoise()
    {
        $eps = 10;
        $minPoints = 4;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(9999, 9999),
            new Point(100, 100),
            new Point(100, 101),
            new Point(101, 100),
            new Point(101, 101),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(1, $noise);
        $this->assertCount(2, $cluster);
        $this->assertEquals($noise[0], $points[4]);
        $this->assertEquals($cluster[0], array_slice($points, 0, 4));
        $this->assertEquals($cluster[1], array_slice($points, 5, 4));
    }

    public function testEpsEnough()
    {
        $eps = 1.001;
        $minPoints = 2;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(1, 3),
            new Point(1, 4),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(0, $noise);
        $this->assertCount(1, $cluster);
        $this->assertEquals($cluster[0], array_slice($points, 0, 4));
    }

    public function testEpsNotEnough()
    {
        $eps = 1;
        $minPoints = 2;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(1, 3),
            new Point(1, 4),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(4, $noise);
        $this->assertCount(0, $cluster);
        $this->assertEquals($noise, $points);
    }

    public function testSquare()
    {
        $eps = 1.001;
        $minPoints = 3;
        $points = array(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(0, $noise);
        $this->assertCount(1, $cluster);
        $this->assertEquals($cluster[0], array_slice($points, 0, 4));
    }

    public function testOverlappingPoint()
    {
        $eps = 1.5;
        $minPoints = 2;
        $points = array(
            new Point(1, 1),
            new Point(1, 1),
            new Point(1, 2),
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(0, $noise);
        $this->assertCount(1, $cluster);
        $this->assertEquals($cluster[0], $points);

    }

}
