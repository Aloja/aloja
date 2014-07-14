<?php

function in_dev() {
    if ($_SERVER['SERVER_NAME'] == 'minerva.bsc.es' ||
        $_SERVER['SERVER_NAME'] == 'hadoop.bsc.es'
    )
        return false;
    else
        return true;
}

if (in_dev()) {
    ini_set('display_errors', 'On');
    error_reporting(E_ALL);
    ini_set('memory_limit', '256M');
}

$message = null;
$db = null;
$exec_rows = null;
$id_exec_rows = null;

$cache_path = '/tmp';


function init_db() {
    global $db;

    if (!in_dev()) {
        $db = new PDO('mysql:host=localhost;dbname=aloja2;', 'root', '');
    } else {
        $db = new PDO('mysql:host=localhost;dbname=aloja2;', 'vagrant', 'vagrant');
        //$db = new PDO('mysql:host=127.0.0.1;port=3307;dbname=aloja2;', 'npm', 'aaa');
    }
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

function make_HTML_header($title = 'HiBench Executions on Hadoop') {
    $HTML_header =
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>'.$title.'</title>
    <style type="text/css" title="currentStyle">
    	@import "css/bootstrap.min.css";
        @import "css/styles.css";
    </style>
    ';
    return $HTML_header;
}

function include_datatables() {
    return
        '<style type="text/css">
        @import "js/datatables/media/css/demo_table.css";
        @import "js/datatables/media/css/jquery.dataTables.css";
        @import "js/datatables/extras/ColReorder/media/css/ColReorder.css";
        @import "js/datatables/extras/TableTools/media/css/TableTools.css";
        @import "js/datatables/extras/ColVis/media/css/ColVis.css";
    </style>
    <script type="text/javascript" language="javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/media/js/jquery.dataTables.min.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/extras/FixedHeader/js/FixedHeader.nightly.min.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/extras/ColReorder/media/js/ColReorder.nightly.min.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/extras/TableTools/media/js/TableTools.nightly.min.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/extras/TableTools/media/js/ZeroClipboard.js"></script>
    <script type="text/javascript" language="javascript" src="js/datatables/extras/ColVis/media/js/ColVis.nightly.min.js"></script>
    ';
}


function make_header ($title = 'HiBench Executions on Hadoop', $message = null) {
    $header = '
</head>
<body id="main">
<div id="container">
    <table width="100%" style="border-bottom: 2px solid #B0BED9;" border="0">
                <tr>
                    <td valign="bottom">
                        <span style="font-size: 1.5em;color: #4E6CA3;">
                            <strong>'.$title.'</strong>
                        </span></td>
                    <td align="right">
                        <a target="blank" href="http://www.bscmsrc.eu/"><img src="img/bsc-msrc_logo.png"></a>
                    </td>
                </tr>
            </table>
    <div class="modal fade" id="welcomeModal">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
        <h4 class="modal-title">Welcome to <strong>ALOJA</strong></h4>
      </div>
      <div class="modal-body">
        <p><strong>ALOJA</strong> is a project to explore Hadoop\'s performance under different Software parameters, Hardware, Cloud or On-Premise, and Job types.
            This site is under constant development and in the process of being documented.
            For inquiries, feature requests or bug reports please contact us at: <a href="mailto:hadoop@bsc.es" target="_top">hadoop@bsc.es</a></p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
            ';

    if ($message) {
        $header .="\n<div><h2 style=\"color: red; text-align: center;\"></br>$message</h2></div>\n";
    }

    return $header;
}

$footer = '
		<div id="copyright">
            <a target="blank" href="http://www.bsc.es/"><img height="44" width="163" src="http://www.bscmsrc.eu/bscmsrc/drupal/sites/default/files/bsc-logo.jpg" alt="BSC logo" /></a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <a target="blank" href="http://research.microsoft.com/"><img height="35" src="http://www.bscmsrc.eu/bscmsrc/drupal/sites/default/files/msr-logo.jpg" alt="MSR logo" class="logo" /></a>

            <div class="content"><p>Copyright 2014 © bscmsrc.eu All Rights Reserved. <a id="legal" href="http://www.bscmsrc.eu/legal-notice">Legal Notice</a> </p></div>
        </div>
		<script type="text/javascript" src="js/bootstrap.min.js"></script>
        <script>
        (function(i,s,o,g,r,a,m){i[\'GoogleAnalyticsObject\']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,\'script\',\'//www.google-analytics.com/analytics.js\',\'ga\');
        ga(\'create\', \'UA-47802380-2\', \'bsc.es\');
        ga(\'send\', \'pageview\');
        </script>
		<script type="text/javascript">
		  $(document).ready(function() {
		
            function getCookie(cname) {
           		var name = cname + "=";
          		var ca = document.cookie.split(\';\');
          		for(var i=0; i<ca.length; i++) {
          		  var c = ca[i].trim();
          		  if (c.indexOf(name) == 0) return c.substring(name.length,c.length);
          		}
          		return "";
          	}

            if(getCookie(\'rememberme\') != "true") {
        		document.cookie="rememberme=true";
        		$("#welcomeModal").modal({
        			show: true,
        		  	backdrop: \'static\'
        		});
        	}
		  });
		</script>
    </body>
</html>';

function make_navigation($selected = '') {
    global $execs;
    $navigation = '    <div id="navigation" style="text-align: center; width: 80%; margin-left: auto; margin-right: auto;">
        <h1>
            <strong>Navigation:</strong>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="datatable.php">'.($selected == 'HiBench Runs Details' ? '<strong>HiBench Runs Details</strong>':'HiBench Runs Details').'</a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="counters.php">'.($selected == 'Hadoop Job Counters' ? '<strong>Hadoop Job Counters</strong>':'Hadoop Job Counters').'</a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="perf_by_cost.php?bench=terasort">'.($selected == 'Cost Evaluation' ? '<strong>Cost Evaluation</strong>':'Cost Evaluation').'</a>
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="charts1.php?'.(isset($execs) && $execs ? make_execs($execs):'random=1').'">'.($selected == 'Performance Charts' ? '<strong>Performance Charts</strong>':'Performance Charts').'</a>
        </h1>
    </div>';

    return $navigation;
}

function make_datatables_help(){
    return 'Click on a <strong>benchmark name</strong> to see execution details.</br>
    Select different rows and <strong>click compare</strong>, to compare charts.</br>
    <strong>Search</strong> to filter results. Shift+Click to order by multiple columns</br>';
}

function make_loading(){
    return '        <div id="loading" style="height: 400px; text-align: center; font-size: 2em;">
            </br></br></br></br></br></br>
            <blink>Loading...</blink>
        </div>';
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

function modify_url($mod)
{
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
}