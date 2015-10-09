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
        $this->filters = new Filters($this->container->getDBUtils());
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
        if($this->filters->getWhereClause() != "") {
            $genericParameters = array_merge($genericParameters,
                array('additionalFilters' => $this->filters->getAdditionalFilters(),
                    'filters' => $this->filters->getFiltersArray(),
                    'filterGroups' => $this->filters->getFiltersGroups(),
                   ));
        }

        echo $this->container->getTwig()->render($templatePath,array_merge(
                $genericParameters,
                $parameters)
        );
    }

    public function addOverrideFilters($filters) {
        $this->filters->addOverrideFilters($filters);
    }

    public function removeFilters($filters) {
        $this->filters->removeFilters($filters);
    }

    public function buildFilters($customDefaultValues = array()) {
        $this->filters->getFilters($this->container->getScreenName(),$customDefaultValues);
    }

    public function buildGroupFilters() {
        $this->filters->buildGroupFilters();
    }

    public function buildFilterGroups($customFilterGroups) {
        $this->filters->overrideFilterGroups($customFilterGroups);
    }
}
