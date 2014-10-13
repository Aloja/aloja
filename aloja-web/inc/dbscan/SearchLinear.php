<?php

namespace alojaweb\inc\dbscan;

use alojaweb\inc\dbscan\DistanceInterface;

class SearchLinear implements SearchInterface
{

    protected $data;
    protected $distanceClass;

    public function setData(&$data)
    {
        $this->data = $data;
    }

    public function setDistanceMode(DistanceInterface $distance)
    {
        $this->distanceClass = $distance;
    }

    public function regionQuery($reference, $eps)
    {
        $neighborhood = array();
        foreach ($this->data as $point_id => $point) {

            // echo "distance from $reference to $point is ".$this->distanceClass->distance($point, $reference)."\n";

            if ($this->distanceClass->distance($point, $reference) < $eps) {
                $neighborhood[$point_id] = $point;
            }
        }
        return $neighborhood;
    }

}
