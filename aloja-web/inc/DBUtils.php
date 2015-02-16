<?php

namespace alojaweb\inc;

use alojaweb\inc\dbscan\DBSCAN;
use alojaweb\inc\dbscan\Cluster;
use alojaweb\inc\dbscan\Point;

class DBUtils
{
    public static $TASK_METRICS = [
        'Duration',
        'Bytes Read',
        'Bytes Written',
        'FILE_BYTES_WRITTEN',
        'FILE_BYTES_READ',
        'HDFS_BYTES_WRITTEN',
        'HDFS_BYTES_READ',
        'Spilled Records',
        'SPLIT_RAW_BYTES',
        'Map input records',
        'Map output records',
        'Map input bytes',
        'Map output bytes',
        'Map output materialized bytes',
        'Reduce input groups',
        'Reduce input records',
        'Reduce output records',
        'Reduce shuffle bytes',
        'Combine input records',
        'Combine output records',
    ];

    private $dbConn;
    private $container;

    public function __construct($container)
    {
        $this->container = $container;
    }

    public function init()
    {
        $this->dbConn = new \PDO($this->container['config']['db_conn_chain'], $this->container['config']['mysql_user'], $this->container['config']['mysql_pwd']);

        $this->dbConn->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
        $this->dbConn->setAttribute(\PDO::ATTR_EMULATE_PREPARES, false);
    }

    public function get_rows($sql, $params = array())
    {
        $md5_sql = md5($sql.http_build_query($params, '', ','));
        $file_path = "{$this->container['config']['db_cache_path']}/CACHE_$md5_sql.sql";

        if ($this->container['env'] == 'dev' || $_SERVER['HTTP_HOST'] == 'localhost' || (isset($_GET['NO_CACHE']) && strlen($_GET['NO_CACHE']) > 0)) {
            $use_cache = false;
        } else {
            $use_cache = true;
        }

        if (!$this->dbConn) $this->init();

        //check for cache first
        if ($use_cache &&
                file_exists($file_path) &&
                ($rows = file_get_contents($file_path)) &&
                ($rows = unserialize(gzuncompress($rows)))
        ) {
            $this->container['log']->addDebug('CACHED: '.$sql);
        } else {
            $this->container['log']->addDebug('NO CACHE: '.$sql);

            try {
                $sth = $this->dbConn->prepare($sql);
                $sth->execute($params);
            } catch (Exception $e) {
                throw new \Exception($e->getMessage(). " SQL: $sql");
            }

            $rows = $sth->fetchAll(\PDO::FETCH_ASSOC);

            //save cache
            if ($use_cache && $rows) {
                file_put_contents($file_path, gzcompress(serialize($rows), 9));
            }
        }

        return $rows;
    }

    public static function getFilterExecs()
    {
        return "
AND (bench_type = 'HiBench' OR bench_type = 'HDI')
AND bench not like 'prep_%'
AND bench_type not like 'HDI-prep%'
AND exe_time between 200 and 15000
AND id_exec IN (select distinct (id_exec) from JOB_status where id_exec is not null)
AND (bench_type = 'HDI' OR id_exec IN (select distinct (id_exec) from SAR_cpu where id_exec is not null))
";
//AND valid = 1
    }

    public function get_execs($filter_execs = null)
    {
        if($filter_execs === null)
            $filter_execs = DBUtils::getFilterExecs();

        $query = "SELECT e.*, (exe_time/3600)*(cost_hour) cost, name cluster_name, datanodes  FROM execs e
        join clusters USING (id_cluster)
        WHERE 1 $filter_execs  ;";

        return $this->get_rows($query);
    }

    public function get_exec_details($id_exec, $field, &$exec_rows, &$id_exec_rows)
    {
        if (is_numeric($id_exec) && $field) {
            if (!$exec_rows) $exec_rows = $this->get_execs();

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

    public function get_hosts($clusters)
    {
        $query = 'SELECT * FROM hosts WHERE id_cluster IN ("'.join('","', $clusters).'");';

        return $this->get_rows($query);
    }

    public function get_task_metric_query($metric)
    {
        if ($metric === 'Duration') {
            return function($table, $startField = "START_TIME", $finishField = "FINISH_TIME") { return "TIMESTAMPDIFF(SECOND, $table.`$startField`, $table.`$finishField`)"; };
        } else {
            return function($table) use ($metric)  { return "$table.`$metric`"; };
        }
    }

    public function get_task_type($task_type)
    {
        if ($task_type === 'MAP') {
            return 'MAP';
        } else if ($task_type === 'REDUCE') {
            return 'REDUCE';
        } else if ($task_type === 'CLEANUP') {
            return 'CLEANUP';
        } else if ($task_type === 'SETUP') {
            return 'SETUP';
        } else {
            return null;
        }
    }

    public function get_task_type_query($task_type, $filter_null = false)
    {
        $task_type = $this->get_task_type($task_type);
        if ($task_type !== null) {
            // Filter only by the specified type
            return function($table) use ($task_type) { return "AND $table.`TASK_TYPE` LIKE '$task_type'"; };
        } else {
            if ($filter_null === true) {
                // Filter type is null
                return function($table) use ($task_type) { return "AND $table.`TASK_TYPE` IS NULL"; };
            } else {
                // Empty filter
                // (instead of filtering by null type, avoid this condition)
                return function($table) use ($task_type) { return ""; };
            }
        }
    }

    /**
     * Calculates the DBSCAN.
     */
    public function get_dbscan($jobid, $metric_x, $metric_y, $task_type, $eps = null, $minPoints = null)
    {
        $query_select1 = $this->get_task_metric_query($this::$TASK_METRICS[$metric_x]);
        $query_select2 = $this->get_task_metric_query($this::$TASK_METRICS[$metric_y]);
        $task_type_select = $this->get_task_type_query($task_type);
        $query = "
            SELECT
                t.`TASKID` as TASK_ID,
                ".$query_select1('t')." as TASK_VALUE_X,
                ".$query_select2('t')." as TASK_VALUE_Y
            FROM `JOB_tasks` t
            WHERE t.`JOBID` = :jobid
            ".$task_type_select('t')."
            ORDER BY t.`TASKID`
        ;";
        $query_params = array(":jobid" => $jobid);

        $rows = $this->get_rows($query, $query_params);

        $points = new Cluster();  // Used instead of a simple array to calc x/y min/max
        foreach ($rows as $row) {
            $task_id = $row['TASK_ID'];
            $task_value_x = $row['TASK_VALUE_X'] ?: 0;
            $task_value_y = $row['TASK_VALUE_Y'] ?: 0;

            // Show only task id (not the whole string)
            $task_id = substr($task_id, 23);

            $points[] = new Point($task_value_x, $task_value_y, array('task_id' => $task_id));
        }

        $dbscan = new DBSCAN($eps, $minPoints);
        $dbscan->execute((array)$points);

        // If heuristic was used, cache results in database
        if ($eps === null && $minPoints === null) {
            $this->add_dbscan($jobid, $metric_x, $metric_y, $task_type, $dbscan->getClusters());
        }

        return $dbscan;
    }

    /**
     * Adds the clusters of the DBSCAN result to the database. Does NOT replace
     * existing ones.
     */
    public function add_dbscan($jobid, $metric_x, $metric_y, $task_type, $clusters)
    {
        // If DBSCAN result is empty, don't do anything
        if (empty($clusters)) {
            return;
        }

        list($bench, $job_offset, $id_exec) = $this->get_jobid_info($jobid);
        $task_type_select = $this->get_task_type_query($task_type, $filter_null=true);

        // Start transaction
        // We need this here because we are going to SELECT some data to check
        // if exists, and if not INSERT it to the database
        // Also, the first SELECT has a "LOCK IN SHARE MODE"
        $this->dbConn->beginTransaction();

        // Check if clusters already exist for this jobid
        $query = "
            SELECT COUNT(*) as COUNT
            FROM `JOB_dbscan`
            WHERE
                `bench` = :bench AND
                `job_offset` = :job_offset AND
                `metric_x` = :metric_x AND
                `metric_y` = :metric_y AND
                `id_exec` = :id_exec
                ".$task_type_select('JOB_dbscan')."
            LOCK IN SHARE MODE
        ;";
        $query_params = array(
            ":bench" => $bench,
            ":job_offset" => $job_offset,
            ":metric_x" => $metric_x,
            ":metric_y" => $metric_y,
            ":id_exec" => $id_exec
        );
        $sth = $this->dbConn->prepare($query);
        $sth->execute($query_params);
        if ($sth->fetchAll(\PDO::FETCH_ASSOC)[0]["COUNT"] > 0) {
            // End transaction (INSERT not needed)
            $this->dbConn->commit();
            return;
        }

        // Insert new clusters
        $this->insert_dbscan($bench, $job_offset, $id_exec, $metric_x, $metric_y, $task_type, $clusters);

        // End transaction (outside of que SELECT + INSERT block)
        $this->dbConn->commit();
    }

    /**
     * Retrieve info about jobid.
     *
     * Returns the bench, job_offset and id_exec of the specified jobid.
     *
     * The job_offset is defined as the last string after _
     * Example: job_201402172244_0002 -> 0002
     */
    public function get_jobid_info($jobid)
    {
        $query = "
            SELECT
                e.`bench`,
                e.`id_exec`
            FROM
                `JOB_details` d,
                `execs` e
            WHERE
                e.`id_exec` = d.`id_exec` AND
                d.`JOBID` = :jobid
        ;";
        $query_params = array(":jobid" => $jobid);

        $rows = $this->get_rows($query, $query_params);

        $bench = $rows[0]["bench"];
        $id_exec = $rows[0]["id_exec"];

        $job_offset = explode('_', $jobid);
        $job_offset = end($job_offset);

        return array($bench, $job_offset, $id_exec);
    }

    /**
     * Finds all the executions related to the $bench and $job_offset that
     * don't have dbscanexecs results calculated yet.
     *
     * Returns a list containing arrays with 'bench', 'id_exec' and 'jobid'.
     */
    public function get_dbscanexecs_pending($bench, $job_offset, $metric_x, $metric_y, $task_type, $where_configs = null)
    {
        $task_type_select = $this->get_task_type_query($task_type, $filter_null=true);
        $query = "
            SELECT
                e.`bench`,
                d.`id_exec`,
                d.`JOBID` as jobid
            FROM `JOB_details` d

            JOIN `execs` e
            ON e.`id_exec` = d.`id_exec`

            LEFT OUTER JOIN `JOB_dbscan` s
            ON
                e.`bench` = s.`bench` AND
                s.`metric_x` = :metric_x AND
                s.`metric_y` = :metric_y AND
                d.`id_exec` = s.`id_exec`
                ".$task_type_select('s')."

            LEFT OUTER JOIN `JOB_tasks` t
            ON
                d.`JOBID` = t.`JOBID`
                ".$task_type_select('t')."
                $where_configs

            WHERE e.`bench` = :bench
            AND d.`JOBID` LIKE :job_offset
            AND s.`id` IS null
            AND t.`JOBID` IS NOT null
            GROUP BY e.`bench`, d.`id_exec`, d.`JOBID`
            ORDER BY d.`id_exec`
        ;";
        $query_params = array(
            ":bench" => $bench,
            ":job_offset" => "%_$job_offset",
            ":metric_x" => $metric_x,
            ":metric_y" => $metric_y
        );

        // Done manually to bypass cache
        $sth = $this->dbConn->prepare($query);
        $sth->execute($query_params);
        $rows = $sth->fetchAll(\PDO::FETCH_ASSOC);

        return $rows;
    }

    /**
     * Save DBSCAN to database.
     *
     * Warning: doesn't check for duplicates neither removes previous clusters.
     */
    private function insert_dbscan($bench, $job_offset, $id_exec, $metric_x, $metric_y, $task_type, $clusters)
    {
        $columns = ["`bench`", "`job_offset`", "`metric_x`", "`metric_y`", "`TASK_TYPE`", "`id_exec`", "`centroid_x`", "`centroid_y`"];

        $query_params = [];
        foreach ($clusters as $cluster) {
            $query_params[] = $bench;
            $query_params[] = $job_offset;
            $query_params[] = $metric_x;
            $query_params[] = $metric_y;
            $query_params[] = $task_type;
            $query_params[] = $id_exec;
            $query_params[] = $cluster->getCentroid()->x;
            $query_params[] = $cluster->getCentroid()->y;
        }

        $query_values = implode(', ', array_fill(0, count($clusters), '('.str_pad('', (count($columns)*2)-1, '?,').')'));
        $query = "
            INSERT INTO
                `JOB_dbscan` (".implode(',', $columns).")
            VALUES
                $query_values
        ;";

        $sth = $this->dbConn->prepare($query);
        $sth->execute($query_params);
    }
}
