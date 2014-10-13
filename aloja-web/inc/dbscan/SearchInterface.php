<?php

namespace alojaweb\inc\dbscan;

use alojaweb\inc\dbscan\DistanceInterface;

interface SearchInterface
{

    public function setData(&$data);

    public function setDistanceMode(DistanceInterface $distance);

    public function regionQuery($reference, $eps);

}
