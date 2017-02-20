#HBASE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

#Zookeeper
#source_file "$ALOJA_REPO_PATH/shell/common/common_zookeeper.sh"
#set_zookeeper_requires


# Sets the required files to download/copy
set_hbase_requires() {
  [ ! "$HBASE_VERSION" ] && die "No HBASE_VERSION specified"

  #if [ "$clusterType" != "PaaS" ]; then
    if [ "$(get_hadoop_major_version)" == "2" ]; then
      HBASE_FOLDER="hbase-${HBASE_VERSION}"
      BENCH_REQUIRED_FILES["$HBASE_FOLDER"]="http://www-eu.apache.org/dist/hbase/$HBASE_VERSION/$HBASE_FOLDER-bin.tar.gz"
    else
      HBASE_FOLDER="hbase-${HBASE_VERSION}-hadoop1"
      BENCH_REQUIRED_FILES["$HBASE_FOLDER"]="http://www-eu.apache.org/dist/hbase/$HBASE_VERSION/$HBASE_FOLDER-bin.tar.gz"
    fi
  #fi
  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${HBASE_FOLDER}_conf_template"
}

# Helper to print a line with requiered exports
get_hbase_exports() {
  local to_export

  #if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  #else
    to_export="
export HBASE_CONF_DIR=$HBASE_CONF_DIR
"
    echo -e "$to_export\n"
  #fi
}

# Returns the the path to the hbase binary with the proper exports
get_hbase_cmd() {
  local hbase_exports
  local hbase_cmd

  #if [ "$clusterType" == "PaaS" ]; then
  #  hbase_exports=""
  #  hbase_bin="hbase"
  #else
    hbase_exports="$(get_hbase_exports)"
    hbase_bin="$HBASE_HOME/bin/"
  #fi
  hbase_cmd="$hbase_exports\n$hbase_bin"

  echo -e "$hbase_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_hbase(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local hbase_cmd

  hbase_cmd="$(get_hbase_cmd)$cmd"

  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity before" "${chdir}$(get_hadoop_cmd) fs -df"
  fi

  # Run the command and time it
  execute_master "$bench" "$hbase_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity after" "${chdir}$(get_hadoop_cmd) fs -df"
    save_hbase "$bench"
  fi
}

# Runs hbase directly for auxiliary commands (allows to capture stderr)
# $1 command
execute_hbase_direct(){
  local cmd="$1"
  local hbase_cmd

  hbase_cmd="$(get_hbase_cmd)$cmd"

  # Run the command and time it
  $DSH_MASTER "$hbase_cmd"
}

# Manages stopping HBase logic
# $1 force stop, for use at restart (useful for -S)
stop_hbase() {
  local force_stop="$1"

  if [ "$clusterType=" != "PaaS" ] && [[ ! "$BENCH_LEAVE_SERVICES" || "$force_stop" ]] && [[ "$DELETE_HDFS" == "1" || "$force_stop" ]] ; then
    logger "INFO: Stopping HBase"
    $DSH_MASTER "export HBASE_CONF_DIR=$HBASE_CONF_DIR && export JAVA_HOME=$(get_java_home) && $HBASE_HOME/bin/stop-hbase.sh"

    if [ "$HBASE_CACHE" ] ; then
      log_WARN "Cleaning up the bucket cache to free space"
      $DSH "[ -f '$HBASE_CACHE' ] && { ls -la '$HBASE_CACHE'; rm -rf '$HBASE_CACHE'; }"
    fi

    log_WARN "Sleeping 30 seconds to work around buggy HBase script"
    sleep 30

  elif [ "$clusterType=" == "PaaS" ] ; then
    log_WARN "In PaaS mode, not stopping HBase."
    #hadoop_kill_jobs
  else
    log_WARN "Not stopping HBase (as requested with -S or -N)."
    #hadoop_kill_jobs
  fi
}

start_hbase() {
  # In case we leave services, we don't stop it unless there is a bucket cache config
  if [[ "true" || "$BENCH_LEAVE_SERVICES" || "$HBASE_CACHE" ]] ; then
    stop_hbase "force"
  # Normal case
  else
    stop_hbase ""
  fi

  #Start Hbase
  logger "INFO: Starting HBase"
  #if [ "$clusterType" == "PaaS" ]; then
  #  :
  #else
    # First, make sure we stop hbase on abnormal exit
    update_traps "stop_hbase;" "update_logger"

    $DSH_MASTER "export HBASE_CONF_DIR=$HBASE_CONF_DIR && export JAVA_HOME=$(get_java_home) && $HBASE_HOME/bin/start-hbase.sh"
  #fi

  log_WARN "Sleeping 15 seconds to allow HBase (zookeper) to fully initialize"
  sleep 15
}
initialize_hbase_vars() {

  #if [ "$clusterType" == "PaaS" ]; then
  #  HBASE_HOME="/usr"
  #  HBASE_CONF_DIR="/etc/hbase/conf"
  #else
    HBASE_HOME="$(get_local_apps_path)/${HBASE_FOLDER}"
    HBASE_CONF_DIR="$(get_hbase_conf_dir)"
  #fi
}

# Sets the substitution values for the Hbase config
get_hbase_substitutions() {

  local node_names="$(get_node_names)"
  local servers=''
  local region_servers=''
  local backup_server=''
  local count=0
  local cache=

  for node in $node_names ; do

    if [ "$count" == 0 ]; then
      servers+="${node}"
    else
      servers+=",${node}"
      if [ "$count" == 1 ]; then
        backup_server="${node}"
        region_servers+="${node}\n"
      else
        region_servers+="${node}\n"
      fi
    fi
    count=$((count+1))
  done

#<property>
#  <name>hfile.block.cache.size</name>
#  <value>0.2</value>
#</property>

  local HBASE_MAX_DIRECT_MEMORY # for onheap bucket cache ioengine

  local HBASE_BLOCKCACHE_SIZE="0.4" #default

  if [ "${HBASE_CACHE}" != "" ] || [ "$HBASE_IOENGINE" ]; then
    local bucket_size="$HBASE_BUCKETCACHE_SIZE"

    # Off heap to file (default)
    local ioengine="file:${HBASE_CACHE}"

    if [ "$HBASE_IOENGINE" ] ; then
      ioengine="$HBASE_IOENGINE"
      HBASE_MAX_DIRECT_MEMORY="$(( HBASE_BUCKETCACHE_SIZE + 1024 ))m"
      if [ "$HBASE_IOENGINE" == "heap" ] ; then
        HBASE_BLOCKCACHE_SIZE="0.2"
        bucket_size="0.2"
      fi
    fi

    cache="<property>
  <name>hbase.bucketcache.ioengine</name>
  <value>${ioengine}</value>
</property>
  <property>
  <name>hbase.bucketcache.size</name>
  <value>${bucket_size}</value>
</property>
<property>
  <name>hbase.bucketcache.combinedcache.enabled</name>
  <value>true</value>
</property>
<property>
  <name>hfile.block.cache.size</name>
  <value>${HBASE_BLOCKCACHE_SIZE}</value>
</property>
"
  fi

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$(get_local_bench_path)/hbase_logs,g;
s,##REPLICATION##,$REPLICATION,g;
s,##MASTER##,$master_name,g;
s,##NAMENODE##,$master_name,g;
s,##TMP_DIR##,$HDD_TMP,g;
s,##HDFS_NDIR##,$HDFS_NDIR,g;
s,##HDFS_DDIR##,$HDFS_DDIR,g;
s,##MAX_MAPS##,$MAX_MAPS,g;
s,##MAX_REDS##,$MAX_REDS,g;
s,##IFACE##,$IFACE,g;
s,##IO_FACTOR##,$IO_FACTOR,g;
s,##IO_MB##,$IO_MB,g;
s,##PORT_PREFIX##,$PORT_PREFIX,g;
s,##IO_FILE##,$IO_FILE,g;
s,##BLOCK_SIZE##,$BLOCK_SIZE,g;
s,##PHYS_MEM##,$PHYS_MEM,g;
s,##NUM_CORES##,$NUM_CORES,g;
s,##CONTAINER_MIN_MB##,$CONTAINER_MIN_MB,g;
s,##CONTAINER_MAX_MB##,$CONTAINER_MAX_MB,g;
s,##MAPS_MB##,$MAPS_MB,g;
s,##REDUCES_MB##,$REDUCES_MB,g;
s,##AM_MB##,$AM_MB,g;
s,##BENCH_LOCAL_DIR##,$BENCH_LOCAL_DIR,g;
s,##HDD##,$(get_local_bench_path),g;
s~##SERVERS##~$servers~g;
s,##REGION_SERVERS##,$region_servers,g;
s,##BACKUP_SERVER##,$backup_server,g;
s,##HBASE_MANAGES_ZK##,$HBASE_MANAGES_ZK,g;
s,##HBASE_CACHE##,$cache,g;
s,##HBASE_ROOT_DIR##,$HBASE_ROOT_DIR,g;
s,##HBASE_IOENGINE##,$HBASE_IOENGINE,g;
s,##HBASE_MAX_DIRECT_MEMORY##,$HBASE_MAX_DIRECT_MEMORY,g;
EOF
}

get_hbase_conf_dir() {
  echo -e "$(get_local_bench_path)/hbase_conf"
}

prepare_hbase_config() {
  logger "INFO: Preparing hbase run specific config"
  #if [ "$clusterType" == "PaaS" ]; then
  #  : # Empty
  #else
    $DSH "mkdir -p $HBASE_CONF_DIR && cp -r $(get_local_configs_path)/${HBASE_FOLDER}_conf_template/* $HBASE_CONF_DIR/"
    subs=$(get_hbase_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $HBASE_CONF_DIR/*"
  #fi
}

# $1 bench name
save_hbase() {

  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create the hive logs dir
  $DSH "mkdir -p $JOB_PATH/$bench_name_num/hbase_logs;"

  # Save hbase logs
  #if [ "$clusterType" == "PaaS" ]; then
  #  : #
    # Save HBase conf
    # $DSH_MASTER "cd /etc/hive; tar -cjf $JOB_PATH/hive_conf.tar.bz2 conf"
  #else
    if [ "$BENCH_LEAVE_SERVICES" ] ; then
      $DSH "cp $HDD/hbase_logs/* $JOB_PATH/$bench_name_num/hbase_logs/ 2> /dev/null"
    else
      $DSH "mv $HDD/hbase_logs/* $JOB_PATH/$bench_name_num/hbase_logs/ 2> /dev/null"
    fi

    # Save HBase conf
    $DSH_MASTER "cd $HDD/; tar -cjf $JOB_PATH/hbase_conf.tar.bz2 hbase_conf"
  #fi

  logger "INFO: Compressing and deleting hadoop configs for $bench_name_num"

  $DSH_MASTER "

cd $JOB_PATH;
if [ \"\$(ls conf_* 2> /dev/null)\" ] ; then
  tar -cjf $JOB_PATH/hadoop_host_conf.tar.bz2 conf_*;
  rm -rf conf_*;
fi
"
  # save hadoop and defaults
  save_hadoop "$bench_name"
}

# Count the number of records generated and compares them to the expected count
# $1 table (optional)
# $2 expected count (optional)
# $3 exception level (ERROR will exit the run)
test_data_size(){
log_WARN "Testing data size DISABLED to save time"
return
  local table="${1:-usertable}"
  local expected_count="$2"
  local exception_level="${3:-WARNING}"

  log_INFO "Testing data size of generated data"

  local count_output="$(execute_hbase_direct "hbase shell -n <<< \"count \\\"$table\\\", INTERVAL => 1000000, CACHE => 1000000;\" 2>&1")"
  local count="$(echo -e "$count_output"|grep 'Current count:'|awk 'END{print substr($3,1,length($3)-1)}')"

  if [ "$BENCH_DATA_SIZE" != "$count" ] ; then
    if [ "$exception_level" == "ERROR" ] ; then
      die "Number of rows in the $table table is: $count but expected: $BENCH_DATA_SIZE. Exiting..."
    else
      logger "$exception_level Number of rows in the $table table is: $count but expected: $BENCH_DATA_SIZE."
    fi
  else
    log_INFO "Number of rows in the $table table is: $count as expected."
  fi
}

clean_hbase() {
  if [ "$HBASE_CACHE" ] ; then
    log_WARN "Cleaning up the bucket cache to free space"
    $DSH "[ -f '$HBASE_CACHE' ] && { ls -la '$HBASE_CACHE'; rm -rf '$HBASE_CACHE'; }"
  fi

  stop_hbase
}