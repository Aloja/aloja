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
         * types: inputText, inputNumber[{le,ge}], inputDate[{le,ge}], selectOne, selectMultiple, hidden
         * default: null (any), array(values)
         * table: associated DB table name
         * parseFunction: function to parse special filter, for filters that need a lot of customization
         *
         * Very custom filters such as advanced filters not in this array
         *
         */
        $this->filters = array(
            'bench' => array('table' => 'execs', 'default' => array('terasort','wordcount'), 'type' => 'selectMultiple', 'label' => 'Benchmarks:'),
            'datasize' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple', 'label' => 'Datasize: ',
                'beautifier' => function($value) {
                  if($value == null)
                      return 'Default';
                  else
                      return $value;
                }),
            'bench_type' => array('table' => 'execs', 'default' => array('HiBench','HiBench3','HiBench3HDI'), 'type' => 'selectMultiple', 'label' => 'Bench suite:'),
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
                    //Not nice, but saves multiple queries to DB
                    $clusters = $this->filters['id_cluster']['choices'];
                    foreach($clusters as $cluster) {
                        if($cluster['id_cluster'] == $value)
                            return $cluster['name'];
                    }
                },
                'queryChoices' => function() {
                    return "select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name  from aloja2.execs e join aloja2.clusters c using (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC";
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
            'execsfilters' => array('table' => 'execs', 'field' => array('valid','filter','perf_details'), 'default' => array('valid','filter'),
                'parseFunction' => 'parseAdvancedFilters', 'labels' => array('valid' => 'Only valid execs',
                    'filter' => 'Filter', 'prepares' => 'Include prepares', 'perfdetails' => 'Only execs with perf details'))
        );

        $this->aliasesTables = array('execs' => '','clusters' => '');

        //To render groups on template. Rows are of 2 columns each. emptySpace puts an empty element on the rendered row
        $this->filterGroups = array('basic' => array('money','bench','datasize','bench_type','id_cluster','net','disk'),
            'hardware' => array('datanodes','vm_size','vm_cores','vm_RAM','type','provider','vm_OS'),
            'hadoop' => array('maps','comp','replication','blk_size','iosf','iofilebuf','hadoop_version'));
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
                if (isset($definition['queryChoices'])) {
                    $queryChoices = $definition['queryChoices']();
                } else {
                    $fromClause = "aloja2.execs";
                    if ($definition['table'] == 'clusters') {
                        $fromClause .= ' JOIN clusters USING (id_cluster) ';
                    }
                    $field = isset($definition['field']) ? $definition['field'] : $filterName;
                    $queryChoices = "SELECT DISTINCT $field FROM $fromClause WHERE 1 AND valid = 1 AND filter = 0 " . DBUtils::getFilterExecs() . " ORDER BY $field ASC";
                }
                $this->filters[$filterName]['choices'] = $this->dbConnection->get_rows($queryChoices);
            }
        }
    }

    private function parseFilters() {
        foreach($this->filters as $filterName => $definition) {
            if(isset($definition['parseFunction'])) {
                $this->$definition['parseFunction']();
            } else {
                $DBreference = ($definition['table'] != 'mixed') ? "${definition['table']}Alias." : '';
                $DBreference .= (isset($definition['field'])) ? $definition['field'] : $filterName;

                $values = null;
                if (isset($_GET[$filterName])) {
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
                array_push($this->filterGroups['basic'],$index);
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
        foreach($benchsDatasize as $row) {
            $dataBenchs[$row['bench_type']][$row['bench']][] = $row['datasize'];
        }

        $this->additionalFilters['datasizesInfo'] = json_encode($dataBenchs);
    }
}
