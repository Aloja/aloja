<?php

namespace alojaweb\Filters;

use \alojaweb\inc\DBUtils;
use \alojaweb\inc\Utils;

class Filters
{
    private $whereClause;

    private $additionalFilters;

    private $filters;

    private $aliasesTables;

    private $filterGroups;

    /**
     * @\alojaweb\inc\DBUtils
     */
    private $dbConnection;

    public function __construct(\alojaweb\inc\DBUtils $dbConnection) {
        $this->dbConnection = $dbConnection;

        /* In this array there are the filter names with its default options
         * that will be overwritten by the given custom defaults and options if given
         * Array with filter => filter specific settings
         *
         * Specific settings is an array with
         * types: inputText, inputNumber[{le,ge}], inputDate[{le,ge}], selectOne, selectMultiple, checkbox[Negated]
         * default: null (any), array(values)
         * table: associated DB table name
         * parseFunction: function to parse special filter, for filters that need a lot of customization
         *
         * Very custom filters such as advanced filters not in this array
         *
         */
        $this->filters = array(
            'bench' => array('table' => 'execs', 'default' => array('terasort','wordcount'), 'type' => 'selectMultiple', 'label' => 'Benchmarks:',),
            'datasize' => array('database' => 'aloja2', 'table' => 'execs', 'default' => null, 'type' => 'selectMultiple', 'label' => 'Datasize: ',
                'beautifier' => function($value) {
                  $nDigits = strlen((string)$value);
                  $return = '';
                  if($nDigits >= 4) {
                      if($nDigits >= 8) {
                          if($nDigits >= 10) {
                             if($nDigits >= 13) {
                                 $return =  ceil(($value/1000000000000)) . ' TB';
                             } else
                                 $return =  ceil(($value/1000000000)) . ' GB';
                          } else
                              $return = ceil(($value/1000000)) . ' MB';
                      } else
                          $return = ceil(($value/1000)) . ' KB';
                  } else
                      $return = $value . ' B';

                  return $return;
                },
                'parseFunction' => 'parseDatasize'),
            'scale_factor' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple', 'label' => 'Scale factor: '),
            'bench_type' => array('table' => 'execs', 'default' => array('HiBench'), 'type' => 'selectOne', 'label' => 'Bench suite:'),
            'net' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple', 'label' => 'Network:',
                'beautifier' => function($value) {
                    return Utils::getNetworkName($value);
                }),
            'disk' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple', 'label' => 'Disk:'),
            'blk_size' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Block size (b):',
                'beautifier' => function($value) {
                    return $value . ' MB';
                }),
            'comp' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Compression (c):',
            'beautifier' => function($value) {
                return Utils::getCompressionName($value);
            }),
            'id_cluster' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Clusters (CL):',
                'beautifier' => function($value) {
                    return $this->filters['id_cluster']['namesClusters'][$value];
                },
                'generateChoices' => function() {
                    $choices = $this->dbConnection->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name  from aloja2.execs e join aloja2.clusters c using (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
                    $returnChoices = array();
                    foreach($choices as $choice) {
                        $returnChoices[] = $choice['id_cluster'];
                        //Not nice, but saves multiple queries to DB in the beautifier
                        $this->filters['id_cluster']['namesClusters'][$choice['id_cluster']] = $choice['name'];
                    }
                    return $returnChoices;
                }),
            'maps' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Maps:',
                'beautifier' => function($value) {
                    if($value == 0)
                        return 'N/A';
                    else
                        return $value;
                }),
            'replication' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Replication (r):'),
            'iosf' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'I/O sort factor (I):'),
            'iofilebuf' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'I/O file buffer:',
                'beautifier' => function($value) {
                    $suffix = ' KB';
                    if($value >= 1024) {
                        $value /= 1024;
                        $suffix = ' MB';
                    }
                    return $value.$suffix;
                }),
            'provider' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'Provider:'),
            'vm_OS' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'VM OS:'),
            'datanodes' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'Cluster datanodes:'),
            'vm_size' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'VM Size:'),
            'vm_cores' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'VM cores:'),
            'vm_RAM' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'VM RAM:',
                'beautifier' => function($value) {
                   return number_format($value,0) . ' GB';
                }),
            'type' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple','label' => 'Cluster type:'),
            'hadoop_version' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple','label' => 'Hadoop version:'),
            'minexetime' => array('table' => 'execs', 'field' => 'exe_time', 'default' => 50, 'type' => 'inputNumberge','label' => 'Min exec time:'),
            'maxexetime' => array('table' => 'execs', 'field' => 'exe_time', 'default' => null, 'type' => 'inputNumberle','label' => 'Max exec time:'),
            'datefrom' => array('table' => 'execs', 'field' => 'start_time', 'default' => null, 'type' => 'inputDatege','label' => 'Date from:'),
            'dateto' => array('table' => 'execs', 'field' => 'end_time', 'default' => null, 'type' => 'inputDatele','label' => 'Date to:'),
            'money' => array('table' => 'mixed', 'field' => '(clustersAlias.cost_hour/3600)*execsAlias.exe_time',
                    'default' => null, 'type' => 'inputNumberle','label' => 'Max cost (US$):'),
            'valid' => array('table' => 'execs', 'field' => 'valid', 'type' => 'checkbox', 'default' => 1, 'label' => 'Only valid execs'),
            'filter' => array('table' => 'execs', 'field' => 'filter', 'type' => 'checkboxNegated', 'default' => 1, 'label' => 'Filter'),
            'prepares' => array('table' => 'execs', 'type' => 'checkbox', 'default' => 0, 'label' => 'Include prepares',
                'parseFunction' => function() {
                    $whereClause = "";
                    $values = 0;
                    if(isset($_GET['prepares'])) {
                        $values = 1;
                    } else {
                        $values = 0;
                        $whereClause = " AND execsAlias.bench NOT LIKE 'prep_%' ";
                    }

                    return array('currentChoice' => $values, 'whereClause' => $whereClause);
                }),
            'perf_details' => array('table' => 'execs', 'type' => 'checkbox', 'default' => 0, 'label' => 'Only execs with perf details'),
        );

        $this->aliasesTables = array('execs' => '','clusters' => '');

        //To render groups on template. Rows are of 2 columns each. emptySpace puts an empty element on the rendered row
        $this->filterGroups = array('basic' => array(
                'label' => 'Basic filters',
                'filters' => array('money','bench','bench_type','datasize','scale_factor','id_cluster','net','disk'),
                'tabOpenDefault' => true),
            'hardware' => array(
                'label' => 'Hardware',
                'filters' => array('datanodes','vm_size','vm_cores','vm_RAM','type','provider','vm_OS'),
                'tabOpenDefault' => false),
            'hadoop' => array(
                'label' => 'Hadoop',
                'filters' => array('maps','comp','replication','blk_size','iosf','iofilebuf','hadoop_version'),
                'tabOpenDefault' => false),
            'advanced' => array(
                'label' => 'Advanced filters',
                'filters' => array('valid','filter','prepares','perf_details','datefrom','dateto','minexetime','maxexetime'),
                'tabOpenDefault' => false
            )
        );
    }

    private function parseDatasize()
    {
        $values = Utils::get_GET_intArray('datasize');
        $this->filters['datasize']['currentChoice'] = $values;
        foreach ($values as $value) {
            $definition = $this->filters['datasize'];
            $DBreference = ($definition['table'] != 'mixed') ? "${definition['table']}Alias." : '';
            $DBreference .= (isset($definition['field'])) ? $definition['field'] : 'datasize';
            $errorMargin = $this->getErrorMargin($value);
            $maxValue = $value + $errorMargin;
            $minValue = $value - $errorMargin;
            $this->whereClause .= " AND $DBreference >= $minValue AND $DBreference <= $maxValue";
        }
    }

    public function getWhereClause($aliasesToReplace = array()) {
        $whereClause = $this->whereClause;
        foreach($this->aliasesTables as $table => $alias) {
            if(array_key_exists($table, $aliasesToReplace)) {
                $whereClause = str_replace("${table}Alias.",$aliasesToReplace[$table].'.',$whereClause);
            } else {
                $whereClause = str_replace("${table}Alias.",$alias,$whereClause);
            }
        }
        return $whereClause;
    }

    public function getAdditionalFilters() {
        return $this->additionalFilters;
    }

    public function generateFilterChoices() {
        foreach($this->filters as $filterName => $definition) {
            $type = (isset($definition['type'])) ? $definition['type'] : 'null';
            if($type == 'selectOne' || $type == 'selectMultiple') {
                if (isset($definition['generateChoices'])) {
                    $choices = $definition['generateChoices']();
                    $this->filters[$filterName]['choices'] = $choices;
                } else {
                    $fromClause = "aloja2.execs";
                    if ($definition['table'] == 'clusters') {
                        $fromClause .= ' JOIN clusters USING (id_cluster) ';
                    }
                    $field = isset($definition['field']) ? $definition['field'] : $filterName;
                    $queryChoices = "SELECT DISTINCT $field FROM $fromClause WHERE 1 AND valid = 1 AND filter = 0 " . DBUtils::getFilterExecs() . " ORDER BY $field ASC";
                    $choices = $this->dbConnection->get_rows($queryChoices);
                    foreach($choices as $choice) {
                        $this->filters[$filterName]['choices'][] = $choice[$field];
                    }
                }
            }
        }
    }

    private function parseFilters() {
        foreach($this->filters as $filterName => $definition) {
            if(isset($definition['parseFunction'])) {
                if(is_callable($definition['parseFunction'])) {
                    $parser = call_user_func($definition['parseFunction']);
                    $this->whereClause .= " ${parser['whereClause']} ";
                    $this->filters[$filterName]['currentChoice'] = $parser['currentChoice'];
                } else
                    call_user_func(array($this,$definition['parseFunction']));
            } else {
                $DBreference = ($definition['table'] != 'mixed') ? "${definition['table']}Alias." : '';
                $DBreference .= (isset($definition['field'])) ? $definition['field'] : $filterName;

                $values = null;
                if($definition['type'] == 'checkbox' ||
                    $definition['type'] == 'checkboxNegated') {
                    if(isset($_GET[$filterName])) {
                        $values = 1;
                    } else if($this->formIsSubmitted()) {
                        $values = 0;
                    } else
                        $values = isset($definition['default']) ? $definition['default'] : 0;
                }  else if (isset($_GET[$filterName])) {
                    $values = $_GET[$filterName];
                    if(is_array($values)) {
                        array_walk($values, function (&$item) {
                            $item = str_replace('%2F', '/', $item);
                        });
                    } else if($values != "" && $values != null)
                        $values = str_replace('%2F', '/', $values);

                } else if ($definition['default'] != null) {
                    $values = $definition['default'];
                }
                $this->filters[$filterName]['currentChoice'] = $values;

                if ($values != null) {
                    $type = $definition['type'];
                    if ($type == "selectOne" || $type == "selectMultiple") {
                        array_walk($values, function (&$item) {
                            $item = "'$item'";
                        });
                        $this->whereClause .= " AND $DBreference IN (" . join(',', $values) . ")";
                    } else if ($type == "inputText" || $type == "inputNumber") {
                        $this->whereClause .= " AND $DBreference = $values";
                    } else if ($type == "inputNumberle") {
                        $this->whereClause .= " AND $DBreference <= $values";
                    } else if ($type == "inputNumberge") {
                        $this->whereClause .= " AND $DBreference >= $values";
                    } else if ($type == "inputDatele") {
                        $this->whereClause .= " AND $DBreference <= '$values'";
                    } else if ($type == "inputDatege") {
                        $this->whereClause .= " AND $DBreference >= '$values'";
                    } else if($type == 'checkbox' || $type == 'checkboxNegated') {
                        if($type == 'checkboxNegated')
                            $values = ($values == 0) ? 1 : 0;

                        $this->whereClause .= " AND $DBreference = $values";
                    }
                }
            }
        }
    }

    private function parseAdvancedFilters() {
        $alias = 'execsAlias';
        $includePrepares = false;
        if(isset($_GET['execsfilters'])) {
            $filters = $_GET['execsfilters'];
            if(in_array("valid",$filters))
                $this->whereClause .= ' AND '.$alias.'.valid = 1 ';
            if(in_array("prepares",$filters))
                $includePrepares = true;
            if(in_array("perfdetails",$filters))
                $this->whereClause .= ' AND '.$alias.'.perf_details = 1 ';

            if(in_array("outliers", $filters)) {
                if(in_array("warnings", $filters))
                    $this->whereClause .= " AND $alias.outlier IN (0,1,2) ";
                else
                    $this->whereClause .= " AND $alias.outlier IN (0,1) ";
            }

            $this->whereClause .= (in_array("filter",$filters)) ? ' AND '.$alias.'.filter = 0 ' : '';

        } else if(!$this->formIsSubmitted()) {
            $_GET['execsfilters'][] = 'valid';
            $_GET['execsfilters'][] = 'filter';

            $this->whereClause .= ' AND '.$alias.'.valid = 1 AND '.$alias.'.filter = 0 ';
        }

        if(!$includePrepares)
            $this->whereClause .= " AND $alias.bench not like 'prep_%' AND $alias.bench_type not like 'HDI-prep%'";

        $this->filters['execsfilters']['currentChoice'] = (isset($_GET['execsfilters'])) ? $_GET['execsfilters'] : "";
    }

    public function getFilters($screenName, $customFilters) {

        $this->readPresets($screenName);

        foreach($customFilters as $index => $options) {
            //Modify existing filter
            if(array_key_exists($index,$this->filters)) {
                foreach($options as $key => $value)
                    $this->filters[$index][$key] = $value;
            } else {
                //Add new filter
                $this->filters[$index] = $options;
                $filterGroup = (isset($options['filterGroup'])) ? $options['filterGroup'] : 'basic';
                if(!isset($this->filterGroups[$filterGroup])) {
                    $this->filterGroups[$filterGroup]['filters'] = array();
                    $this->filterGroups[$filterGroup]['tabOpenDefault'] = false;
                }

                array_unshift($this->filterGroups[$filterGroup]['filters'],$index);
            }
        }

        $this->parseFilters();
        $this->generateFilterChoices();
        $this->processExtraData();
    }

    public function getFiltersArray() {
        return $this->filters;
    }

    private function readPresets($screenName) {
        /* If sizeof GET > 1 means form has been submitted
         * therefore we don't want to overwrite selected filters - including presets -
        */

        if(sizeof($_GET) <= 1)
            $this->initDefaultPreset($screenName);

        $this->additionalFilters['presets']['currentChoice'] = (isset($_GET['presets'])) ? $_GET['presets'] : "none";
        $this->additionalFilters['presets']['choices'] = $this->dbConnection->get_rows("
          SELECT * FROM aloja2.filter_presets WHERE selected_tool = '$screenName' ORDER BY short_name DESC");
    }

    private function initDefaultPreset($screen) {
        $presets = $this->dbConnection->get_rows("SELECT * FROM aloja2.filter_presets WHERE default_preset = 1 AND selected_tool = '$screen'");
        if(count($presets)>=1) {
            $url = $presets[0]['URL'];
            $this->additionalFilters['presets']['default'] = $url;
            $filters = explode('?',$url)[1];
            $filters = explode('&',$filters);
            $filters = array_filter($filters); //make sure we don't get empty values in cases like ?&afa=dfa
            foreach($filters as $filter) {
                $explode = explode('=',$filter);
                $filterName = $explode[0];
                $isArray = false;
                if($filterName[strlen($filterName)-1] == "]") {
                    $filterName = substr($filterName,0,strlen($filterName)-2);
                    $isArray = true;
                }

                $filterValue = $explode[1];

                if($isArray)
                    $_GET[$filterName][] = $filterValue;
                else
                    $_GET[$filterName] = $filterValue;
            }
        }
    }

    public function buildGroupFilters($defaultGroups = array('disk')) {
        if(isset($_GET['selected-groups']) && $_GET['selected-groups'] != "") {
            $this->additionalFilters['selectedGroups'] = explode(",", $_GET['selected-groups']);
        } else {
            $this->additionalFilters['selectedGroups'] = $defaultGroups;
        }
    }

    public function getGroupFilters() {
        return $this->additionalFilters['selectedGroups'];
    }

    public function getFiltersGroups() {
        return $this->filterGroups;
    }

    private function formIsSubmitted() {
        return isset($_GET['submit']);
    }

    private function processExtraData() {
        //Getting option to tell JS what to filter on rendering
        $benchsDatasize = $this->dbConnection->get_rows("SELECT DISTINCT bench_type,bench,datasize FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." GROUP BY bench_type,bench,datasize ORDER BY bench ASC ");
        $dataBenchs = array();
        $availDatasizes = array();
        foreach($benchsDatasize as $row) {
            $datasize = $this->roundDatasize($row['datasize']);
            if(!isset($availDatasizes[$row['bench_type']]) ||
                !isset($availDatasizes[$row['bench_type']][$row['bench']]) ||
                !in_array($datasize, $availDatasizes[$row['bench_type']][$row['bench']])) {
                    $dataBenchs[$row['bench_type']][$row['bench']][] = $row['datasize'];
                    $availDatasizes[$row['bench_type']][$row['bench']][] = $datasize;
            }
        }

        $this->additionalFilters['datasizesInfo'] = json_encode($dataBenchs);

        //Getting scale factors per bench
        $scaleFactors = array();
        $benchsScaleFactors = $this->dbConnection->get_rows("SELECT DISTINCT bench_type,bench,scale_factor FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." GROUP BY bench_type,bench,datasize ORDER BY bench ASC ");
        foreach($benchsScaleFactors as $row) {
            $scaleFactor = $row['scale_factor'];
            $scaleFactors[$row['bench_type']][$row['bench']][] = $scaleFactor;
        }

        $this->additionalFilters['scaleFactorsInfo'] = json_encode($scaleFactors);
    }

    private function roundDatasize($value) {
        $nDigits = strlen((string)$value);
        $return = '';
        if($nDigits >= 4) {
            if($nDigits >= 8) {
                if($nDigits >= 10) {
                    if($nDigits >= 13) {
                        $return =  ceil(($value/1000000000000));
                    } else
                        $return =  ceil(($value/1000000000));
                } else
                    $return = ceil(($value/1000000));
            } else
                $return = ceil(($value/1000));
        } else
            $return = $value;

        return $return;
    }

    private function getErrorMargin($value) {
        $nDigits = strlen((string)$value);
        if($nDigits >= 4) {
            if($nDigits >= 8) {
                if($nDigits >= 10) {
                    if($nDigits >= 13) {
                        return 1000000000000;
                    } else
                        return 1000000000;
                } else
                    return 1000000;
            } else
                return 1000;
        } else
            return 1;
    }

    public function changeCurrentChoice($filterName,$choice) {
        $this->filters[$filterName]['currentChoice'] = $choice;
    }

    public function addFilterGroup($filterGroupArray) {
        array_push($this->filterGroups,$filterGroupArray);
    }

    public function getFiltersSelectedChoices($filtersArray) {
        $values = array();
        foreach($filtersArray as $filterName) {
            $values[$filterName] = $this->filters[$filterName]['currentChoice'];

            //If select one get only the first one
            if($this->filters[$filterName]['type'] == 'selectOne')
                $values[$filterName] = $values[$filterName][0];
        }

        return $values;
    }

    public function getFilterChoices() {
        $options = array();
        foreach($this->filters as $filterName => $value) {
            if($value['type'] == 'selectMultiple' || $value['type'] == 'selectOne')
                $options[$filterName] = $value['choices'];
        }

        return $options;
    }

    public function buildFilterGroups($filterGroups) {
        foreach($filterGroups as $filterGroup => $options) {
            foreach($options as $optionKey => $option) {
                $this->filterGroups[$filterGroup][$optionKey] = $option;
            }
        }
    }
}
