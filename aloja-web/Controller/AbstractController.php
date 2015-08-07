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

    public function render($templatePath, $parameters) {
        $genericParameters = array('selected' => $this->container->getScreenName());
        if($this->filters) {
            $genericParameters = array_merge($genericParameters, $this->filters->getSelectedFilters(),
                array('options' => $this->filters->getFilterOptions($this->container->getDBUtils())));
        }

        echo $this->container->getTwig()->render($templatePath,array_merge(
                $genericParameters,
                $parameters)
        );
    }

    public function buildFilters($customDefaultValues = array()) {
        $this->filters = new Filters();
        $this->filters->getFilters($this->container->getDBUtils(),$this->container->getScreenName(),$customDefaultValues);
    }

    public function buildGroupFilters() {
        if(!$this->filters) {
            $this->filters = new Filters();
        }
        $this->filters->buildGroupFilters();
    }
}
