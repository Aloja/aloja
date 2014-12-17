<?php

namespace alojaweb\inc\dbscan;

/**
 * A array-like class to store points in a cluster. Keeps calculated the
 * max/min values of X and Y.
 * 
 * WARNING: only tested adding points to the cluster, editing or removing
 * points from the cluster may result in undefined behaviour.
 */
class Cluster extends \ArrayObject
{

    private $x_min;
    private $x_max;
    private $y_min;
    private $y_max;

    private $centroid;

    /**
     * Updates the calculated internal values with the passed value
     */
    private function updateValues($value)
    {
        // If any value is null, initialize with new value
        if ($this->x_min === null) $this->x_min = $value->x;
        if ($this->x_max === null) $this->x_max = $value->x;
        if ($this->y_min === null) $this->y_min = $value->y;
        if ($this->y_max === null) $this->y_max = $value->y;
        if ($this->centroid === null) $this->centroid = new Point($value->x, $value->y);

        // Update values if necessary
        if ($this->x_min > $value->x) $this->x_min = $value->x;
        if ($this->x_max < $value->x) $this->x_max = $value->x;
        if ($this->y_min > $value->y) $this->y_min = $value->y;
        if ($this->y_max < $value->y) $this->y_max = $value->y;

        // Recalculate centroid with new value
        $size = $this->count();
        $this->centroid->x = ($this->centroid->x * $size + $value->x) / ($size + 1);
        $this->centroid->y = ($this->centroid->y * $size + $value->y) / ($size + 1);
    }

    /**
     * Return the minimum X value of the cluster, or null if empty
     */
    public function getXMin()
    {
        return $this->x_min;
    }

    /**
     * Return the maximum X value of the cluster, or null if empty
     */
    public function getXMax()
    {
        return $this->x_max;
    }

    /**
     * Return the minimum Y value of the cluster, or null if empty
     */
    public function getYMin()
    {
        return $this->y_min;
    }

    /**
     * Return the maximum Y value of the cluster, or null if empty
     */
    public function getYMax()
    {
        return $this->y_max;
    }

    /**
     * Return the centroid of the cluster, or null if empty
     */
    public function getCentroid()
    {
        return $this->centroid;
    }

    /**
     * Checks if a value already exists in the cluster
     */
    public function contains($value)
    {
        return in_array($value, (array)$this, $strict = true);
    }

    //
    // Superclass overrides
    //

    public function __construct()
    {
        // Call superclass
        $result = parent::__construct();

        // Iterate and append all arguments
        // (no need to call updateValues(), offsetSet will take care of it)
        $args = func_get_args();
        foreach($args as $arg) {
            if (is_array($arg) || $arg instanceof \Traversable) {
                // Argument is array-like, append all its values
                foreach ($arg as $value) {
                    $this[] = $value;
                }
            } else {
                // Append the argument
                $this[] = $arg;
            }
        }

        // Return superclass return
        return $result;
    }

    public function offsetSet($offset, $value)
    {
        // Update internal values
        $this->updateValues($value);

        // Call superclass
        return parent::offsetSet($offset, $value);
    }
}
