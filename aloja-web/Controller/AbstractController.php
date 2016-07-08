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
        $filters = $this->filters->getFiltersArray();

        $selected_filters = array();
        foreach ($filters as $name => $filter) {
            $key = 'currentChoice';
            if (!array_key_exists($key, $filter)) continue;

            $current_choice = $filter[$key];
            if (is_array($current_choice) && count($current_choice) > 0) {
                $selected_filters[$name] = $current_choice;
            }
            elseif (is_string($current_choice)) {
                $selected_filters[$name] = array($current_choice);
            }
        }

        if($this->filters->getWhereClause() != "") {
            $genericParameters = array_merge($genericParameters,
                array('additionalFilters' => $this->filters->getAdditionalFilters(),
                    'filters' => $filters,
                    'filterGroups' => $this->filters->getFiltersGroups(),
                   ));
        }

        echo $this->container->getTwig()->render($templatePath,array_merge(
                $genericParameters,
                $parameters,
                array('selectedFilters' => $selected_filters))
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
