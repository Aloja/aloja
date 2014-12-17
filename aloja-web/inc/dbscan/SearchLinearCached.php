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

    public function regionQuery($reference_id, $eps)
    {
        $neighborhood = array();
        foreach ($this->data as $point_id => $point) {

            // echo "distance from $reference_id to $point is ".$this->distanceClass->distance($point, $this->data[$reference_id])."\n";

            if ($this->getDistance($point_id, $reference_id) < $eps) {
                $neighborhood[$point_id] = $point;
            }
        }
        return $neighborhood;
    }

    private function getDistance($id1, $id2)
    {
        $id_min = min($id1, $id2);
        $id_max = max($id1, $id2);

        if (isset($this->cached[$id_min][$id_max])) {
            // echo "Cached!!!!!!!!!!!!!! $id_min $id_max\n";
            return $this->cached[$id_min][$id_max];
        }
        // echo "NOT cached $id_min $id_max\n";

        $distance = $this->distanceClass->distance($this->data[$id_min], $this->data[$id_max]);
        $this->cached[$id_min][$id_max] = $distance;

        return $distance;
    }
}
