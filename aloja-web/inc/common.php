<?php

require_once('vendor/autoload.php');

function in_dev() {
    if ($_SERVER['SERVER_NAME'] == 'minerva.bsc.es' ||
        $_SERVER['SERVER_NAME'] == 'hadoop.bsc.es'
    ) {
        return false;
    } else {
        return true;
    }
}

if (in_dev()) {
    ini_set('display_errors', 'On');
    error_reporting(E_ALL);
    ini_set('memory_limit', '256M');
    
    require_once('config.sample.php');
} else {
	require_once('config.php');
}

$loader = new Twig_Loader_Filesystem('views/');
$twig   = new Twig_Environment($loader, array('debug' => ENABLE_DEBUG));


$message        = null;
$db             = null;
$exec_rows      = null;
$id_exec_rows   = null;

$cache_path = '/tmp';

function make_tooltip($tooltip)
{
	return '<img class="tooltip2" src="img/info_small.png" style="width: 10px; height: 10px; margin-bottom: 1px; margin-left: 2px;" data-toggle="tooltip" data-placement="top" data-title="'.$tooltip.'"></img>';
}

function init_db() {
    global $db;

    $db = new PDO(DB_CONN_CHAIN, MYSQL_USER, MYSQL_PWD);

    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
}

function get_rows($sql) {
    global $db, $cache_path;

    $md5_sql = md5($sql);
    $file_path = "$cache_path/CACHE_$md5_sql.sql";

    if (in_dev() || $_SERVER['HTTP_HOST'] == 'localhost' || (isset($_GET['NO_CACHE']) && strlen($_GET['NO_CACHE']) > 0)) { //
        $use_cache = false;
    } else {
        $use_cache = true;
    }

    //check for cache first
    if ($use_cache &&
        file_exists($file_path) &&
        ($rows = file_get_contents($file_path)) &&
        ($rows = unserialize(gzuncompress($rows)))
    ) {

if (in_dev())
    echo "<!--CACHED: $sql --->\n";

    } else {
        if (!$db) init_db();

if (in_dev()) echo "<!--NO CACHE: $sql --->\n";

        try {
            $sth = $db->prepare($sql);
            $sth->execute();
        } catch (Exception $e) {
            throw new Exception($e->getMessage(). " SQL: $sql");
        }

        $rows = $sth->fetchAll(PDO::FETCH_ASSOC);

        //save cache
        if ($rows) {
            file_put_contents($file_path, gzcompress(serialize($rows), 9));
        }
    }

    return $rows;
}

$filter_execs = "AND exe_time > 200 AND (id_cluster = 1 OR (bench != 'bayes' AND id_cluster=2))";
$filter_execs_max_time = "AND exe_time < 10000";
function get_execs() {
    global $filter_execs;
    $query = "SELECT e.*, (exe_time/3600)*(cost_hour) cost  FROM execs e
    join clusters USING (id_cluster)
    WHERE 1 $filter_execs
    AND id_exec IN (select distinct (id_exec) from SAR_cpu where id_exec is not null and host not like '%-1001');
    ";
    return get_rows($query);
}

/* To delete
function get_counters($table_name, $execs) {
    $query = "SELECT e.bench, exe_time, c.* FROM ".$table_name." c JOIN execs e using (id_exec) WHERE 1 ".
        ($execs ? ' AND id_exec IN ('.join(',', $execs).') ':'').
        //($table_name == 'JOB_task_history' ? ' AND task_name != "" ':'').
        " ;";
    return get_rows($query);
}
*/

function get_hosts($clusters) {
    $query = 'SELECT * FROM hosts WHERE id_cluster IN ("'.join('","', $clusters).'");';
    return get_rows($query);
}

function get_GET_execs() {
    $execs = array();
    if (isset($_GET['execs'])) {
        $execs_tmp = array_unique($_GET['execs']);
        foreach ($execs_tmp as $exec) {
            $execs[] = filter_var($exec, FILTER_SANITIZE_NUMBER_INT);
        }
    }

    return $execs;
}


function get_GET_string($param) {
    if (isset($_GET[$param]))
        return filter_var($_GET[$param], FILTER_SANITIZE_STRING);
}

function get_GET_int($param) {
    if (isset($_GET[$param]))
        return filter_var($_GET[$param], FILTER_SANITIZE_NUMBER_INT);
}

function get_exec_details($id_exec, $field) {
    global $exec_rows, $id_exec_rows;
    if (is_numeric($id_exec) && $field) {
        if (!$exec_rows) $exec_rows = get_execs();

        if (!$id_exec_rows) {
            $new_rows = array();
            foreach ($exec_rows as $row) {
                foreach ($row as $key_row=>$field_value) {
                    if (is_numeric($field_value)) {
                        $new_rows[$row['id_exec']][$key_row] = round($field_value, 2);
                    } else {
                        $new_rows[$row['id_exec']][$key_row] = $field_value;
                    }
                }
            }
            $exec_rows = $new_rows;
            $id_exec_rows = true;
        }

        if (isset($exec_rows[$id_exec][$field]))
            return $exec_rows[$id_exec][$field];
        else
            return false;
    } else {
        return false;
    }
}

function minimize_array($array) {
    foreach ($array as $key=>$value) {
        if (is_numeric($value))
            $array[$key] = round($value, 2);
    }
    return $array;
}

function minimize_exec_rows(array $rows, $stacked = false) {
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
             throw new Exception("Incorrect array format!");
        }
    }

    return array($minimized_rows, $max, $min);
}


function csv_to_array($filename='', $delimiter=',') {
    if(!file_exists($filename) || !is_readable($filename))
        return FALSE;

    $header = NULL;
    $data = array();
    if (($handle = fopen($filename, 'r')) !== FALSE)
    {
        while (($row = fgetcsv($handle, 1000, $delimiter)) !== FALSE)
        {
            if(!$header)
                $header = $row;
            else
                $data[] = array_combine($header, $row);
        }
        fclose($handle);
    }

    return $data;
}

function find_config($config, $csv) {
    $return = false;
    foreach ($csv as $key_row=>$value_row) {
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


$show_in_result = array(
    'id_exec' => 'ID',
    'bench' => 'Benchmark',
    'exe_time' => 'Exe Time',
    'exec' => 'Exec Conf',
    'cost' => 'Running Cost $',
    'net' => 'Net',
    'disk' => 'Disk',
    'maps' => 'Maps',
    'iosf' => 'IO SFac',
    'replication' => 'Rep',
    'iofilebuf' => 'IO FBuf',
    'comp' => 'Comp',
    'blk_size' => 'Blk size',
    'id_cluster' => 'Cluster',
    'files' => 'Files',
    'prv' => 'PARAVER',
    //'version' => 'Hadoop v.',
    'init_time' => 'End time',
);

function generate_show($show_in_result, $csv, $offset) {

    reset($csv);
    $header = current($csv);

    $dont_show= array('job_name');

    $position = 0;
    foreach ($header as $key_header=>$value_header) {
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

function generate_table($csv, $show_in_result, $precision = null, $type = null) {

    if (!$csv) {
        return '<tr><td>NO DATA</td></tr>';
    }

    $table_fields = "<thead>\n\t<tr>\n";
    $table_fields .= "\t\t<th></th>\n";
    foreach ($show_in_result as $key_name=>$column_name) {
    	if($column_name == 'IO SFac')
    		$column_name.=make_tooltip('The number of streams to merge at once while sorting files. This determines the number of open file handles.');
    	else if($column_name == 'IO FBuf')
    		$column_name.=make_tooltip('The total amount of buffer memory to use while sorting files, in megabytes. By default, gives each merge stream 1MB, which should minimize seeks.');
        $table_fields .= "\t\t<th>$column_name</th>\n";
    }
    $table_fields .= "\t</tr>\n";

    //add seach inputs
    $table_fields .= "\t<tr>\n";
    $table_fields .= "\t\t<th><input type=\"text\" value=\"\" class=\"search_init\" style=\"visibility: hidden;\"></th>\n";
    foreach ($show_in_result as $key_name=>$column_name) {
        $table_fields .= "\t\t<th><input type=\"text\" value=\"filter col\" class=\"search_init\"></th>\n";
    }

    $table_fields .= "\t</tr>\n</thead>\n<tbody>\n";

    $i = 0;
    foreach ($csv as $key_row=>$value_row) {
        $table_fields .= "\t<tr>\n";
        $table_fields .= "\t\t<td><input type=\"checkbox\" name=\"execs[]\" value=\"{$value_row['id_exec']}\"></td>\n";
        foreach ($show_in_result as $key_name=>$column_name) {
            if ($precision !== null && is_numeric($value_row[$key_name])) {
                $value_row[$key_name] = round($value_row[$key_name], $precision);
            }

            if (!$type) {
                if ($key_name == 'bench') {
                    $value = "<a href=\"charts1.php?execs[]={$value_row['id_exec']}\" target=\"_blank\">".$value_row[$key_name]."</a>";
                } elseif ($key_name == 'init_time') {
                    $value = date('YmdHis', strtotime($value_row['end_time']));
                } elseif ($key_name == 'exe_time') {
                    $value = round($value_row['exe_time']);
                } elseif ($key_name == 'files') {
                    $value = "<a href=\"/jobs/".substr($value_row['exec'], 0, strpos($value_row['exec'], '/'))."\"  target=\"_blank\">files</a>";
                } elseif ($key_name == 'prv') {
                    $value = "<a href=\"exp2prv.php?id_exec={$value_row['id_exec']}\"  target=\"_blank\">PRV .ZIP</a>";
                } elseif ($key_name == 'version') {
                    $value = "1.0.3";
                } elseif ($key_name == 'cost') {
                    $value = number_format($value_row['cost'], 2);
                } elseif ($key_name == 'id_cluster') {
                    if (strpos($value_row['exec'], '_az')) $value = 'Azure L';
                    else $value = "Local 1";
                } elseif (stripos($key_name, 'BYTES') !== false) {
                    $value = round(($value_row[$key_name])/(1024*1024));
                } elseif ($key_name == 'FINISH_TIME') {
                    $value = date('YmdHis', round($value_row[$key_name]/1000));
                } else {
                    $value = $value_row[$key_name];
                    $tooltip = null;
                    if($key_name == 'net')
                    	$tooltip = ($value == 'ETH') ? 'Ethernet' : 'Infiniband';
                    else if($key_name == 'disk') {
                    	if($value == 'SSD')
                    		$tooltip = 'Solid-state disk';
                    	else if($value == 'HDD')
                    		$tooltip = 'Hard disk';
                    	else
                    		$tooltip = substr($value, 2) . ' remote(s)';
                    }
                    
                    if(isset($tooltip))
                    	$value.=make_tooltip($tooltip);
                }
            } else {
                if ($key_name == 'JOBID') {
                    $value = "<a href=\"counters.php?execs[]={$value_row['id_exec']}&type=TASKS\" >".$value_row[$key_name]."</a>";
                } elseif (stripos($key_name, 'BYTES') !== false) {
                    $value = round(($value_row[$key_name])/(1024*1024));
                } elseif (stripos($key_name, 'TIME') !== false){
                    $value = substr($value_row[$key_name], -8);
                } elseif (strpos($key_name, 'JOBNAME') !== false){
                    if (strlen($value_row[$key_name]) > 15)
                        $value = substr($value_row[$key_name], 0, 15).'.';
                    else
                        $value = $value_row[$key_name];
                } else {
                    $value = $value_row[$key_name];
                }

            }

            $table_fields .= "\t\t<td>$value</td>\n";
        }
        $table_fields .= "\t</tr>\n";
        $i++;

        //if ($i > 10) break;
    }
    //build the search footer
    /*
    $table_fields .= "<tfoot>\n\t<tr>\n";
    $table_fields .= "\t\t<th>Filter col: <input type=\"text\" value=\"\" class=\"search_init\" style=\"visibility: hidden;\"></th>\n";
    foreach ($show_in_result as $key_name=>$column_name) {
        $table_fields .= "\t\t<th><input type=\"text\" value=\"\" class=\"search_init\"></th>\n";
    }
    $table_fields .= "\t</tr>\n</tfoot>\n";
    */
    return $table_fields;
}

function make_execs(array $execs) {
    $return = '';
    foreach ($execs as $exec) {
        $return .= '&execs[]='.$exec;
    }
    return $return;
}

//copied functions
function url_origin($s, $use_forwarded_host=false)
{
    $ssl = (!empty($s['HTTPS']) && $s['HTTPS'] == 'on') ? true:false;
    $sp = strtolower($s['SERVER_PROTOCOL']);
    $protocol = substr($sp, 0, strpos($sp, '/')) . (($ssl) ? 's' : '');
    $port = $s['SERVER_PORT'];
    //$port = ((!$ssl && $port=='80') || ($ssl && $port=='443')) ? '' : ':'.$port;
    $host = ($use_forwarded_host && isset($s['HTTP_X_FORWARDED_HOST'])) ? $s['HTTP_X_FORWARDED_HOST'] : (isset($s['HTTP_HOST']) ? $s['HTTP_HOST'] : $s['SERVER_NAME']);
    return $protocol . '://' . $host ;//. $port;
}

function full_url($s, $use_forwarded_host=false)
{
    return url_origin($s, $use_forwarded_host) . $s['REQUEST_URI'];
}

$function = new Twig_SimpleFunction('modifyUrl', function ($mod) {
	$url = full_url($_SERVER);

    $query = explode("&", $_SERVER['QUERY_STRING']);
    if (!$_SERVER['QUERY_STRING']) {$queryStart = "?";} else {$queryStart = "&";}
    // modify/delete data
    foreach($query as $q)
    {
        if ($q) {
            list($key, $value) = explode("=", $q);
            if(array_key_exists($key, $mod))
            {
                if($mod[$key])
                {
                    $url = preg_replace('/'.$key.'='.$value.'/', $key.'='.$mod[$key], $url);
                }
                else
                {
                    $url = preg_replace('/&?'.$key.'='.$value.'/', '', $url);
                }
            }
        }
    }
    // add new data
    foreach($mod as $key => $value)
    {
        if($value && !preg_match('/'.$key.'=/', $url))
        {
            $url .= $queryStart.$key.'='.$value;
        }
    }

    //remove first directory to fix "redirection" in hadoop.bsc.es
    if (strpos($url, '.php')) {
        $url = substr($url, strpos($url, basename($url)));
    }

    return $url;
});
$twig->addFunction($function);