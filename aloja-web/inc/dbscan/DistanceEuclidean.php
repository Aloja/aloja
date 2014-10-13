<?php

namespace alojaweb\inc\dbscan;

class DistanceEuclidean implements DistanceInterface
{

    public static function distance(Point $a, Point $b)
    {
        return sqrt(pow(($a->x - $b->x), 2) + pow(($a->y - $b->y), 2));
    }

}
