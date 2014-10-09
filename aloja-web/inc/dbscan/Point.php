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

    /**
     * Compares the current object to the passed $other.
     *
     * Returns 0 if they are semantically equal, 1 if the other object is less
     * than the current one, or -1 if its more than the current one.
     */
    public function compareTo($other)
    {
        if ($this->x > $other->x) {
            return 1;
        } else if ($this->x < $other->x) {
            return -1;
        } else {
            if ($this->y > $other->y) {
                return 1;
            } else if ($this->y < $other->y) {
                return -1;
            } else {
                return 0;
            }
        }
    }

    public function __toString()
    {
        return "(".$this->x.",".$this->y.")";
    }

}
