#!/bin/bash
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#echo "$CUR_DIR"


#TABLE MANIPULATION
MYSQL_ARGS="-u vagrant -paaa -h host --local-infile -f -b --show-warnings " #--show-warnings -B
DB="aloja"
MYSQL="mysql $MYSQL_ARGS $DB -e "
BASE_TABLES="$1"
TRUNCATE_AFTER="$2"
DROP_TABLES=""

if [ "$BASE_TABLES" == "1" ] ; then

  echo "Creating and loading execs_dump from table_db.csv"
  bash "$CUR_DIR/load_csv.sh" table_db.csv execs_dump #drop

  if [ "$DROP_TABLES" == "1" ] ; then
    echo "Dropping table execs"
    $MYSQL "drop table execs;"
  fi

  echo "Creating and altering table for execs"
  $MYSQL "
  CREATE table if not exists execs like execs_dump;

  ALTER IGNORE TABLE \`execs\`
  ADD COLUMN \`id_exec\` INT NOT NULL AUTO_INCREMENT FIRST,
  ADD COLUMN \`id_cluster\` INT NULL DEFAULT 1 AFTER \`id_exec\`,
  CHANGE COLUMN \`exe_time\` \`exe_time\` DECIMAL(20,3) NULL DEFAULT NULL,
  CHANGE COLUMN \`end_time\` \`init_time\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`maps\` \`maps\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`iosf\` \`iosf\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`replication\` \`replication\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`iofilebuf\` \`iofilebuf\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`comp\` \`comp\` INT NULL DEFAULT NULL  ,
  CHANGE COLUMN \`blk_size\` \`blk_size\` INT NULL DEFAULT NULL,
  ADD PRIMARY KEY (\`id_exec\`),
  DROP INDEX index1,
  ADD UNIQUE INDEX \`exec_UNIQUE\` (\`exec\` ASC),
  ADD INDEX \`index1\` (\`id_cluster\` ASC),
  ENGINE = InnoDB;

  "
  echo "Inserting execs"
  $MYSQL "insert ignore into \`execs\` select null, 1, t.* from execs_dump t WHERE exec NOT in (select distinct(exec) from execs);"

  table_exists=$($MYSQL "show tables like 'clusters';" )
  if [[ -z $table_exists ]] ; then
    echo "Create clusters table (if not exists) and insert"
    $MYSQL "create table if not exists aloja2.clusters  (id_cluster int, name varchar(127), cost_hour decimal(10,3), `type` varchar(127), link varchar(255), primary key (id_cluster)) engine InnoDB;
    insert into aloja2.clusters  set name='Local 1', id_cluster=1, cost_hour=12, type='Colocated', link='http://aloja.bsc.es/?page_id=51';
    insert into aloja2.clusters  set name='Azure Linux', id_cluster=2, cost_hour=7, type='IaaS Cloud', link='http://www.windowsazure.com/en-us/pricing/calculator/';"
  fi

  echo "Updating cluster in execs"
  $MYSQL  "update execs set id_cluster = 2 where locate('_az', exec) > 1;"

  table_exists=$($MYSQL "show tables like 'hosts';" )
  if [[ -z $table_exists ]] ; then
    echo "Create hosts table (if not exists) and insert"
    $MYSQL "create table if not exists hosts (
    id_host int(11) NOT NULL AUTO_INCREMENT,
    host_name varchar(128) NOT NULL,
    id_cluster int(11) NOT NULL,
    role varchar(45) DEFAULT NULL,
    PRIMARY KEY (id_host)
    ) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
    insert into hosts set id_host=null, id_cluster=1, host_name='minerva-1001', role='master';
    insert into hosts set id_host=null, id_cluster=1, host_name='minerva-1002', role='slave';
    insert into hosts set id_host=null, id_cluster=1, host_name='minerva-1003', role='slave';
    insert into hosts set id_host=null, id_cluster=1, host_name='minerva-1004', role='slave';
    insert into hosts set id_host=null, id_cluster=2, host_name='al-1001', role='master';
    insert into hosts set id_host=null, id_cluster=2, host_name='al-1002', role='slave';
    insert into hosts set id_host=null, id_cluster=2, host_name='al-1003', role='slave';
    insert into hosts set id_host=null, id_cluster=2, host_name='al-1004', role='slave';
    "
  fi

fi

decimal_fields=""
get_decimal_fields() {
  decimal_fields=""

  if   [ "$1" == "SAR_cpu" ] ; then
    decimal_fields="%user %nice %system %iowait %steal %idle"
  elif [ "$1" == "SAR_interrupts" ] ; then
      decimal_fields="intr/s"
  elif [ "$1" == "SAR_io_paging" ] ; then
      decimal_fields="pgpgin/s pgpgout/s fault/s majflt/s pgfree/s pgscank/s pgscand/s pgsteal/s %vmeff"
  elif [ "$1" == "SAR_load" ] ; then
      decimal_fields="runq-sz plist-sz ldavg-1 ldavg-5 ldavg-15 blocked"
  elif [ "$1" == "SAR_memory" ] ; then
      decimal_fields="frmpg/s bufpg/s campg/s"
  elif [ "$1" == "SAR_memory_util" ] ; then
      decimal_fields="kbmemfree kbmemused %memused kbbuffers kbcached kbcommit %commit kbactive kbinact kbdirty"
  elif [ "$1" == "SAR_swap" ] ; then
      decimal_fields="kbswpfree kbswpused %swpused kbswpcad %swpcad"
  elif [ "$1" == "SAR_swap_util" ] ; then
      decimal_fields="pswpin/s pswpout/s"
  elif [ "$1" == "SAR_switches" ] ; then
      decimal_fields="proc/s cswch/s"
  elif [ "$1" == "JOB_job_history" ] ; then
      decimal_fields="time maps shuffle merge reduce waste"
  elif [ "$1" == "JOB_task_history" ] ; then
      decimal_fields="reduce_output_bytes shuffle_finish reduce_finish"
  elif [ "$1" == "JOB_COUNTERS" ] ; then
      decimal_fields="BYTES_READ SLOTS_MILLIS_MAPS FALLOW_SLOTS_MILLIS_REDUCES FALLOW_SLOTS_MILLIS_MAPS TOTAL_LAUNCHED_MAPS SLOTS_MILLIS_REDUCES BYTES_WRITTEN HDFS_BYTES_READ FILE_BYTES_WRITTEN HDFS_BYTES_WRITTEN MAP_INPUT_RECORDS PHYSICAL_MEMORY_BYTES SPILLED_RECORDS COMMITTED_HEAP_BYTES CPU_MILLISECONDS MAP_INPUT_BYTES VIRTUAL_MEMORY_BYTES SPLIT_RAW_BYTES MAP_OUTPUT_RECORDS"
  elif [ "$1" == "JOB_MAP_COUNTERS" ] ; then
      decimal_fields="BYTES_READ BYTES_WRITTEN HDFS_BYTES_READ FILE_BYTES_WRITTEN HDFS_BYTES_WRITTEN MAP_INPUT_RECORDS PHYSICAL_MEMORY_BYTES SPILLED_RECORDS COMMITTED_HEAP_BYTES CPU_MILLISECONDS MAP_INPUT_BYTES VIRTUAL_MEMORY_BYTES SPLIT_RAW_BYTES MAP_OUTPUT_RECORDS"
  elif [ "$1" == "JOB_REDUCE_COUNTERS" ] ; then
      decimal_fields="BYTES_WRITTEN FILE_BYTES_READ FILE_BYTES_WRITTEN HDFS_BYTES_WRITTEN REDUCE_INPUT_GROUPS COMBINE_OUTPUT_RECORDS REDUCE_SHUFFLE_BYTES PHYSICAL_MEMORY_BYTES REDUCE_OUTPUT_RECORDS SPILLED_RECORDS COMMITTED_HEAP_BYTES CPU_MILLISECONDS VIRTUAL_MEMORY_BYTES COMBINE_INPUT_RECORDS REDUCE_INPUT_RECORDS"
  elif [ "$1" == "JOB_SUMMARY_COUNTERS" ] ; then
      decimal_fields="FINISH_TIME FINISHED_MAPS FINISHED_REDUCES FAILED_MAPS FAILED_REDUCES"
  elif [ "$1" == "VMSTATS" ] ; then
      decimal_fields="r b swpd free buff cache si so bi bo in cs us sy id wa"
  elif [ "$1" == "BMW" ] ; then
      decimal_fields="bytes_out bytes_in bytes_total packets_out packets_in packets_total errors_out errors_in"
  elif [ "$1" == "SAR_block_devices" ] ; then
      decimal_fields="interval tps rd_sec/s wr_sec/s avgrq-sz avgqu-sz await svctm %util"
  elif [ "$1" == "SAR_net_devices" ] ; then
      decimal_fields="interval rxpck/s txpck/s rxkB/s txkB/s rxcmp/s txcmp/s rxmcst/s"
  elif [ "$1" == "SAR_net_errors" ] ; then
      decimal_fields="interval rxerr/s txerr/s coll/s rxdrop/s txdrop/s txcarr/s rxfram/s rxfifo/s txfifo/s"
  elif [ "$1" == "SAR_net_sockets" ] ; then
      decimal_fields="interval totsck tcpsck udpsck rawsck ip-frag tcp-tw"
  elif [ "$1" == "SAR_io_rate" ] ; then
      decimal_fields="interval tps rtps wtps bread/s bwrtn/s"
  fi
}

has_date=""
get_has_date() {
  has_date=""
  if [ "$1" == "SAR_cpu" ] || [ "$1" == "SAR_interrupts" ] || [ "$1" == "SAR_io_paging" ] || [ "$1" == "SAR_load" ] || [ "$1" == "SAR_memory" ] || [ "$1" == "SAR_memory_util" ] || [ "$1" == "SAR_swap" ] || [ "$1" == "SAR_swap_util" ] || [ "$1" == "SAR_switches" ] ; then
      has_date="1"
  fi
}

#"SAR_cpu" "SAR_interrupts" "SAR_io_paging" "SAR_load" "SAR_memory" "SAR_memory_util" "SAR_swap" "SAR_swap_util" "SAR_switches" "JOB_job_history" "JOB_task_history" "JOB_job_history" "JOB_task_history" "JOB_COUNTERS"  "JOB_MAP_COUNTERS"  "JOB_REDUCE_COUNTERS"  "JOB_SUMMARY" "VMSTATS" "BWM" "SAR_block_devices" "SAR_net_devices" "SAR_io_rate" "SAR_net_errors"
for table_name in "SAR_cpu" "SAR_interrupts" "SAR_io_paging" "SAR_load" "SAR_memory" "SAR_memory_util" "SAR_swap" "SAR_swap_util" "SAR_switches" "JOB_job_history" "JOB_task_history" "JOB_job_history" "JOB_task_history" "JOB_COUNTERS"  "JOB_MAP_COUNTERS"  "JOB_REDUCE_COUNTERS"  "JOB_SUMMARY" "VMSTATS" "BWM" "SAR_block_devices" "SAR_net_devices" "SAR_io_rate" "SAR_net_errors" ; do # "JOB_job_history" "JOB_task_history" "JOB_COUNTERS"  "JOB_MAP_COUNTERS"  "JOB_REDUCE_COUNTERS"  "JOB_SUMMARY" "VMSTATS" "BWM"

  if [ "$DROP_TABLES" == "1" ] ; then
    echo "Dropping table ${table_name}"
    $MYSQL "drop table if exists ${table_name};"
  fi

  table_exists=$($MYSQL "show tables like '$table_name';" )
  if [[ -z $table_exists ]] ; then

    echo "Creating (if not exists) and altering table for ${table_name}"

    $MYSQL "CREATE table if not exists ${table_name} like ${table_name}_dump;
    ALTER IGNORE TABLE \`${table_name}\`
    ADD COLUMN \`id_${table_name}\` INT NOT NULL AUTO_INCREMENT FIRST,
    ADD PRIMARY KEY (\`id_${table_name}\`),
    ADD COLUMN \`id_exec\` INT AFTER \`id_${table_name}\`,
    #ADD INDEX \`index1\` (\`exec\` ASC),
    ADD INDEX \`index2\` (\`id_exec\` ASC),
    ENGINE = InnoDB; "

    get_decimal_fields "$table_name"
    get_has_date "$table_name"

    if [ "$decimal_fields" != "" ] ; then
      echo "Executing custom alters for ${table_name}"
      alters=""
      for field in $decimal_fields ; do
        alters="$alters
        CHANGE COLUMN \`$field\` \`$field\` DECIMAL(20,3) NULL DEFAULT NULL,"
      done

      if [ "$has_date" == "1" ] ; then
        alters="$alters
        CHANGE COLUMN \`date\` \`date\` DATETIME NULL DEFAULT NULL ,
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`date\` ASC),
        ADD INDEX \`index3\` (\`host\` ASC),"
      fi

      if [ "$table_name" == "JOB_job_history" ] ; then
        alters="$alters
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`job_name\`,\`time\` ASC),
        ADD INDEX \`index_job_name\` (\`job_name\` ASC),"
      elif [ "$table_name" == "JOB_task_history" ] ; then
        alters="$alters
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`job_name\`,\`task_name\` ASC),
        ADD INDEX \`index_job_name\` (\`job_name\` ASC),"
      elif [ "$table_name" == "JOB_COUNTERS" ] || [ "$table_name" == "JOB_MAP_COUNTERS" ] || [ "$table_name" == "JOB_REDUCE_COUNTERS" ] || [ "$table_name" == "JOB_SUMMARY" ] ; then
        alters="$alters
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`job_name\` ASC),"
      elif [ "$table_name" == "VMSTATS" ]  ; then
        alters="$alters
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`time\` ASC),"
      elif [ "$table_name" == "BWM" ]  ; then
        alters="$alters
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`iface_name\`,\`time\` ASC),"
      ## Start SAR new format
      elif [ "$table_name" == "SAR_block_devices" ] || [ "$table_name" == "SAR_net_errors" ]  ; then
        alters="$alters
        CHANGE COLUMN \`timestamp\` \`date\` DATETIME NULL DEFAULT NULL ,
        CHANGE COLUMN \`hostname\` \`host\` VARCHAR(128) NULL DEFAULT NULL ,
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`date\`,\`DEV\` ASC),"
      elif [ "$table_name" == "SAR_net_devices" ]  ; then
        alters="$alters
        CHANGE COLUMN \`timestamp\` \`date\` DATETIME NULL DEFAULT NULL ,
        CHANGE COLUMN \`hostname\` \`host\` VARCHAR(128) NULL DEFAULT NULL ,
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`date\`,\`IFACE\` ASC),"
      elif [ "$table_name" == "SAR_io_rate" ] || [ "$table_name" == "SAR_net_sockets" ] ; then
        alters="$alters
        CHANGE COLUMN \`timestamp\` \`date\` DATETIME NULL DEFAULT NULL ,
        CHANGE COLUMN \`hostname\` \`host\` VARCHAR(128) NULL DEFAULT NULL ,
        ADD UNIQUE INDEX \`avoid_duplicates_UNIQUE\` (\`exec\`,\`host\`,\`date\` ASC),"
      fi

      alters="${alters:0:-1}"
      $MYSQL "ALTER TABLE \`${table_name}\` $alters; "
    fi
  fi #table exists

  echo "Inserting ${table_name}"
  $MYSQL "insert ignore into \`${table_name}\` select null, null, t.* from ${table_name}_dump t where exec not IN (select distinct(exec) from ${table_name}) limit 20000000,20000000;"
  #$MYSQL "insert ignore into \`${table_name}\` select null, null, t.* from ${table_name}_dump t limit 1000;"
  echo "Updating ${table_name}"
  $MYSQL "update ${table_name} s set id_exec = (select id_exec from execs where exec = s.exec) where id_exec is null;"

  if [ "$TRUNCATE_AFTER" == "1" ] ; then
    echo "truncating ${table_name}_dump"
    $MYSQL "TRUNCATE ${table_name}_dump;"
  fi

done
