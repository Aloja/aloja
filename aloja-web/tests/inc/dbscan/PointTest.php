<?php

namespace alojaweb\inc\dbscan;

class PointTest extends \PHPUnit_Framework_TestCase
{

    public function testPointConstruct()
    {
        $p = new Point(1, 2);
        $this->assertEquals($p->x, 1);
        $this->assertEquals($p->y, 2);
    }

    public function testComparisonOperator()
    {
        $this->assertTrue(new Point(1, 1) == new Point(1, 1));
        $this->assertFalse(new Point(1, 1) == new Point(1, 2));
        $this->assertFalse(new Point(1, 1) == new Point(2, 1));
        $this->assertFalse(new Point(1, 1) == new Point(2, 2));

        $this->assertFalse(new Point(1, 1) != new Point(1, 1));
        $this->assertTrue(new Point(1, 1) != new Point(1, 2));
        $this->assertTrue(new Point(1, 1) != new Point(2, 1));
        $this->assertTrue(new Point(1, 1) != new Point(2, 2));
    }

    public function testIdentityOperator()
    {
        $this->assertFalse(new Point(1, 1) === new Point(1, 1));
        $this->assertFalse(new Point(1, 1) === new Point(1, 2));
        $this->assertFalse(new Point(1, 1) === new Point(2, 1));
        $this->assertFalse(new Point(1, 1) === new Point(2, 2));
    }

    public function testInArray()
    {
        $p1 = new Point(1, 1);
        $p2 = new Point(1, 1);

        $data = array();
        $data[] = $p1;

        $this->assertTrue(in_array($p1, $data, $strict = true));
        $this->assertFalse(in_array($p2, $data, $strict = true));

        $data[] = $p2;
        $this->assertTrue(in_array($p1, $data, $strict = true));
        $this->assertTrue(in_array($p2, $data, $strict = true));
    }
}
