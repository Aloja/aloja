<?php

ini_set('memory_limit', '256M');
error_reporting(512);

require_once 'inc/common.php';

try {
    $message = null; //for error reporting

    if (get_GET_int('id_exec')) {
        $id_exec = get_GET_string('id_exec');
    } else {
        throw new Exception('id_execution not set!');
    }

    $exec_name = get_exec_details($id_exec, 'exec');
    $exec_name = str_replace('/', '_', $exec_name);

    $dir = '/tmp/prv';
    $zip_file = "$exec_name.zip";

    $full_name = "$dir/$zip_file";

    //check if it needs to be created
    if(!(file_exists($full_name) && is_readable($full_name) && file_exists($full_name))){
        $query = '
SELECT
concat(
"2:",
substring(host, -1),
":1:",
substring(host, -1),
":1:",
(unix_timestamp(date) -
(select unix_timestamp(min(date)) FROM SAR_cpu t WHERE id_exec = "'.$id_exec.'"))*1000000000,
":2001:",round(AVG(`%user`)),
":2002:",round(AVG(`%system`)),
":2003:",round(AVG(`%steal`)),
":2004:",round(AVG(`%iowait`)),
":2005:",round(AVG(`%nice`))
) prv
FROM SAR_cpu t WHERE id_exec = "'.$id_exec.'"
GROUP BY date, host ORDER by date, host;';

        $prv_rows = get_rows($query);

        if (!isset($prv_rows)) throw new Exception('No data returned!');

        $query_job_history = 'select time, maps, reduce from JOB_job_history where id_exec = "'.$id_exec.'" ORDER by time';

        $job_history_rows = get_rows($query_job_history);

        $test = "count ".count($prv_rows)." count2 ".count($job_history_rows);

        if ($job_history_rows) {
            $key_job_history = 0;
            $current_time = 0; //skip first second
            foreach ($prv_rows as $key_prv_row=>$prv_row) {
                $parts = explode(':', $prv_row['prv']);

                //only one time per time and group of hosts
                if (!$current_time || $parts[5] != $current_time) {
                    $current_time = $parts[5];
                    if (isset($job_history_rows[$key_job_history])) {
                        $prv_rows[$key_prv_row]['prv'] =
                            $prv_rows[$key_prv_row]['prv'].
                            ":1001:".round($job_history_rows[$key_job_history]['maps']).
                            ":1002:".round($job_history_rows[$key_job_history]['reduce'])
                        ;
                    }
                    $key_job_history++;
                }
            }
        }

        //get the ending time
        $end = end($prv_rows)['prv'];
        $end = explode(':', $end);

        $header = "#Paraver (".date('d/m/y \a\t H:i')."):".$end[5].":4(1,1,1,1):1:4(1:1,1:2,1:3,1:4),0";

        $row_file =
'LEVEL CPU SIZE 4
CPU-MASTER
CPU-SLV1
CPU-SLV2
CPU-SLV3

LEVEL APPL SIZE 1
'.$exec_name.'

TASK LEVEL SIZE 4
JT+NN
TT1+DN1
TT2+DN2
TT3+DN3

LEVEL NODE SIZE 4
MASTER-NODE
SLAVE-NODE-1
SLAVE-NODE-2
SLAVE-NODE-3

LEVEL THREAD SIZE 4
THREAD-JT+NN
THREAD-TT1+DN1
THREAD-TT2+DN2
THREAD-TT3+DN3';

        $pcf_file =
'DEFAULT_OPTIONS

LEVEL               NODE
UNITS               NANOSEC
LOOK_BACK           100
SPEED               1
FLAG_ICONS          ENABLED
NUM_OF_STATE_COLORS 1000
YMAX_SCALE          37


DEFAULT_SEMANTIC

THREAD_FUNC          State As Is


STATES
0    Idle
1    Running
2    Not created
3    Waiting a message
4    Blocking Send
5    Synchronization
6    Test/Probe
7    Scheduling and Fork/Join
8    Wait/WaitAll
9    Blocked
10    Immediate Send
11    Immediate Receive
12    I/O
13    Group Communication
14    Tracing Disabled
15    Others
16    Send Receive
17    Memory transfer

STATES_COLOR
0    {117,195,255}
1    {0,0,255}
2    {255,255,255}
3    {255,0,0}
4    {255,0,174}
5    {179,0,0}
6    {0,255,0}
7    {255,255,0}
8    {235,0,0}
9    {0,162,0}
10    {255,0,255}
11    {100,100,177}
12    {172,174,41}
13    {255,144,26}
14    {2,255,177}
15    {192,224,0}
16    {66,66,66}
17    {255,0,96}

EVENT_TYPE
6   1001        Number of running Maps
6   1002        Number of running Reduces

EVENT_TYPE
6   2001        CPU Usage - User (%)
6   2002        CPU Usage - System (%)
6   2003        CPU Usage - Steal (%)
6   2004        CPU Usage - IOwait (%)
6   2005        CPU Usage - Nice (%)

EVENT_TYPE
6   3001        System Load Avg-1min
6   3001        System Load Avg-5min
6   3001        System Load Avg-15min

EVENT_TYPE
6   4001        Mem KB used
6   4002        Mem KB free

EVENT_TYPE
6   5001        Page faults per second
6   5002        Major Page faults per second
6   5003        Pages freed per second



GRADIENT_COLOR
0    {0,255,2}
1    {0,244,13}
2    {0,232,25}
3    {0,220,37}
4    {0,209,48}
5    {0,197,60}
6    {0,185,72}
7    {0,173,84}
8    {0,162,95}
9    {0,150,107}
10    {0,138,119}
11    {0,127,130}
12    {0,115,142}
13    {0,103,154}
14    {0,91,166}


GRADIENT_NAMES
0    Gradient 0
1    Grad. 1/MPI Events
2    Grad. 2/OMP Events
3    Grad. 3/OMP locks
4    Grad. 4/User func
5    Grad. 5/User Events
6    Grad. 6/General Events
7    Grad. 7/Hardware Counters
8    Gradient 8
9    Gradient 9
10    Gradient 10
11    Gradient 11
12    Gradient 12
13    Gradient 13
14    Gradient 14


EVENT_TYPE
9    40000018    Tracing mode:
VALUES
1      Detailed
2      CPU Bursts';

        $prv_file = $header."\n";
        foreach ($prv_rows as $prv_row) {
            $prv_file .= $prv_row['prv']."\n";
        }

        //create the file
        if (!is_dir("$dir/$exec_name/")) {
            mkdir("$dir/$exec_name/", 0777, true);
        }
        file_put_contents($dir."/$exec_name/$exec_name.pcf", $pcf_file);
        file_put_contents($dir."/$exec_name/$exec_name.row", $row_file);
        file_put_contents($dir."/$exec_name/$exec_name.prv", $prv_file);

        if (!exec("cd $dir &&  zip -r $zip_file $exec_name && rm -rf $exec_name") || !file_exists("$dir/$zip_file")) {
            throw new Exception('Could not create .zip');
        }
    }

    //donwload the file
    if(file_exists($full_name) && is_readable($full_name) && file_exists($full_name)){
        header("Content-Disposition: attachment; filename=".basename(str_replace(' ', '_', $full_name)));
        header("Content-Type: application/force-download");
        header("Content-Type: application/octet-stream");
        header("Content-Type: application/download");
        header("Content-Description: File Transfer");
        header("Content-Length: " . filesize($full_name));
        flush(); // this doesn't really matter.

        $fp = fopen($full_name, "r");
        while (!feof($fp))
        {
            echo fread($fp, 65536);
            flush(); // this is essential for large downloads
        }
        fclose($fp);
        exit;
    } else {
        throw new Exception('Could not read zip file');
    }

} catch(Exception $e) {
    $message .= $e->getMessage()."\n";
    echo $message;
    exit;
}


