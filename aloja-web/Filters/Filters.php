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
         * types: inputText, inputNumber[{le,ge}], inputDate[{le,ge}], selectOne, selectMultiple
         * default: null (any), array(values)
         * table: associated DB table name
         *
         * Very custom filters such as advanced filters not in this array
         *
         */
        $this->filters = array(
            'bench' => array('table' => 'execs', 'default' => array('terasort','wordcount'), 'type' => 'selectMultiple', 'label' => 'Benchmarks:'),
            'bench_type' => array('table' => 'execs', 'default' => array('HiBench','HiBench3','HiBench3HDI'), 'type' => 'selectMultiple', 'label' => 'Benchmark type:'),
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
        );

        $this->aliasesTables = array('execs' => '','clusters' => '');

        //To render groups on template. Rows are of 2 columns each. emptySpace puts an empty element on the rendered row
        $this->filterGroups = array('basic' => array('money','emptySpace','bench','id_cluster','net','disk'),
            'hardware' => array('datanodes','bench_type','vm_size','vm_cores','vm_RAM','type','provider','vm_OS'),
            'hadoop' => array('maps','comp','replication','blk_size','iosf','iofilebuf','hadoop_version'));
    }

    public function getWhereClause($aliasesToReplace) {
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
        $choices['bench'] = $this->dbConnection->get_rows("SELECT DISTINCT bench FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
        $choices['net'] = $this->dbConnection->get_rows("SELECT DISTINCT net FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY net ASC");
        $choices['disk'] = $this->dbConnection->get_rows("SELECT DISTINCT disk FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY disk ASC");
        $choices['blk_size'] = $this->dbConnection->get_rows("SELECT DISTINCT blk_size FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY blk_size ASC");
        $choices['comp'] = $this->dbConnection->get_rows("SELECT DISTINCT comp FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY comp ASC");
        $choices['id_cluster'] = $this->dbConnection->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name  from execs e join clusters c using (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
        $choices['maps'] = $this->dbConnection->get_rows("SELECT DISTINCT maps FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY maps ASC");
        $choices['replication'] = $this->dbConnection->get_rows("SELECT DISTINCT replication FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY replication ASC");
        $choices['iosf'] = $this->dbConnection->get_rows("SELECT DISTINCT iosf FROM execs e WHERE 1 AND valid = 1 AND filter = 0 AND iosf IS NOT NULL ".DBUtils::getFilterExecs()." ORDER BY iosf ASC");
        $choices['iofilebuf'] = $this->dbConnection->get_rows("SELECT DISTINCT iofilebuf FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iofilebuf ASC");
        $choices['datanodes'] = $this->dbConnection->get_rows("SELECT DISTINCT datanodes FROM execs e JOIN clusters USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datanodes ASC");
        $choices['bench_type'] = $this->dbConnection->get_rows("SELECT DISTINCT bench_type FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench_type ASC");
        $choices['vm_size'] = $this->dbConnection->get_rows("SELECT DISTINCT vm_size FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_size ASC");
        $choices['vm_cores'] = $this->dbConnection->get_rows("SELECT DISTINCT vm_cores FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_cores ASC");
        $choices['vm_RAM'] = $this->dbConnection->get_rows("SELECT DISTINCT vm_RAM FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_RAM ASC");
        $choices['hadoop_version'] = $this->dbConnection->get_rows("SELECT DISTINCT hadoop_version FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY hadoop_version ASC");
        $choices['type'] = $this->dbConnection->get_rows("SELECT DISTINCT type FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY type ASC");
        $choices['provider'] = $this->dbConnection->get_rows("SELECT DISTINCT provider FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY provider DESC;");
        $choices['vm_OS'] = $this->dbConnection->get_rows("SELECT DISTINCT vm_OS FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_OS DESC;");
        foreach($choices as $key => $value) {
            $this->filters[$key]['choices'] = $value;
        }
    }

    private function parseFilters() {
        foreach($this->filters as $filterName => $definition) {
            $DBreference = ($definition['table'] != 'mixed') ? "${definition['table']}Alias." : '';
            $DBreference .= (isset($definition['field'])) ? $definition['field'] : $filterName;

            $values = null;
            if(isset($_GET[$filterName])) {
                $values = $_GET[$filterName];
                array_walk($values, function(&$item) {
                    $item=str_replace('%2F','/',$item);
                });
            } else if($definition['default'] != null) {
                $values = $definition['default'];
            }
            $this->filters[$filterName]['currentChoice'] = $values;

            if($values != null) {
                $type = $definition['type'];
                if($type == "selectOne" || $type == "selectMultiple") {
                    array_walk($values,function(&$item) {
                        $item = "'$item'";
                    });
                    $this->whereClause .= " AND $DBreference IN (". join(',', $values) .")";
                } else if($type == "inputText" || $type == "inputNumber") {
                    $this->whereClause .= " AND $DBreference = $values";
                } else if($type == "inputNumberle") {
                    $this->whereClause .= " AND $DBreference <= $values";
                } else if($type == "inputNumberge") {
                    $this->whereClause .= " AND $DBreference >= $values";
                } else if($type == "inputDatele") {
                    $this->whereClause .= " AND $DBreference <= '$values'";
                } else if($type == "inputDatege") {
                    $this->whereClause .= " AND $DBreference >= '$values'";
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

        } else if(!isset($_GET['allunchecked']) || $_GET['allunchecked'] == '') {
            $_GET['execsfilters'][] = 'valid';
            $_GET['execsfilters'][] = 'filter';

            $this->whereClause .= ' AND '.$alias.'.valid = 1 AND '.$alias.'.filter = 0 ';
        }

        if(!$includePrepares)
            $this->whereClause .= "AND $alias.bench not like 'prep_%' AND $alias.bench_type not like 'HDI-prep%'";

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
        $this->parseAdvancedFilters();
        $this->generateFilterChoices();

        //Workaround to know if all advanced options selected or not, due unable to know in a "beauty" way with GET parameters
        $this->additionalFilters['allunchecked'] = (isset($_GET['allunchecked'])) ? $_GET['allunchecked']  : '';
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
          SELECT * FROM filter_presets WHERE selected_tool = '$screenName' ORDER BY short_name DESC");

    }

    private function initDefaultPreset($db, $screen) {
        $presets = $this->dbConnection->get_rows("SELECT * FROM filter_presets WHERE default_preset = 1 AND selected_tool = '$screen'");
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
}
