<?php

namespace alojaweb\inc\dbscan;

class ClusterTest extends \PHPUnit_Framework_TestCase
{

    public function testClusterConstruct()
    {
        $cluster = new Cluster();

        $this->assertNull($cluster->getXMin());
        $this->assertNull($cluster->getXMax());
        $this->assertNull($cluster->getYMin());
        $this->assertNull($cluster->getYMax());
    }

    public function testClusterConstructValue()
    {
        $cluster = new Cluster(
            new Point(1, 2)
        );

        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 1);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 2);
    }

    public function testClusterConstructValues()
    {
        $cluster = new Cluster(
            new Point(1, 2),
            new Point(3, 4)
        );

        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 3);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 4);
    }

    public function testClusterConstructArray()
    {
        $cluster = new Cluster(
            array(
                new Point(1, 2),
                new Point(3, 4),
            )
        );

        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 3);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 4);
    }

    public function testClusterConstructClusters()
    {
        $cluster = new Cluster(
            new Cluster(
                new Point(1, 2)
            ),
            new Cluster(
                new Point(3, 4)
            )
        );

        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 3);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 4);
    }

    public function testClusterContains()
    {
        $point1 = new Point(1, 1);
        $point2 = new Point(1, 1);

        $cluster = new Cluster();
        $cluster[] = $point1;

        $this->assertTrue($cluster->contains($point1));
        $this->assertFalse($cluster->contains($point2));

        $cluster[] = $point2;
        $this->assertTrue($cluster->contains($point1));
        $this->assertTrue($cluster->contains($point2));
    }

    public function testClusterMinMax()
    {
        $cluster = new Cluster();

        $cluster[] = new Point(1, 2);
        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 1);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 2);

        $cluster[] = new Point(2, 2);
        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 2);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 2);

        $cluster[] = new Point(1.5, 2);
        $this->assertEquals($cluster->getXMin(), 1);
        $this->assertEquals($cluster->getXMax(), 2);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 2);

        $cluster[] = new Point(0, 2);
        $this->assertEquals($cluster->getXMin(), 0);
        $this->assertEquals($cluster->getXMax(), 2);
        $this->assertEquals($cluster->getYMin(), 2);
        $this->assertEquals($cluster->getYMax(), 2);

        $cluster[] = new Point(0, -2);
        $this->assertEquals($cluster->getXMin(), 0);
        $this->assertEquals($cluster->getXMax(), 2);
        $this->assertEquals($cluster->getYMin(), -2);
        $this->assertEquals($cluster->getYMax(), 2);

        $cluster[] = new Point(0, 10);
        $this->assertEquals($cluster->getXMin(), 0);
        $this->assertEquals($cluster->getXMax(), 2);
        $this->assertEquals($cluster->getYMin(), -2);
        $this->assertEquals($cluster->getYMax(), 10);
    }

}
