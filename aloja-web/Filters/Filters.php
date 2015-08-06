<?php

namespace alojaweb\Filters;

use \alojaweb\inc\DBUtils;
use \alojaweb\inc\Utils;

class Filters
{
    private $whereClause;

    private $selectedFilters;

    private $filtersNamesOptions;

    private $aliasesTables;

    public function __construct() {
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
        $this->filtersNamesOptions = array('money' => array('table' => 'execs', 'default' => null, 'type' => 'inputNumber'),
            'bench' => array('table' => 'execs', 'default' => array('terasort','wordcount','sort'), 'type' => 'selectMultiple'),
            'bench_type' => array('table' => 'execs', 'default' => array('HiBench','HiBench3','HiBench3HDI'), 'type' => 'selectMultiple'),
            'net' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'disk' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'blk_size' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'comp' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'id_cluster' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'maps' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'replication' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'iosf' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'iofilebuf' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'provider' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'vm_OS' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'datanodes' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'vm_size' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'vm_cores' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'vm_RAM' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'type' => array('table' => 'clusters', 'default' => null, 'type' => 'selectMultiple'),
            'hadoop_version' => array('table' => 'execs', 'default' => null, 'type' => 'selectMultiple'),
            'minexetime' => array('table' => 'execs', 'field' => 'exe_time', 'default' => null, 'type' => 'inputNumberge'),
            'maxexetime' => array('table' => 'execs', 'field' => 'exe_time', 'default' => null, 'type' => 'inputNumberle'),
            'datefrom' => array('table' => 'execs', 'default' => null, 'type' => 'inputDatege'),
            'dateto' => array('table' => 'execs', 'default' => null, 'type' => 'inputDatele'));

        $this->aliasesTables = array('execs' => '','clusters' => '');
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

    public function getSelectedFilters() {
        return $this->selectedFilters;
    }

    public function getFilterOptions(\alojaweb\inc\DBUtils $dbUtils) {
        $options['bench'] = $dbUtils->get_rows("SELECT DISTINCT bench FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
        $options['net'] = $dbUtils->get_rows("SELECT DISTINCT net FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY net ASC");
        $options['disk'] = $dbUtils->get_rows("SELECT DISTINCT disk FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY disk ASC");
        $options['blk_size'] = $dbUtils->get_rows("SELECT DISTINCT blk_size FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY blk_size ASC");
        $options['comp'] = $dbUtils->get_rows("SELECT DISTINCT comp FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY comp ASC");
        $options['id_cluster'] = $dbUtils->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,2,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name from execs e join clusters c using (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
        $options['maps'] = $dbUtils->get_rows("SELECT DISTINCT maps FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY maps ASC");
        $options['replication'] = $dbUtils->get_rows("SELECT DISTINCT replication FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY replication ASC");
        $options['iosf'] = $dbUtils->get_rows("SELECT DISTINCT iosf FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iosf ASC");
        $options['iofilebuf'] = $dbUtils->get_rows("SELECT DISTINCT iofilebuf FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iofilebuf ASC");
        $options['datanodes'] = $dbUtils->get_rows("SELECT DISTINCT datanodes FROM execs e JOIN clusters USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datanodes ASC");
        $options['benchtype'] = $dbUtils->get_rows("SELECT DISTINCT bench_type FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench_type ASC");
        $options['vm_size'] = $dbUtils->get_rows("SELECT DISTINCT vm_size FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_size ASC");
        $options['vm_cores'] = $dbUtils->get_rows("SELECT DISTINCT vm_cores FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_cores ASC");
        $options['vm_ram'] = $dbUtils->get_rows("SELECT DISTINCT vm_RAM FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_RAM ASC");
        $options['hadoop_version'] = $dbUtils->get_rows("SELECT DISTINCT hadoop_version FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY hadoop_version ASC");
        $options['type'] = $dbUtils->get_rows("SELECT DISTINCT type FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY type ASC");
        $options['presets'] = $dbUtils->get_rows("SELECT * FROM filter_presets ORDER BY short_name DESC");
        $options['provider'] = $dbUtils->get_rows("SELECT DISTINCT provider FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY provider DESC;");
        $options['vm_OS'] = $dbUtils->get_rows("SELECT DISTINCT vm_OS FROM execs e JOIN clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_OS DESC;");
        return $options;
    }

    private function parseFilters() {
        foreach($this->filtersNamesOptions as $filterName => $definition) {
            $DBreference = "${definition['table']}Alias.";
            $DBreference .= (isset($definition['field'])) ? $definition['field'] : $filterName;

            $values = null;
            if(isset($_GET[$filterName])) {
                $values = $_GET[$filterName];
            } else if($definition['default'] != null) {
                $values = $definition['default'];
            }
            $this->selectedFilters[$filterName] = $values;


            if($values != null) {
                $type = $definition['type'];
                if($type == "selectOne" || $type == "selectMultiple") {
                    array_walk($values,function(&$item) {
                        $item = "'$item'";
                    });
                    $this->whereClause .= " AND $DBreference IN (". join(',', $values) .")";
                } else if($type == "inputText" || $type == "inputNumber") {
                    $this->whereClause .= " AND $DBreference = $values";
                } else if($type == "inputDatele" || $type == "inputNumberle") {
                    $this->whereClause .= " AND $DBreference <= $values";
                } else if($type == "inputDatege" || $type == "inputNumberge") {
                    $this->whereClause .= " AND $DBreference >= $values";
                }
            }
        }
    }

    private function parseAdvancedFilters() {
        $alias = 'execsAlias';
        $includePrepares = false;
        if(isset($_GET['filters'])) {
            $filters = $_GET['filters'];
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

            $this->whereClause .= (in_array("filters",$filters)) ? ' AND '.$alias.'.filter = 0 ' : '';

        } else if(!isset($_GET['allunchecked']) || $_GET['allunchecked'] == '') {
            $_GET['filters'][] = 'valid';
            $_GET['filters'][] = 'filters';

            $this->whereClause .= ' AND '.$alias.'.valid = 1 AND '.$alias.'.filter = 0 ';
        }

        if(!$includePrepares)
            $this->whereClause .= "AND $alias.bench not like 'prep_%' AND $alias.bench_type not like 'HDI-prep%'";

        $this->selectedFilters['filters'] = (isset($_GET['filters'])) ? $_GET['filters'] : "";
    }

    public function getFilters(\alojaweb\inc\DBUtils $dbConnection, $screenName, $customDefaultValues) {

        $this->readPresets($dbConnection,$screenName);

        //Override with custom default values
        foreach($this->filtersNamesOptions as $index => &$options) {
            if(array_key_exists($index,$customDefaultValues)) {
                $options = $customDefaultValues[$index];
            }
        }

        $this->parseFilters();
        $this->parseAdvancedFilters();

        //Workaround to know if all advanced options selected or not, due unable to know in a "beauty" way with GET parameters
        $this->selectedFilters['allunchecked'] = (isset($_GET['allunchecked'])) ? $_GET['allunchecked']  : '';
    }

    private function readPresets($dbConnection, $screenName) {
        $preset = null;
        if(sizeof($_GET) <= 1)
        $this->selectedFilters['preset'] = $this->initDefaultPreset($dbConnection, $screenName);
        $this->selectedFilters['selPreset'] = (isset($_GET['presets'])) ? $_GET['presets'] : "none";
    }

    private function initDefaultPreset($db, $screen) {
        $presets = $db->get_rows("SELECT * FROM filter_presets WHERE default_preset = 1 AND selected_tool = '$screen'");
        $return = null;
        if(count($presets)>=1) {
            $url = $presets[0]['URL'];
            $return = $url;
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

        return $return;
    }
}
