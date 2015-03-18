#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

logger "Starting ALOJA DB create/update script"

logger "Creating tables, applying alters, updating data..."

source "$CUR_DIR/common/create_db.sh"

logger "Updating clusters and hosts"

for clusterConfigFile in $configFolderPath/cluster_* ; do

  id_cluster="${clusterConfigFile:(-7):2}"
  logger "INFO: loading $clusterConfigFile with ID $id_cluster"

  #TODO this check wont work for old folders with numeric values at the end, need another strategy
  #line to fix update execs set id_cluster=1 where id_cluster IN (28,32,56,64);
  if [ -f "$clusterConfigFile" ] && [[ $id_cluster =~ ^-?[0-9]+$ ]] ; then
    sql_tmp="$(get_insert_cluster_sql "$id_cluster" "$clusterConfigFile")"
    echo "Executing $sql_tmp"
    $MYSQL "$sql_tmp"
  fi

done

#Before updating filters values

echo "update execs set bench='terasort' where bench='TeraSort' and id_cluster IN (20,23,24,25);
update execs set bench='prep_wordcount' where bench='random-text-writer' and id_cluster IN (20,23,24,25);
update execs set bench='prep_terasort' where bench='TeraGen' and id_cluster IN (20,23,24,25);"

$MYSQL  "
update ignore execs SET filter = 0;
update ignore execs SET perf_details = 1;
update ignore execs SET perf_details = 0 where id_exec NOT IN(select distinct (id_exec) from JOB_status where id_exec is not null);
update ignore execs SET perf_details = 0 where id_exec NOT IN(select distinct (id_exec) from SAR_cpu where id_exec is not null);

update ignore execs SET valid = 1;
update ignore execs SET valid = 0 where bench_type = 'HiBench' and bench = 'terasort' and id_exec NOT IN (
  select distinct(id_exec) from
    (select b.id_exec from execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore execs SET valid = 1 where bench_type = 'HiBench' and bench = 'sort' and id_exec IN (
  select distinct(id_exec) from
    (select b.id_exec from execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'sort' and HDFS_BYTES_WRITTEN between '73910080224' and '73910985034')
    tmp_table
);

update ignore execs e INNER JOIN (SELECT id_exec,SUM(js.reduce) as 'suma' FROM execs e2 JOIN JOB_status js USING (id_exec) WHERE e2.bench NOT LIKE 'prep%' GROUP BY id_exec) i ON e.id_exec = i.id_exec SET perf_details = 0 WHERE suma = 0;
"
