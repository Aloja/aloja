<?php

namespace alojaweb\inc\dbscan;

class SearchLinearTest extends \PHPUnit_Framework_TestCase
{

    public function testSearch()
    {
        $search = new SearchLinear();
        $search->setDistanceMode(new DistanceEuclidean());

        $eps = 10;
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
        $search->setData($points);

        $result = $search->regionQuery($points[4], $eps);
        $this->assertCount(4, $result);
        $this->assertEquals($result[4], $points[4]);
        $this->assertEquals($result[5], $points[5]);
        $this->assertEquals($result[6], $points[6]);
        $this->assertEquals($result[7], $points[7]);
    }

}
