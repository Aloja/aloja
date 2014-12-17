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

    /**
     * @dataProvider compareToProvider
     */
    public function testCompareTo($p1, $p2, $compare_result)
    {
        $this->assertEquals($compare_result, $p1->compareTo($p2));
    }

    public function compareToProvider()
    {
        // Array content:
        // point 1, point 2, compare result
        return array(
            array(new Point(0, 0), new Point(0, 0), 0),
            array(new Point(15, 15), new Point(15, 15), 0),
            array(new Point(14, 16), new Point(14, 16), 0),

            array(new Point(15, 15), new Point(15, 14), 1),
            array(new Point(15, 15), new Point(15, 16), -1),
            array(new Point(15, 14), new Point(15, 15), -1),
            array(new Point(15, 16), new Point(15, 15), 1),

            array(new Point(15, 15), new Point(14, 15), 1),
            array(new Point(15, 15), new Point(14, 14), 1),
            array(new Point(15, 15), new Point(14, 16), 1),
            array(new Point(15, 14), new Point(14, 15), 1),
            array(new Point(15, 16), new Point(14, 15), 1),

            array(new Point(15, 15), new Point(16, 15), -1),
            array(new Point(15, 15), new Point(16, 14), -1),
            array(new Point(15, 15), new Point(16, 16), -1),
            array(new Point(15, 14), new Point(16, 15), -1),
            array(new Point(15, 16), new Point(16, 15), -1),

            array(new Point(14, 15), new Point(15, 15), -1),
            array(new Point(14, 15), new Point(15, 14), -1),
            array(new Point(14, 15), new Point(15, 16), -1),
            array(new Point(14, 14), new Point(15, 15), -1),
            array(new Point(14, 16), new Point(15, 15), -1),

            array(new Point(16, 15), new Point(15, 15), 1),
            array(new Point(16, 15), new Point(15, 14), 1),
            array(new Point(16, 15), new Point(15, 16), 1),
            array(new Point(16, 14), new Point(15, 15), 1),
            array(new Point(16, 16), new Point(15, 15), 1),
        );
    }
}
