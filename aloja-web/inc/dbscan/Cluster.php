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
     * Checks if a value already exists in the cluster
     */
    public function contains($value)
    {
        return in_array($value, (array)$this, $strict = true);
    }

    //
    // Superclass overrides
    //

    public function offsetSet($offset, $value)
    {
        // If any value is null, initialize with new value
        if ($this->x_min === null) $this->x_min = $value->x;
        if ($this->x_max === null) $this->x_max = $value->x;
        if ($this->y_min === null) $this->y_min = $value->y;
        if ($this->y_max === null) $this->y_max = $value->y;

        // Update values if necessary
        if ($this->x_min > $value->x) $this->x_min = $value->x;
        if ($this->x_max < $value->x) $this->x_max = $value->x;
        if ($this->y_min > $value->y) $this->y_min = $value->y;
        if ($this->y_max < $value->y) $this->y_max = $value->y;

        // Call superclass
        return parent::offsetSet($offset, $value);
    }
}
