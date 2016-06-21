<?php

namespace alojaweb\inc;

use alojaweb\Container;

class Utils
{
    public function __construct()
    {

    }

    public static function delete_none($array)
    {
        if (($key = array_search('None', $array)) !== false) {
            unset ($array[$key]);
        }

        return $array;
    }

    public static function getConfig($items) {
        $aliases = array('maps' => 'e', 'comp' => 'e', 'id_cluster' => 'c',
            'net' => 'e', 'disk' => 'e','replication' => 'e',
            'iofilebuf' => 'e', 'blk_size' => 'e', 'iosf' => 'e', 'vm_size' => 'c',
            'vm_cores' => 'c', 'vm_RAM' => 'c', 'vm_OS' => 'c', 'datanodes' => 'c', 'hadoop_version' => 'e',
            'type' => 'c', 'datasize' => 'e', 'scale_factor' => 'e', 'run_num' => 'e');

    	$concatConfig = "";
    	foreach($items as $item) {
	    	if ($item != 'bench') {
	    		if ($concatConfig) $concatConfig .= ",'_',";
	    	
	    		if ($item == 'id_cluster') {
	    			//$concatConfig .= "CONCAT_WS(',',c.provider,c.vm_size,CONCAT(c.datanodes,'nodes'))";
                    $concatConfig .= "c.vm_size";
	    		} elseif ($item == 'iofilebuf') {
	    			$confPrefix = 'I';
	    		} elseif ($item == 'vm_OS') {
                    $confPrefix = 'OS';
                } elseif ($item == 'datasize') {
                    $confPrefix = 'S';
                } elseif ($item == 'run_num') {
                    $confPrefix = 'Run';
                } elseif ($item == 'maps') {
                    $confPrefix = 'AUs';
                } elseif ($item == 'replication') {
                    $confPrefix = 'Dists';
                } else {
	    			$confPrefix = $item;
	    		}

                $prefixes = array ('maps', 'replication');

	    		//avoid alphanumeric fields
	    		if (!in_array($item, $prefixes) && $item != 'id_cluster' && !in_array($item, array('net', 'disk'))) {
                    $concatConfig .= "'" . $confPrefix . "', ${aliases[$item]}.$item";
                } else if (in_array($item, $prefixes)) {
                        $concatConfig .= "${aliases[$item]}.$item ,'$confPrefix'";
	    		} else if($item != 'id_cluster') {
	    			$concatConfig .= " ${aliases[$item]}.$item";
	    		}
	    	}
    	}
    	
    	return $concatConfig;
    }

    public static function generateJSONTable($csv, $show_in_result, $precision = null, $type = null)
    {
        $jsonData = array();

        $i = 0;
        foreach ($csv as $value_row) {
            $jsonRow = array();
            $jsonRow[] = $value_row['id_exec'];
            if(key_exists("cluster_name",$value_row))
           	 $clusterName = $value_row['cluster_name'];
            
            foreach (array_keys($show_in_result) as $key_name) {
                if ($precision !== null && is_numeric($value_row[$key_name])) {
                    $value_row[$key_name] = round($value_row[$key_name], $precision);
                }

                if (!$type) {
                	if ($key_name == 'bench') {
                        $jsonRow[] = $value_row[$key_name];
                    } elseif ($key_name == 'init_time') {
                        $jsonRow[] = date('YmdHis', strtotime($value_row['end_time']));
                    } elseif ($key_name == 'exe_time') {
                        $jsonRow[] = round($value_row['exe_time']);
                    } elseif ($key_name == 'files') {
                        $jsonRow[] = $value_row['exec'];
                    } elseif ($key_name == 'prv' || $key_name == 'counters') {
                        $jsonRow[] = $value_row['id_exec'];
                    } elseif ($key_name == 'version') {
                        $jsonRow[] = "1.0.3";
                    } elseif ($key_name == 'cost') {
                        $jsonRow[] = number_format($value_row['cost'], 2);
                    } elseif ($key_name == 'id_cluster') {
                        //if (strpos($value_row['exec'], '_az')) $jsonRow[] = 'Azure L';
                        //else $jsonRow[] = "Local 1";
                        $jsonRow[] = $value_row['cluster_name'];
                    } elseif (stripos($key_name, 'BYTES') !== false) {
                        $jsonRow[] = round(($value_row[$key_name])/(1024*1024));
                    } elseif ($key_name == 'FINISH_TIME') {
                        $jsonRow[] = date('YmdHis', round($value_row[$key_name]/1000));
                    } elseif ($key_name == 'comp') {
                    	$jsonRow[] = self::getCompressionName($value_row[$key_name]);
                    } else
                        $jsonRow[] = $value_row[$key_name];
                } else {
                    if ($key_name == 'JOBID') {
                        $jsonRow[] = $value_row[$key_name];
                    } elseif (stripos($key_name, 'BYTES') !== false) {
                        $jsonRow[] = round(($value_row[$key_name])/(1024*1024));
                    } elseif (stripos($key_name, 'TIME') !== false) {
                        $jsonRow[] = substr($value_row[$key_name], -8);
                    } elseif (strpos($key_name, 'JOBNAME') !== false) {
                        if (strlen($value_row[$key_name]) > 15)
                            $jsonRow[] = substr($value_row[$key_name], 0, 15).'.';
                        else
                            $jsonRow[] = $value_row[$key_name];
                    } else {
                        $jsonRow[] = $value_row[$key_name];
                    }

                }
            }
            $jsonData[] = $jsonRow;
            $i++;
        }
        return $jsonData;
        //return json_encode(array('aaData' => $jsonData));
    }

    public static function get_GET_intArray($param)
    {
        $paramArray = array();
        if (isset($_GET[$param])) {
            $paramArray = array_unique($_GET[$param]);
            foreach ($paramArray as $value) {
                $value = filter_var($value, FILTER_SANITIZE_NUMBER_INT);
            }
        }

        return $paramArray;
    }

    public static function get_GET_stringArray($param)
    {
        $paramArray = array();
        if (isset($_GET[$param])) {
            $paramArray = array_unique($_GET[$param]);
            foreach ($paramArray as &$value) {
                $value = filter_var($value, FILTER_SANITIZE_STRING);
            }
        }

        return $paramArray;
    }

    public static function get_GET_string($param)
    {
        if (isset($_GET[$param]))
            return filter_var($_GET[$param], FILTER_SANITIZE_STRING);
    }

    public static function get_GET_int($param)
    {
        if (isset($_GET[$param]))
            return filter_var($_GET[$param], FILTER_SANITIZE_NUMBER_INT);
    }

    public static function get_GET_float($param)
    {
        if (isset($_GET[$param]))
            return filter_var($_GET[$param], FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
    }

    public static function minimize_array($array)
    {
        foreach ($array as $key=>$value) {
            if (is_numeric($value))
                $array[$key] = round($value, 2);
        }

        return $array;
    }

    public static function minimize_exec_rows(array $rows, $stacked = false)
    {
        $minimized_rows = array();
        $max = null;
        $min = null;
        foreach ($rows as $key_row=>$row) {
            if (is_array($row)) {

                //if (is_numeric($row['id_exec'])) $id = $row['id_exec'];
                //else $id = $key_row;
                $id = $key_row;

                $row_sum = 0;
                foreach ($row as $key_field=>$field) {
                    if (is_numeric($field)) {
                        $field = round($field, 2);
                        if (!$stacked && $key_field != 'time') {
                            if (!$max || $field > $max) $max = $field;
                            if (!$min || $field < $min) $min = $field;
                        } else {
                            $row_sum += $field;
                        }
                    }
                    $minimized_rows[$id][$key_field] = $field;
                }
                if ($stacked) {
                    if (!$max || $row_sum > $max) $max = $row_sum;
                    if (!$min || $row_sum < $min) $min = $row_sum;
                }
            } else {
                throw new \Exception("Incorrect array format!");
            }
        }

        return array($minimized_rows, $max, $min);
    }

    public static function csv_to_array($filename='', $delimiter=',')
    {
        if(!file_exists($filename) || !is_readable($filename))

            return FALSE;

        $header = null;
        $data = array();
        if (($handle = fopen($filename, 'r')) !== FALSE) {
            while (($row = fgetcsv($handle, 1000, $delimiter)) !== FALSE) {
                if(!$header)
                    $header = $row;
                else
                    $data[] = array_combine($header, $row);
            }
            fclose($handle);
        }

        return $data;
    }

    public static function find_config($config, $csv)
    {
        $return = false;
        foreach ($csv as $value_row) {
            if ($value_row['exec'] == $config) {
                $value_row['print_name'] =
                "<strong>".$value_row['bench']."</strong> ".
                substr($value_row['exec'], 16, (strpos($value_row['exec'],'/')-16)).
                " {$value_row['exe_time']} secs.";
                $return = $value_row;
                break;
            }
        }

        return $return;
    }

    public static function generate_show($show_in_result, $csv, $offset)
    {
        reset($csv);
        $header = current($csv);

        $dont_show= array('job_name');

        $position = 0;
        foreach (array_keys($header) as $key_header) {
            if ($position > $offset && !in_array($key_header, $dont_show)) {

                $name = str_replace('_', ' ', $key_header);

                if (stripos($key_header, 'BYTES') !== false) {
                    $show_in_result[$key_header] = str_ireplace('BYTES', 'MB', $name);
                } else {
                    $show_in_result[$key_header] = $name;
                }
            }
            $position++;
        }

        return $show_in_result;
    }
    
    public static function getExecsOptions($db,$predictions,$where_configs = "")
    {
        $filter_execs = $where_configs ." ".DBUtils::getFilterExecs();

        $benchOptions = "SELECT DISTINCT e.bench FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$netOptions = "SELECT DISTINCT e.net FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$diskOptions = "SELECT DISTINCT e.disk FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$mapsOptions = "SELECT DISTINCT e.maps FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$compOptions = "SELECT DISTINCT e.comp FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$blk_sizeOptions = "SELECT DISTINCT e.blk_size FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$clusterOptions = "SELECT DISTINCT c.name FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE  e.valid = 1 AND e.filter = 0 $filter_execs";
    	$clusterNodes = "SELECT DISTINCT c.datanodes FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE e.valid = 1 AND e.filter = 0 $filter_execs";
    	$hadoopVersion = "SELECT DISTINCT e.hadoop_version FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
        $benchType = "SELECT DISTINCT e.bench_type FROM aloja2.execs e JOIN aloja2.clusters c USING(id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
    	$vmOS = "SELECT DISTINCT c.vm_OS FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";
        $execTypes = "SELECT DISTINCT e.exec_type FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) LEFT JOIN aloja_ml.predictions p USING (id_exec) WHERE 1 AND e.valid = 1 AND e.filter = 0 $filter_execs";

        $benchOptionsPred = "SELECT DISTINCT CONCAT('pred_',p.bench) FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $netOptionsPred = "SELECT DISTINCT p.net FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $diskOptionsPred = "SELECT DISTINCT p.disk FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $mapsOptionsPred = "SELECT DISTINCT p.maps FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $compOptionsPred = "SELECT DISTINCT p.comp FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $blk_sizeOptionsPred = "SELECT DISTINCT p.blk_size FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $clusterOptionsPred = "SELECT DISTINCT c.name FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE  p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $clusterNodesPred = "SELECT DISTINCT c.datanodes FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $hadoopVersionPred = "SELECT DISTINCT p.hadoop_version FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $benchTypePred = "SELECT DISTINCT p.bench_type FROM aloja_ml.predictions p JOIN aloja2.clusters c USING(id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $vmOSPred = "SELECT DISTINCT c.vm_OS FROM aloja_ml.predictions p JOIN aloja2.clusters c USING (id_cluster)  WHERE 1 AND p.valid = 1 AND p.filter = 0 ".str_replace("e.","p.",$filter_execs);
        $execTypesPred = $execTypes;

        if($predictions == 1) {
            $benchOptions = $db->get_rows($benchOptionsPred);
            $netOptions = $db->get_rows($netOptionsPred);
            $diskOptions = $db->get_rows($diskOptionsPred);
            $mapsOptions = $db->get_rows($mapsOptionsPred);
            $compOptions = $db->get_rows($compOptionsPred);
            $blk_sizeOptions = $db->get_rows($blk_sizeOptionsPred);
            $clusterOptions = $db->get_rows($clusterOptionsPred);
            $clusterNodes = $db->get_rows($clusterNodesPred);
            $hadoopVersion = $db->get_rows($hadoopVersionPred);
            $benchType = $db->get_rows($benchTypePred);
            $vmOS = $db->get_rows($vmOSPred);
            $execTypes = $db->get_rows($execTypesPred);
        } else if($predictions == 2) {
            $benchOptions = $db->get_rows("$benchOptions UNION $benchOptionsPred");
            $netOptions = $db->get_rows("$netOptions UNION $netOptionsPred");
            $diskOptions = $db->get_rows("$diskOptions UNION $diskOptionsPred");
            $mapsOptions = $db->get_rows("$mapsOptions UNION $mapsOptionsPred");
            $compOptions = $db->get_rows("$compOptions UNION $compOptionsPred");
            $blk_sizeOptions = $db->get_rows("$blk_sizeOptions UNION $blk_sizeOptionsPred");
            $clusterOptions = $db->get_rows("$clusterOptions UNION $clusterOptionsPred");
            $clusterNodes = $db->get_rows("$clusterNodes UNION $clusterNodesPred");
            $hadoopVersion = $db->get_rows("$hadoopVersion UNION $hadoopVersionPred");
            $benchType = $db->get_rows("$benchType UNION $benchTypePred");
            $vmOS = $db->get_rows("$vmOS UNION $vmOSPred");
            $execTypes = $db->get_rows("$execTypes UNION $execTypesPred");
        } else {
            $benchOptions = $db->get_rows($benchOptions);
            $netOptions = $db->get_rows($netOptions);
            $diskOptions = $db->get_rows($diskOptions);
            $mapsOptions = $db->get_rows($mapsOptions);
            $compOptions = $db->get_rows($compOptions);
            $blk_sizeOptions = $db->get_rows($blk_sizeOptions);
            $clusterOptions = $db->get_rows($clusterOptions);
            $clusterNodes = $db->get_rows($clusterNodes);
            $hadoopVersion = $db->get_rows($hadoopVersion);
            $benchType = $db->get_rows($benchType);
            $vmOS = $db->get_rows($vmOS);
            $execTypes = $db->get_rows($execTypes);
        }


        $discreteOptions = array();
    	$discreteOptions['bench'][] = 'All';
    	$discreteOptions['net'][] = 'All';
    	$discreteOptions['disk'][] = 'All';
    	$discreteOptions['maps'][] = 'All';
    	$discreteOptions['comp'][] = 'All';
    	$discreteOptions['blk_size'][] = 'All';
    	$discreteOptions['id_cluster'][] = 'All';
    	$discreteOptions['datanodes'][] = 'All';
    	$discreteOptions['hadoop_version'][] = 'All';
        $discreteOptions['bench_type'][] = 'All';
        $discreteOptions['vm_OS'][] = 'All';
        $discreteOptions['exec_type'][] = 'All';

        foreach($benchOptions as $option) {
    		$discreteOptions['bench'][] = array_shift($option);
    	}
    	foreach($netOptions as $option) {
    		$current = array_shift($option);
    		$current = ($current == "0") ? "HDI" : $current;
    		$discreteOptions['net'][] = $current;
    	}
    	foreach($diskOptions as $option) {
    		$current = array_shift($option);
    		$current = ($current == "0") ? "HDI" : $current;
    		$discreteOptions['disk'][] = $current;
    	}
    	foreach($mapsOptions as $option) {
    		$discreteOptions['maps'][] = array_shift($option);
    	}
    	foreach($compOptions as $option) {
    		$value = array_shift($option);
    		$discreteOptions['comp'][] = self::getCompressionName($value);
    	}
    	foreach($blk_sizeOptions as $option) {
    		$discreteOptions['blk_size'][] = array_shift($option);
    	}
    	foreach($clusterOptions as $option) {
            $discreteOptions['id_cluster'][] = array_shift($option);
    	}
    	foreach($clusterNodes as $option) {
    		$discreteOptions['datanodes'][] = array_shift($option);
    	}
    	foreach($hadoopVersion as $option) {
    		$discreteOptions['hadoop_version'][] = array_shift($option);
    	}
        foreach($benchType as $option) {
            $discreteOptions['bench_type'][] = array_shift($option);
        }
        foreach($vmOS as $option) {
            $discreteOptions['vm_OS'][] = array_shift($option);
        }
        foreach($execTypes as $option) {
            $discreteOptions['exec_type'][] = array_shift($option);
        }

    	return $discreteOptions;
    }
    
    public static function getCompressionName($compCode)
    {
    	$compName = '';
    	if($compCode == 0)
    		$compName = 'None';
    	elseif($compCode == 1)
    		$compName = 'ZLIB';
    	elseif($compCode == 2)
    		$compName = 'BZIP2';
    	else
    		$compName = 'Snappy';
    	
    	return $compName;
    }

    public static function getClusterName($clusterCode, $db)
    {
        $clusterName = $db->get_rows("SELECT CONCAT_WS('/',LPAD(id_cluster,3,0),vm_size,CONCAT(datanodes,'Dn')) as name FROM aloja2.clusters WHERE id_cluster=$clusterCode");

        return $clusterName[0]['name'];
    }
    
    public static function getNetworkName($netShort)
    {
    	$netName = '';
    	if($netShort == 'IB')
    		$netName = 'InfiniBand';
    	elseif($netShort == 'HDI')
    		$netName = 'HDInsight';
    	else
    		$netName = 'Ethernet';
    	
    	return $netName;
    }
    
    public static function getDisksName($diskShort)
    {
    	$disks = '';
    	if($diskShort == 'HDD')
    		$disks = 'SATA drive';
    	elseif($diskShort == 'SSD')
    		$disks = 'SSD drive';
    	elseif($diskShort == "HDI")
    		$disks = 'Azure Storage (remote)';
    	else if(preg_match("/^RL/",$diskShort))
    		$disks = substr($diskShort,2).' HDFS remote(s) /tmp  to local SATA disk';
    	else if(preg_match("/^RR/",$diskShort))
    		$disks = substr($diskShort,2).' Remote volumes(s)';
    	else if(preg_match("/^SS([0-9]+)/",$diskShort))
    		$disks = substr($diskShort,2).' SSD drives';
    	else if(preg_match("/^HS([0-9]+)/",$diskShort))
    		$disks = substr($diskShort,2).' HDFS in SATA /tmp to SSD';
        else if(preg_match("/^RS([0-9]+)/",$diskShort))
            $disks = substr($diskShort,2).' HDFS in Remote(s) /tmp to SSD';
    	else if(preg_match("/^HD/",$diskShort))
    		$disks = substr($diskShort,2).' SATA drives';
        else if($diskShort == 'SaaS')
            $disks = 'SaaS managed (unknown)';
        else
            $disks = 'N/A';

    	return $disks;
    }
    
    public static function getBeautyRam($ramAmount)
    {
    	return round($ramAmount,0)." GB";
    }
    
    public static function makeExecInfoBeauty(&$execInfo)
    {
    	if(array_key_exists('comp',$execInfo))
    		$execInfo['comp'] = self::getCompressionName($execInfo['comp']);
    	
    	if(array_key_exists('net',$execInfo))
    		$execInfo['net'] = self::getNetworkName($execInfo['net']);
    	
    	if(array_key_exists('disk',$execInfo))
    		$execInfo['disk'] = self::getDisksName($execInfo['disk']);
    }
    
    public static function changeParamOptions(&$paramOptions, $paramEval)
    {
    	if($paramEval == 'comp') {
    		foreach($paramOptions as &$option) {
    			$option['param'] = Utils::getCompressionName($option['param']);
    		}
    	}
    }
    
    public static function getParamevalUnit($paramEval)
    {
    	$unit = '';
    	if($paramEval == 'iofilebuf')
    		$unit = 'KB';
    	else if($paramEval == 'blk_size')
    		$unit = 'MB';
    	
    	return $unit;
    }
    
    public static function getFilterOptions($dbUtils) {
    	$options['benchs'] = $dbUtils->get_rows("SELECT DISTINCT bench FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench ASC");
    	$options['net'] = $dbUtils->get_rows("SELECT DISTINCT net FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY net ASC");
    	$options['disk'] = $dbUtils->get_rows("SELECT DISTINCT disk FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY disk ASC");
    	$options['blk_size'] = $dbUtils->get_rows("SELECT DISTINCT blk_size FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY blk_size ASC");
    	$options['comp'] = $dbUtils->get_rows("SELECT DISTINCT comp FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY comp ASC");
    	$options['id_cluster'] = $dbUtils->get_rows("select distinct id_cluster,CONCAT_WS('/',LPAD(id_cluster,3,0),c.vm_size,CONCAT(c.datanodes,'Dn')) as name from aloja2.execs e JOIN aloja2.clusters c using (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY c.name ASC");
    	$options['maps'] = $dbUtils->get_rows("SELECT DISTINCT maps FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY maps ASC");
    	$options['replication'] = $dbUtils->get_rows("SELECT DISTINCT replication FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY replication ASC");
        $options['run_num'] = $dbUtils->get_rows("SELECT DISTINCT run_num FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY run_num ASC");
    	$options['iosf'] = $dbUtils->get_rows("SELECT DISTINCT iosf FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iosf ASC");
    	$options['iofilebuf'] = $dbUtils->get_rows("SELECT DISTINCT iofilebuf FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY iofilebuf ASC");
    	$options['datanodes'] = $dbUtils->get_rows("SELECT DISTINCT datanodes FROM aloja2.execs e JOIN aloja2.clusters USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY datanodes ASC");
    	$options['benchtype'] = $dbUtils->get_rows("SELECT DISTINCT bench_type FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY bench_type ASC");
    	$options['vm_size'] = $dbUtils->get_rows("SELECT DISTINCT vm_size FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_size ASC");
    	$options['vm_cores'] = $dbUtils->get_rows("SELECT DISTINCT vm_cores FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_cores ASC");
    	$options['vm_ram'] = $dbUtils->get_rows("SELECT DISTINCT vm_RAM FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_RAM ASC");
    	$options['hadoop_version'] = $dbUtils->get_rows("SELECT DISTINCT hadoop_version FROM aloja2.execs e WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY hadoop_version ASC");
    	$options['type'] = $dbUtils->get_rows("SELECT DISTINCT type FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY type ASC");
    	$options['presets'] = $dbUtils->get_rows("SELECT * FROM aloja2.filter_presets ORDER BY short_name DESC");
        $options['provider'] = $dbUtils->get_rows("SELECT DISTINCT provider FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY provider DESC;");
    	$options['vm_OS'] = $dbUtils->get_rows("SELECT DISTINCT vm_OS FROM aloja2.execs e JOIN aloja2.clusters c USING (id_cluster) WHERE 1 AND valid = 1 AND filter = 0 ".DBUtils::getFilterExecs()." ORDER BY vm_OS DESC;");
    	return $options;
    }
    
    public static function getExecutionCost($exec, $clusterCosts) {
        $costHour = $clusterCosts['costsHour'][$exec['id_cluster']];
        $costRemote = $clusterCosts['costsRemote'][$exec['id_cluster']];
        $costSSD = $clusterCosts['costsSSD'][$exec['id_cluster']];
        $costIB = $clusterCosts['costsIB'][$exec['id_cluster']];

    	$num_remotes = 0;
    	/** calculate remote */
    	if(preg_match("/^RL/", $exec['disk']) || preg_match("/^RR/", $exec['disk'])) {
    		$num_remotes = (int)$exec['disk'][2];
    	}
    	
    	/** calculate HDD */
    	if(preg_match("/^HD[0-9]/", $exec['disk'])) {
    		$num_remotes = (int)$exec['disk'][2];
    	}
    	
    	$num_ssds=0;
    	
    	
    	/** calculate Multiple SSDs */
    	if(preg_match("/^SS[0-9]/", $exec['disk'])) {
    		$num_ssds= (int)$exec['disk'][2];
    	}
    	
    	/** if local SSD, numSSDs + 1, remotes = num HDD */
    	if(preg_match("/^HS[0-9]/", $exec['disk'])) {
    		$num_ssds=1;
    		$num_remotes = (int)$exec['disk'][2];
    	}

    	$num_IB=0;
    	 
    	if($exec['net'] == "IB")
    		$num_IB = 1;
    	
    	if($exec['disk'] == "SSD")
    		$num_ssds = 1;
    	
    	if($exec['disk'] == 'HDD')
    		$num_remotes = 1;
    	
    	//To get the cost
        //convert the cluster cost + additions from per hour to per second, then just multiply by number of seconds it took

        // ADLA tests
        if (isset($_GET['cluster_hours'])) {
            if(in_array($exec['id_cluster'], array(101, 102, 103))) {
                $cost = (($costHour + ($costRemote * $num_remotes) + ($costIB * $num_IB) + ($costSSD * $num_ssds))) * $_GET['cluster_hours'];
            } else {
                $cost = (($costHour + ($costRemote * $num_remotes) + ($costIB * $num_IB) + ($costSSD * $num_ssds))) * 168;
            }
        // Normal
        } else {
            $cost = $exec['exe_time']*(($costHour + ($costRemote * $num_remotes) + ($costIB * $num_IB) + ($costSSD * $num_ssds))/3600);
        }

    	return $cost;
    }
    
    public static function getClustersInfo($dbUtils) {
    	$rows = $dbUtils->get_rows("SELECT * FROM aloja2.clusters");

    	$clusters = array();
    	foreach($rows as $row) {
    		$clusters[$row['name']] = $row;
    	}
    	
    	return json_encode($clusters);
    }

    public static function initDefaultPreset($db, $screen) {
    	$presets = $db->get_rows("SELECT * FROM aloja2.filter_presets WHERE default_preset = 1 AND selected_tool = '$screen'");
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

    public static function generateCostsFilters($dbConnection) {
        $clustersInfo = $dbConnection->get_rows("SELECT id_cluster,cost_hour,cost_remote,cost_IB,cost_SSD FROM clusters");
        foreach ($clustersInfo as $row) {
            $costsHour[$row['id_cluster']] = $row['cost_hour'];
            $costsRemote[$row['id_cluster']] = $row['cost_remote'];
            $costsSSD[$row['id_cluster']] = $row['cost_IB'];
            $costsIB[$row['id_cluster']] = $row['cost_SSD'];
        }

        //If form submitted, get given values and change those
        if(isset($_GET['cost_hour'])) {
            foreach(Utils::get_GET_intArray('cost_hour') as $idCluster => $value) {
                $costsHour[$idCluster] = $value;
            }

            foreach(Utils::get_GET_intArray('cost_remote') as $idCluster => $value) {
                $costsRemote[$idCluster] = $value;
            }

            foreach(Utils::get_GET_intArray('cost_IB') as $idCluster => $value) {
                $costsSSD[$idCluster] = $value;
            }

            foreach(Utils::get_GET_intArray('cost_SSD') as $idCluster => $value) {
                $costsIB[$idCluster] = $value;
            }
        }

        return array('costsHour' => $costsHour,
            'costsRemote' => $costsRemote,
            'costsSSD' => $costsSSD,
            'costsIB' => $costsIB);
    }

    public static function multi_implode($array, $glue) {
        $ret = '';

        if(!is_array($array))
            return $ret;

        foreach ($array as $item) {
            if (is_array($item)) {
                $ret .= Utils::multi_implode($item, $glue) . $glue;
            } else {
                $ret .= $item . $glue;
            }
        }

        $ret = substr($ret, 0, 0-strlen($glue));

        return $ret;
    }

    /**
     * @return checks if we are in development environment
     */
    public static function in_dev()
    {
        if (is_dir('/vagrant')) return true;

        if (isset($_SERVER['HTTP_CLIENT_IP'])
            || isset($_SERVER['HTTP_X_FORWARDED_FOR'])
            || !in_array(@$_SERVER['REMOTE_ADDR'], array('127.0.0.1', 'fe80::1', '::1', '10.0.2.2', '192.168.99.1'))) {
            return false;
        } else
            return true;
    }

    public static function beautifyDatasize($value) {
        $nDigits = strlen((string)$value);
        $return = '';
        if($nDigits >= 4) {
            if($nDigits >= 8) {
                if($nDigits >= 10) {
                    if($nDigits >= 13) {
                        $return = ceil(($value/1000000000000)) . ' TB';
                    } else
                        $return = ceil(($value/1000000000)) . ' GB';
                } else
                    $return = ceil(($value/1000000)) . ' MB';
            } else
                $return = ceil(($value/1000)) . ' KB';
        } else
            $return = $value . ' B';

        return $return;
    }

    public static function cmp_conf($a, $b)
    {
//        if ($a == $b) {
//            return 0;
//        }
//        return ($a < $b) ? -1 : 1;
        return strnatcmp($a['conf'],$b['conf']);
    }
}
