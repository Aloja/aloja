<?php

namespace alojaweb\inc\dbscan;

use alojaweb\inc\dbscan\Point;

interface DistanceInterface
{

    public static function distance(Point $a, Point $b);

}
