<?php

namespace alojaweb\Filters;

use \alojaweb\inc\DBUtils;
use \alojaweb\inc\Utils;

class Filters
{
    private $whereClause;

    private $selectedFilters;

    public function getWhereClause($execsAlias = "", $clustersAlias = "") {
        $whereClause = $this->whereClause;
        $execsAlias = ($execsAlias != "") ? "$execsAlias." : "";
        $clustersAlias = ($clustersAlias != "") ? "$clustersAlias." : "";
        $whereClause = str_replace('execsAlias.',$execsAlias,$whereClause);
        $whereClause = str_replace('clustersAlias.',$clustersAlias,$whereClause);
        return $whereClause;
    }

    public function getSelectedFilters() {
        return $this->selectedFilters;
    }

    public function getFilterOptions(\alojaweb\inc\DBUtils $dbUtils) {
        $options['benchs'] = $dbUtils->get_rows("SELECT DISTINCT bench FROM execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
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

    public function getFilters(\alojaweb\inc\DBUtils $dbConnection, $screenName) {

        $preset = null;
        if(sizeof($_GET) <= 1)
            $preset = Utils::initDefaultPreset($dbConnection, $screenName);
        $selPreset = (isset($_GET['presets'])) ? $_GET['presets'] : "none";

        $money = $this->readFilter('money','execs',$filtersWhereClause, false);
        $benchs = $this->readFilter('benchs','execs',$filtersWhereClause, true);
        $benchtype = $this->readFilter ( 'bench_types','execs', $filtersWhereClause, true );
        $nets = $this->readFilter('nets','execs',$filtersWhereClause, false);
        $disks = $this->readFilter('disks','execs',$filtersWhereClause, false);
        $blk_sizes = $this->readFilter('blk_sizes','execs',$filtersWhereClause, false);
        $comps = $this->readFilter('comps','execs',$filtersWhereClause, false);
        $id_clusters = $this->readFilter('id_clusters','execs',$filtersWhereClause, false);
        $mapss = $this->readFilter('mapss','execs',$filtersWhereClause, false);
        $replications = $this->readFilter('replications','execs',$filtersWhereClause, false);
        $iosfs = $this->readFilter('iosfs','execs',$filtersWhereClause, false);
        $iofilebufs = $this->readFilter('iofilebufs','execs',$filtersWhereClause, false);
        $provider = $this->readFilter ( 'providers','clusters', $filtersWhereClause, false );
        $vm_OS = $this->readFilter ( 'vm_OSs','clusters', $filtersWhereClause, false );
        $datanodes = $this->readFilter ( 'datanodess','clusters', $filtersWhereClause, false );
        $vm_sizes = $this->readFilter ( 'vm_sizes','clusters', $filtersWhereClause, false );
        $vm_coress = $this->readFilter ( 'vm_coress','clusters', $filtersWhereClause, false );
        $vm_RAMs = $this->readFilter ( 'vm_RAMs','clusters', $filtersWhereClause, false );
        $types = $this->readFilter ( 'types','clusters', $filtersWhereClause, false );
        $hadoop_versions = $this->readFilter ( 'hadoop_versions','execs', $filtersWhereClause, false );
        $filters = $this->readFilter ( 'filters','execs', $filtersWhereClause, false );
        $minexetime = $this->readFilter ( 'minexetime','execs', $filtersWhereClause, false);
        $maxexetime = $this->readFilter ( 'maxexetime','execs', $filtersWhereClause, false);
        $datefrom = $this->readFilter('datefrom','execs',$filtersWhereClause, false);
        $dateto	= $this->readFilter('dateto','execs',$filtersWhereClause, false);
        $allunchecked = (isset($_GET['allunchecked'])) ? $_GET['allunchecked']  : '';

        $selFilters = array(
            'benchs' => $benchs,
            'nets' => $nets,
            'disks' => $disks,
            'blk_sizes' => $blk_sizes,
            'comps' => $comps,
            'id_clusters' => $id_clusters,
            'mapss' => $mapss,
            'replications' => $replications,
            'iosfs' => $iosfs,
            'iofilebufs' => $iofilebufs,
            'money' => $money,
            'datanodess' => $datanodes,
            'bench_types' => $benchtype,
            'vm_sizes' => $vm_sizes,
            'vm_coress' => $vm_coress,
            'vm_RAMs' => $vm_RAMs,
            'vm_OS' => $vm_OS,
            'hadoop_versions' => $hadoop_versions,
            'types' => $types,
            'providers' => $provider,
            'filters' => $filters,
            'minexetime' => $minexetime,
            'maxexetime' => $maxexetime,
            'datefrom' => $datefrom,
            'dateto' => $dateto,
            'allunchecked' => $allunchecked,
            'preset' => $preset,
            'selPreset' => $selPreset);

        $this->whereClause = $filtersWhereClause;
        $this->selectedFilters = $selFilters;
    }

    private function readFilter($filterName, $tableName, &$whereClause, $setDefaultValues = true)
    {
        $alias = "${tableName}Alias";
        if($filterName == 'money' && isset($_GET['money'])) {
            $money = $_GET['money'];
            if($money != '') {
                $whereClause .= ' AND ('.$alias.'.exe_time/3600)*('.$alias.'.cost_hour) <= '.$_GET['money'];
            }
            return $_GET['money'];
        }

        if($filterName == 'datefrom' && isset($_GET['datefrom'])) {
            $datefrom = $_GET['datefrom'];
            if($datefrom != '') {
                $whereClause .= " AND $alias.start_time >= '$datefrom'";
            }
            return $datefrom;
        } else if($filterName == 'datefrom')
            return "";

        if($filterName == 'dateto' && isset($_GET['dateto'])) {
            $dateto = $_GET['dateto'];
            if($dateto != '') {
                $whereClause .= " AND $alias.end_time <= '$dateto'";
            }
            return $dateto;
        } else if($filterName == 'dateto')
            return "";

        //Advanced filters parsing
        if($filterName == "filters") {
            $includePrepares = false;
            if(isset($_GET['filters'])) {
                $filters = $_GET['filters'];
                if(in_array("valid",$filters))
                    $whereClause .= ' AND '.$alias.'.valid = 1 ';
                if(in_array("prepares",$filters))
                    $includePrepares = true;
                if(in_array("perfdetails",$filters))
                    $whereClause .= ' AND '.$alias.'.perf_details = 1 ';

                if(in_array("outliers", $filters)) {
                    if(in_array("warnings", $filters))
                        $whereClause .= " AND $alias.outlier IN (0,1,2) ";
                    else
                        $whereClause .= " AND $alias.outlier IN (0,1) ";
                }

                $whereClause .= (in_array("filters",$filters)) ? ' AND '.$alias.'.filter = 0 ' : '';


            } else if(!isset($_GET['allunchecked']) || $_GET['allunchecked'] == '') {
                $_GET['filters'][] = 'valid';
                $_GET['filters'][] = 'filters';

                $whereClause .= ' AND '.$alias.'.valid = 1 AND '.$alias.'.filter = 0 ';
            }

            if(!$includePrepares)
                $whereClause .= "AND $alias.bench not like 'prep_%' AND $alias.bench_type not like 'HDI-prep%'";

            if(isset($_GET['filters']))
                return $_GET['filters'];
            else
                return "";
        }

        if($filterName == "minexetime") {
            $minexetime = (isset($_GET["minexetime"])) ? $_GET["minexetime"] : 50;

            if($minexetime != null)
                $whereClause .= " AND $alias.exe_time >= $minexetime ";

            return $minexetime;
        }

        if($filterName == "maxexetime") {
            if(isset($_GET["maxexetime"])) {
                $maxexetime = $_GET["maxexetime"];

                if($maxexetime != null)
                    $whereClause .= " AND $alias.exe_time <= $maxexetime ";

                return $maxexetime;
            } else
                return "";
        }

        //General filters
        if (isset($_GET[$filterName])) {
            $items = $_GET[$filterName];
            $items = Utils::delete_none($items);
        } else if($setDefaultValues) {
            if ($filterName == 'benchs') {
                $items = array('terasort', 'wordcount', 'sort');
            } elseif ($filterName == 'nets') {
                $items = array();
            } elseif ($filterName == 'bench_types') {
                $items = array('HiBench','HiBench3','HiBench3HDI');
            } else {
                $items = array();
            }
        } else
            $items = array();

        if ($items) {
            $tableItemName = substr($filterName, 0, -1);  //remove trailing 's'

            $whereClause .=
                ' AND '.
                $alias.'.'.$tableItemName.
                ' IN ("'.join('","', $items).'")';
        }

        return $items;
    }
}
