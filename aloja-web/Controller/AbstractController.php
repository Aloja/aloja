<?php

/**
 * Base controller class
 *
 * You should NOT use this to manage specific routes
 */

namespace alojaweb\Controller;

use \alojaweb\Filters\Filters;

class AbstractController
{
    /**
	 * @var \alojaweb\Container\Container
	 */
    protected $container;

    /**
     * @var \alojaweb\Filters\Filters
     */
    protected $filters;

    public function __construct($container = null)
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

    public function render($screen, $parameters) {
        $genericParameters = array('selected' => $this->container->getScreenName());
        if($this->filters) {
            $genericParameters = array_merge($genericParameters, $this->filters->getSelectedFilters());
        }

        echo $this->container->getTwig()->render($screen,array_merge(
                $genericParameters,
                $parameters)
        );
    }

    public function buildFilters($dbConnection = null) {
        if(!$dbConnection)
            $dbConnection = $this->container->getDBUtils();

        $this->filters = new Filters();
        $this->filters->getFilters($dbConnection,$this->container->getScreenName());
    }
}
