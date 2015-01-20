<?php

namespace alojaweb\inc;

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

    public static function read_params($item_name, &$where_configs, &$configurations, &$concat_config, $setDefaultValues = true, $table_name = null)
    {
    	if($item_name == 'money' && isset($_GET['money'])) {
    		$money = $_GET['money'];
    		if($money != '') {
    			$where_configs .= ' AND (exe_time/3600)*(cost_hour) <= '.$_GET['money'];
    		}
    		return $_GET['money'];
    	}
    	
        $single_item_name = substr($item_name, 0, -1);

        if (isset($_GET[$item_name])) {
            $items = $_GET[$item_name];
            $items = Utils::delete_none($items);
        } else if($setDefaultValues) {
            if ($item_name == 'benchs') {
                $items = array('terasort', 'wordcount', 'sort');
            } elseif ($item_name == 'nets') {
                $items = array();
            } elseif ($item_name == 'disks') {
                $items = array('SSD', 'HDD', 'RR3', 'RR2', 'RR1', 'RL3', 'RL2', 'RL1');
            } else {
                $items = array();
            }
        } else
        	$items = array();

        if ($items) {
            if ($item_name != 'benchs') {
                $configurations[] = $single_item_name;
                if ($concat_config) $concat_config .= ",'_',";

                if ($item_name == 'id_clusters') {
                    $conf_prefix = 'CL';
                } elseif ($item_name == 'iofilebufs') {
                    $conf_prefix = 'I';
                } else {
                    $conf_prefix = substr($single_item_name, 0, 1);
                }

                //avoid alphanumeric fields
                if (!in_array($item_name, array('nets', 'disks'))) {
                    $concat_config .= "'".$conf_prefix."', $single_item_name";
                } else {
                    $concat_config .= " $single_item_name";
                }
            }

            if ($table_name !== null) {
                $single_item_name = $table_name.'.`'.$single_item_name.'`';
            }

            $where_configs .=
            ' AND '.
            $single_item_name. //remove trailing 's'
            ' IN ("'.join('","', $items).'")';
        }

        return $items;
    }

    public static function generateJSONTable($csv, $show_in_result, $precision = null, $type = null)
    {
        $jsonData = array();

        $i = 0;
        $naValues=array('net','disk','maps','iosf','replication','iofilebuf','comp','blk_size',);
        foreach ($csv as $value_row) {
            $jsonRow = array();
            $jsonRow[] = $value_row['id_exec'];
            $clusterName = $value_row['cluster_name'];
            
            foreach (array_keys($show_in_result) as $key_name) {
                if ($precision !== null && is_numeric($value_row[$key_name])) {
                    $value_row[$key_name] = round($value_row[$key_name], $precision);
                }
                
                if (!$type) {
                	if ($clusterName == 'HDInsight' && in_array($key_name,$naValues))
                		$jsonRow[] = 'N/A';
                    elseif ($key_name == 'bench') {
                        $jsonRow[] = $value_row[$key_name];
                    } elseif ($key_name == 'init_time') {
                        $jsonRow[] = date('YmdHis', strtotime($value_row['end_time']));
                    } elseif ($key_name == 'exe_time') {
                        $jsonRow[] = round($value_row['exe_time']);
                    } elseif ($key_name == 'files') {
                        $jsonRow[] = $value_row['exec'];
                    } elseif ($key_name == 'prv') {
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

        return json_encode(array('aaData' => $jsonData));
    }

    public static function get_GET_execs()
    {
        $execs = array();
        if (isset($_GET['execs'])) {
            $execs_tmp = array_unique($_GET['execs']);
            foreach ($execs_tmp as $exec) {
                $execs[] = filter_var($exec, FILTER_SANITIZE_NUMBER_INT);
            }
        }

        return $execs;
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
    
    public static function getExecsOptions($db)
    {
        $filter_execs = DBUtils::getFilterExecs();

        $benchOptions = $db->get_rows("SELECT DISTINCT bench FROM execs WHERE 1 $filter_execs");
    	$netOptions = $db->get_rows("SELECT DISTINCT net FROM execs WHERE 1 $filter_execs");
    	$diskOptions = $db->get_rows("SELECT DISTINCT disk FROM execs WHERE 1 $filter_execs");
    	$mapsOptions = $db->get_rows("SELECT DISTINCT maps FROM execs WHERE 1 $filter_execs");
    	$compOptions = $db->get_rows("SELECT DISTINCT comp FROM execs WHERE 1 $filter_execs");
    	$blk_sizeOptions = $db->get_rows("SELECT DISTINCT blk_size FROM execs WHERE 1 $filter_execs");
    	$clusterOptions = $db->get_rows("SELECT DISTINCT clusters.name FROM execs, clusters WHERE execs.id_cluster = clusters.id_cluster $filter_execs");
    	$clusterNodes = $db->get_rows("SELECT DISTINCT clusters.nodes_number FROM execs, clusters WHERE execs.id_cluster = clusters.id_cluster $filter_execs");
    	$hadoopVersion = $db->get_rows("SELECT DISTINCT hadoop_version FROM execs WHERE 1 $filter_execs");
    	
    	$discreteOptions = array();
    	$discreteOptions['bench'][] = 'All';
    	$discreteOptions['net'][] = 'All';
    	$discreteOptions['disk'][] = 'All';
    	$discreteOptions['maps'][] = 'All';
    	$discreteOptions['comp'][] = 'All';
    	$discreteOptions['blk_size'][] = 'All';
    	$discreteOptions['id_cluster'][] = 'All';
    	$discreteOptions['nodes_number'][] = 'All';
    	$discreteOptions['hadoop_version'][] = 'All';
    	
    	foreach($benchOptions as $option) {
    		$discreteOptions['bench'][] = array_shift($option);
    	}
    	foreach($netOptions as $option) {
    		$discreteOptions['net'][] = array_shift($option);
    	}
    	foreach($diskOptions as $option) {
    		$discreteOptions['disk'][] = array_shift($option);
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
    		$discreteOptions['nodes_number'][] = array_shift($option);
    	}
    	foreach($hadoopVersion as $option) {
    		$discreteOptions['hadoop_version'][] = array_shift($option);
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

    public static function getClusterName($clusterCode)
    {
        $clusterName = 'Undefined';
        if($clusterCode == 1)
            $clusterName = 'Local';
        else
            $clusterName = 'Azure';

        return $clusterName;
    }
    
    public static function getNetworkName($netShort)
    {
    	$netName = '';
    	if($netShort == 'IB')
    		$netName = 'Infiniband';
    	else
    		$netName = 'Ethernet';
    	
    	return $netName;
    }
    
    public static function getDisksName($diskShort)
    {
    	$disks = '';
    	if($diskShort == 'HDD')
    		$disks = 'Hard-disk drive';
    	elseif($diskShort == 'SSD')
    		$disks = 'SSD';
    	else if(substr($diskShort,2))
    		$disks = substr($diskShort,2).' HDFS remote(s)/tmp local';
    	else
    		$disks = substr($diskShort,1).' HDFS remote(s)';
    
    	return $disks;
    }
    
    public static function makeExecInfoBeauty(&$execInfo)
    {
    	if(key_exists('comp',$execInfo))
    		$execInfo['comp'] = self::getCompressionName($execInfo['comp']);
    	
    	if(key_exists('net',$execInfo))
    		$execInfo['net'] = self::getNetworkName($execInfo['net']);
    	
    	if(key_exists('disk',$execInfo))
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
}
