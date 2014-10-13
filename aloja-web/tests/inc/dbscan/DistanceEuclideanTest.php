<?php

namespace alojaweb\inc\dbscan;

class DistanceEuclideanTest extends \PHPUnit_Framework_TestCase
{

    public function testDistance1()
    {
        $this->assertEquals(DistanceEuclidean::distance(new Point(1, 1), new Point(1, 2)), 1); 
    }

    public function testDistance2()
    {
        $this->assertEquals(DistanceEuclidean::distance(new Point(2, -1), new Point(-2, 2)), 5); 
    }

}
