<?php

namespace alojaweb\inc\dbscan;

class DBSCANTest extends \PHPUnit_Framework_TestCase
{

    public function testSimpleWithArray()
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
        $this->assertEquals(10, $dbscan->getEps());
        $this->assertEquals(4, $dbscan->getMinPoints());
        $this->assertEquals((array)$cluster[0], array_slice($points, 0, 4));
        $this->assertEquals((array)$cluster[1], array_slice($points, 4, 4));
        $this->assertEquals($cluster[0]->getXMin(), 1);
        $this->assertEquals($cluster[0]->getXMax(), 2);
        $this->assertEquals($cluster[0]->getYMin(), 1);
        $this->assertEquals($cluster[0]->getYMax(), 2);
        $this->assertEquals($cluster[1]->getXMin(), 100);
        $this->assertEquals($cluster[1]->getXMax(), 101);
        $this->assertEquals($cluster[1]->getYMin(), 100);
        $this->assertEquals($cluster[1]->getYMax(), 101);
    }

    public function testSimpleWithCluster()
    {
        $eps = 10;
        $minPoints = 4;
        $points = new Cluster(
            new Point(1, 1),
            new Point(1, 2),
            new Point(2, 1),
            new Point(2, 2),
            new Point(100, 100),
            new Point(100, 101),
            new Point(101, 100),
            new Point(101, 101)
        );

        $dbscan = new DBSCAN($eps, $minPoints);
        list($cluster, $noise) = $dbscan->execute($points);

        $this->assertCount(0, $noise);
        $this->assertCount(2, $cluster);
        $this->assertCount(4, $cluster[0]);
        $this->assertCount(4, $cluster[1]);
        $this->assertEquals(10, $dbscan->getEps());
        $this->assertEquals(4, $dbscan->getMinPoints());
        $this->assertEquals((array)$cluster[0], array_slice((array)$points, 0, 4));
        $this->assertEquals((array)$cluster[1], array_slice((array)$points, 4, 4));
        $this->assertEquals($cluster[0]->getXMin(), 1);
        $this->assertEquals($cluster[0]->getXMax(), 2);
        $this->assertEquals($cluster[0]->getYMin(), 1);
        $this->assertEquals($cluster[0]->getYMax(), 2);
        $this->assertEquals($cluster[1]->getXMin(), 100);
        $this->assertEquals($cluster[1]->getXMax(), 101);
        $this->assertEquals($cluster[1]->getYMin(), 100);
        $this->assertEquals($cluster[1]->getYMax(), 101);
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
        $this->assertEquals((array)$cluster[0], array_slice($points, 0, 4));
        $this->assertEquals((array)$cluster[1], array_slice($points, 5, 4));
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
        $this->assertEquals((array)$cluster[0], array_slice($points, 0, 4));
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
        $this->assertEquals((array)$cluster[0], array_slice($points, 0, 4));
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
        $this->assertEquals((array)$cluster[0], $points);

    }

    /**
     * @dataProvider iterationsProvider
     * @group optimization
     */
    public function testComplexity($size, $repeat)
    {
        $eps = 100*$size;
        $minPoints = 1;
        $points = [];
        $durations = [];

        for ($i = 0; $i < $size; $i++) {
            $points[] = new Point($i, $i*10);
        }

        $dbscan = new DBSCAN($eps, $minPoints);
        for ($i = 0; $i < $repeat; $i++) {
            $duration = -microtime(true);
            list($cluster, $noise) = $dbscan->execute($points);
            $duration += microtime(true);

            $durations[] = $duration;
        }

        $avg = number_format(array_sum($durations) / count($durations), 4);
        $stddev = number_format($this->stats_standard_deviation($durations), 4);
        $best = number_format(min($durations), 4);
        echo "Points: $size  Time: $avg ±$stddev  Best: $best\n";
    }

    public function iterationsProvider()
    {
        // Array content:
        // size (number of points), repeat (times to average)
        return array(
            array(25, 5),
            array(50, 5),
            array(75, 5),
            array(100, 5),
            array(125, 5),
            array(150, 5),
            array(175, 5),
            array(200, 5),
            array(225, 5),
            array(250, 5),
            array(275, 5),
            array(300, 5),
            array(325, 5),
            array(350, 5),
            array(375, 5),
            array(400, 5),
            array(425, 5),
            array(450, 5),
            array(475, 5),
            array(500, 5),
            array(525, 5),
            array(550, 5),
            array(575, 5),
            array(600, 5),
            array(625, 5),
            array(650, 5),
            array(675, 5),
            array(700, 5),
            array(725, 5),
            array(750, 5),
            array(775, 5),
            array(800, 5),
            array(825, 5),
            array(850, 5),
            array(875, 5),
            array(900, 5),
            array(925, 5),
            array(950, 5),
            array(975, 5),
            array(1000, 5),
            array(1100, 5),
            array(1200, 5),
            array(1300, 5),
            array(1400, 5),
            array(1500, 5),
        );
    }

    public function stats_standard_deviation(array $a, $sample = false) {
        $n = count($a);
        if ($n === 0) {
            trigger_error("The array has zero elements", E_USER_WARNING);
            return false;
        }
        if ($sample && $n === 1) {
            trigger_error("The array has only 1 element", E_USER_WARNING);
            return false;
        }
        $mean = array_sum($a) / $n;
        $carry = 0.0;
        foreach ($a as $val) {
            $d = ((double) $val) - $mean;
            $carry += $d * $d;
        };
        if ($sample) {
           --$n;
        }
        return sqrt($carry / $n);
    }

}
