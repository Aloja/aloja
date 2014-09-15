<?php

namespace alojaweb\inc\dbscan;

class Point
{

    public $x;
    public $y;
    public $info;

    public function __construct($x, $y, $info = null)
    {
        $this->x = $x;
        $this->y = $y;
        $this->info = $info;
    }

    public function __toString()
    {
        return "(".$this->x.",".$this->y.")";
    }

}
