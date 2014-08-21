<?php

/**
 * Base controller class
 *
 * You should NOT use this to manage specific routes
 */

namespace alojaweb\Controller;

class AbstractController
{
    /**
	 * @var \alojaweb\Container\Container
	 */
    protected $container;

    public function __construct(\alojaweb\Container\Container $container = null)
    {
        $this->container = $container;
    }

    public function getContainer()
    {
        return $this->container;
    }

    public function setContainer($container)
    {
        $this->container = $container;
    }
}
