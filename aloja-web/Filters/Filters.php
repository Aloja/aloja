<?php

namespace alojaweb\Filters;

use \alojaweb\inc\DBUtils;
use \alojaweb\inc\Utils;

class Filters
{
    private $whereClause;

    private $selectedFilters;

    public function getWhereClause() {
        return $this->whereClause;
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

        $money = $this->readFilter('money',$filtersWhereClause, false);
        $benchs = $this->readFilter('benchs',$filtersWhereClause, true);
        $benchtype = $this->readFilter ( 'bench_types', $filtersWhereClause, true );
        $nets = $this->readFilter('nets',$filtersWhereClause, false);
        $disks = $this->readFilter('disks',$filtersWhereClause, false);
        $blk_sizes = $this->readFilter('blk_sizes',$filtersWhereClause, false);
        $comps = $this->readFilter('comps',$filtersWhereClause, false);
        $id_clusters = $this->readFilter('id_clusters',$filtersWhereClause, false);
        $mapss = $this->readFilter('mapss',$filtersWhereClause, false);
        $replications = $this->readFilter('replications',$filtersWhereClause, false);
        $iosfs = $this->readFilter('iosfs',$filtersWhereClause, false);
        $iofilebufs = $this->readFilter('iofilebufs',$filtersWhereClause, false);
        $provider = $this->readFilter ( 'providers', $filtersWhereClause, false );
        $vm_OS = $this->readFilter ( 'vm_OSs', $filtersWhereClause, false );
        $datanodes = $this->readFilter ( 'datanodess', $filtersWhereClause, false );
        $vm_sizes = $this->readFilter ( 'vm_sizes', $filtersWhereClause, false );
        $vm_coress = $this->readFilter ( 'vm_coress', $filtersWhereClause, false );
        $vm_RAMs = $this->readFilter ( 'vm_RAMs', $filtersWhereClause, false );
        $types = $this->readFilter ( 'types', $filtersWhereClause, false );
        $hadoop_versions = $this->readFilter ( 'hadoop_versions', $filtersWhereClause, false );
        $filters = $this->readFilter ( 'filters', $filtersWhereClause, false );
        $minexetime = $this->readFilter ( 'minexetime', $filtersWhereClause, false);
        $maxexetime = $this->readFilter ( 'maxexetime', $filtersWhereClause, false);
        $datefrom = $this->readFilter('datefrom',$filtersWhereClause, false);
        $dateto	= $this->readFilter('dateto',$filtersWhereClause, false);
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
            'selPreset' => $selPreset,
            'options' => $this->getFilterOptions($dbConnection));

        $this->whereClause = $filtersWhereClause;
        $this->selectedFilters = $selFilters;
    }

    private function readFilter($item_name, &$where_configs, $setDefaultValues = true)
    {
        if($item_name == 'money' && isset($_GET['money'])) {
            $money = $_GET['money'];
            if($money != '') {
                $where_configs .= ' AND (exe_time/3600)*(cost_hour) <= '.$_GET['money'];
            }
            return $_GET['money'];
        }

        if($item_name == 'datefrom' && isset($_GET['datefrom'])) {
            $datefrom = $_GET['datefrom'];
            if($datefrom != '') {
                $where_configs .= " AND start_time >= '$datefrom'";
            }
            return $datefrom;
        } else if($item_name == 'datefrom')
            return "";

        if($item_name == 'dateto' && isset($_GET['dateto'])) {
            $dateto = $_GET['dateto'];
            if($dateto != '') {
                $where_configs .= " AND end_time <= '$dateto'";
            }
            return $dateto;
        } else if($item_name == 'dateto')
            return "";

        if($item_name == "filters") {
            $includePrepares = false;
            if(isset($_GET['filters'])) {
                $filters = $_GET['filters'];
                if(in_array("valid",$filters))
                    $where_configs .= ' AND valid = 1 ';
                if(in_array("prepares",$filters))
                    $includePrepares = true;
                if(in_array("perfdetails",$filters))
                    $where_configs .= ' AND perf_details = 1 ';

                if(in_array("outliers", $filters)) {
                    if(in_array("warnings", $filters))
                        $where_configs .= " AND outlier IN (0,1,2) ";
                    else
                        $where_configs .= " AND outlier IN (0,1) ";
                }

                $where_configs .= (in_array("filters",$filters)) ? ' AND filter = 0 ' : '';


            } else if(!isset($_GET['allunchecked']) || $_GET['allunchecked'] == '') {
                $_GET['filters'][] = 'valid';
                $_GET['filters'][] = 'filters';

                $where_configs .= ' AND valid = 1 AND filter = 0 ';
            }

            if(!$includePrepares)
                $where_configs .= "AND bench not like 'prep_%' AND bench_type not like 'HDI-prep%'";

            if(isset($_GET['filters']))
                return $_GET['filters'];
            else
                return "";
        }

        if($item_name == "minexetime") {
            $minexetime = (isset($_GET["minexetime"])) ? $_GET["minexetime"] : 50;

            if($minexetime != null)
                $where_configs .= " AND exe_time >= $minexetime ";

            return $minexetime;
        }

        if($item_name == "maxexetime") {
            if(isset($_GET["maxexetime"])) {
                $maxexetime = $_GET["maxexetime"];

                if($maxexetime != null)
                    $where_configs .= " AND exe_time <= $maxexetime ";

                return $maxexetime;
            } else
                return "";
        }

        if (isset($_GET[$item_name])) {
            $items = $_GET[$item_name];
            $items = Utils::delete_none($items);
        } else if($setDefaultValues) {
            if ($item_name == 'benchs') {
                $items = array('terasort', 'wordcount', 'sort');
            } elseif ($item_name == 'nets') {
                $items = array();
            } elseif ($item_name == 'bench_types') {
                $items = array('HiBench','HiBench3','HiBench3HDI');
            } else {
                $items = array();
            }
        } else
            $items = array();

        if ($items) {
            $single_item_name = substr($item_name, 0, -1);  //remove trailing 's'

            $where_configs .=
                ' AND '.
                $single_item_name.
                ' IN ("'.join('","', $items).'")';
        }

        return $items;
    }
}
