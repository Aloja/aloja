<?php

namespace alojaweb\inc\dbscan;

use alojaweb\inc\dbscan\DistanceInterface;

class SearchLinearCached implements SearchInterface
{

    protected $data;
    protected $distanceClass;
    protected $cached;

    public function setData(&$data)
    {
        $this->data = $data;
        $this->cached = array();
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

            if ($this->getDistance($point, $reference) < $eps) {
                $neighborhood[$point_id] = $point;
            }
        }
        return $neighborhood;
    }

    private function getDistance($point1, $point2)
    {
        $comp = $point1->compareTo($point2);
        $str1 = (string)($comp <= 0 ? $point1 : $point2);
        $str2 = (string)($comp <= 0 ? $point2 : $point1);

        if (array_key_exists($str1, $this->cached)) {
            if (array_key_exists($str2, $this->cached[$str1])) {
                // echo "Cached!!!!!!!!!!!!!! $str1 $str2\n";
                return $this->cached[$str1][$str2];
            }
        }
        // echo "NOT cached $str1 $str2\n";

        $distance = $this->distanceClass->distance($point1, $point2);
        $this->cached[$str1][$str2] = $distance;

        return $distance;
    }
}
