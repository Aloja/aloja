<?php

namespace alojaweb\inc\dbscan;

class DBSCAN
{

    protected $eps;
    protected $minPoints;

    protected $search;

    protected $visited;
    protected $cluster;
    protected $noise;

    public function __construct($eps, $minPoints, DistanceInterface $distance = null, SearchInterface $search = null)
    {
        if ($distance === null) {
            $distance = new DistanceEuclidean();
        }

        if ($search === null) {
            $search = new SearchLinear();
        }

        $this->eps = $eps;
        $this->minPoints = $minPoints;

        $this->search = $search;
        $this->search->setDistanceMode($distance);
    }

    public function execute(array $data)
    {
        // Initialize internal variables
        $this->init($data);

        foreach ($data as $point_id => $point) {

            // Skip if point already visited
            if ($this->isVisited($point)) {
                continue;
            }

            // Mark point as visited
            $this->setVisited($point);

            // Search near points
            $neighborhood = $this->search->regionQuery($point, $this->eps);

            // echo "neighborhood\n";
            // print_r($neighborhood);
            // echo "\n\n";

            if (count($neighborhood) < $this->minPoints) {
                // Point is noise
                $this->noise[] = $point;
            } else {
                // Create new cluster
                $this->cluster[] = array();
                $this->expandCluster($point_id, $point, $neighborhood);
            }
        }

        return array($this->cluster, $this->noise);
    }

    private function expandCluster(&$point_id, &$point, &$neighborhood) {
        // Add point to current cluster
        $this->toCluster($point);

        // Iterate all neighbors
        $iterator = new \AppendIterator();
        $iterator->append(new \ArrayIterator($neighborhood));
        foreach ($iterator as $neighbor_id => $neighbor) {

            // echo "  foreach in $neighbor ($neighbor_id)\n";

            // Neighbor not yet visited
            if (!$this->isVisited($neighbor)) {

                // Mark neighbor as visited
                $this->setVisited($neighbor);

                // Search the neighbor's neighborhood for new points
                $neighbor_neighborhood = $this->search->regionQuery($neighbor, $this->eps);

                // echo "  current neighbor $neighbor has this neighbor_neighborhood around:\n";
                // print_r($neighbor_neighborhood);

                if (count($neighbor_neighborhood) >= $this->minPoints) {
                    // Add new points to the loop
                    $iterator->append(new \ArrayIterator($neighbor_neighborhood));

                    // echo "  appended!!\n";
                }
            }

            // Add to cluster
            $this->toCluster($neighbor);
        }

        // echo "  END FOREACH\n";
    }

    private function init(array $data) {
        // Fill search class with all the points
        $this->search->setData($data);

        // Initialize auxiliary variables
        $this->visited = array();
        $this->cluster = array();
        $this->noise = array();
    }

    private function isVisited($point)
    {
        return in_array($point, $this->visited, $strict = true);
    }

    private function setVisited($point)
    {
        $this->visited[] = $point;
    }

    private function toCluster($point)
    {
        $last_cluster = &$this->cluster[count($this->cluster) - 1];
        // Don't duplicate points inside the same cluster
        if (!in_array($point, $last_cluster, $strict = true)) {
            $last_cluster[] = $point;
        }
    }
}
