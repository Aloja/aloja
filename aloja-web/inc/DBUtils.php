<?php

namespace alojaweb\inc;

class DBUtils
{
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

    public function get_rows($sql)
    {
        $md5_sql = md5($sql);
        $file_path = "{$this->container['config']['db_cache_path']}/CACHE_$md5_sql.sql";

        if ($this->container['env'] == 'dev' || $_SERVER['HTTP_HOST'] == 'localhost' || (isset($_GET['NO_CACHE']) && strlen($_GET['NO_CACHE']) > 0)) {
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
            $this->container['log']->addDebug('CACHED: '.$sql);
        } else {
            if (!$this->dbConn) $this->init();

            $this->container['log']->addDebug('NO CACHE: '.$sql);

            try {
                $sth = $this->dbConn->prepare($sql);
                $sth->execute();
            } catch (Exception $e) {
                throw new \Exception($e->getMessage(). " SQL: $sql");
            }

            $rows = $sth->fetchAll(\PDO::FETCH_ASSOC);

            //save cache
            if ($rows) {
                file_put_contents($file_path, gzcompress(serialize($rows), 9));
            }
        }

        return $rows;
    }

    public function get_execs($filter_execs = null)
    {
        if($filter_execs === null)
            $filter_execs = "AND exe_time > 200 AND (id_cluster = 1 OR (bench != 'bayes' AND id_cluster=2))";

        $query = "SELECT e.*, (exe_time/3600)*(cost_hour) cost  FROM execs e
        join clusters USING (id_cluster)
        WHERE 1 $filter_execs
        AND id_exec IN (select distinct (id_exec) from SAR_cpu where id_exec is not null and host not like '%-1001');
        ";

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
}
