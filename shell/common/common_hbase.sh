#HBASE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

#Zookeeper
source_file "$ALOJA_REPO_PATH/shell/common/common_zookeeper.sh"
set_zookeeper_requires


# Sets the required files to download/copy
set_hbase_requires() {
  [ ! "$HBASE_VERSION" ] && die "No HBASE_VERSION specified"

  if [ "$clusterType" != "PaaS" ]; then
    if [ "$(get_hadoop_major_version)" == "2" ]; then
      HBASE_FOLDER="hbase-${HBASE_VERSION}-hadoop2"
      BENCH_REQUIRED_FILES["$HBASE_FOLDER"]="http://www-eu.apache.org/dist/hbase/$HBASE_VERSION/$HBASE_FOLDER-bin.tar.gz"
    else
      HBASE_FOLDER="hbase-${HBASE_VERSION}-hadoop1"
      BENCH_REQUIRED_FILES["$HBASE_FOLDER"]="http://www-eu.apache.org/dist/hbase/$HBASE_VERSION/$HBASE_FOLDER-bin.tar.gz"
    fi
  fi
  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${HBASE_FOLDER}_conf_template"
}

# Helper to print a line with requiered exports
get_hbase_exports() {
  local to_export

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="
    export HBASE_CONF_DIR=$HBASE_CONF_DIR
"
    echo -e "$to_export\n"
  fi
}

# Returns the the path to the hbase binary with the proper exports
get_hbase_cmd() {
  local hbase_exports
  local hbase_cmd

  if [ "$clusterType" == "PaaS" ]; then
    hbase_exports=""
    hbase_bin="hbase"
  else
    hbase_exports="$(get_hbase_exports)"
    hbase_bin="$HBASE_HOME/bin/"
  fi
  hbase_cmd="$hbase_exports\n $hbase_bin"

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

  # if in PaaS use the bin in PATH and no exports
  if [ "$clusterType" == "PaaS" ]; then
    hbase_cmd="$cmd"
  else
    hbase_cmd="$(get_hbase_cmd)$cmd"
  fi

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: Hbase command:\n$hbase_cmd"

  # Run the command and time it
  time_cmd_master "$hbase_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_hbase "$bench"
  fi
}

stop_hbase() {
  #Stop Hbase
  logger "INFO: Stopping hbase"
  if [ "$clusterType" == "PaaS" ]; then
    :
  else
    $DSH "export HBASE_CONF_DIR=$HBASE_CONF_DIR && $HBASE_HOME/bin/stop-hbase.sh"
  fi
}

start_hbase() {
    #Start Hbase
    stop_hbase
    execute_hbase "start-hbase" "start-hbase.sh" "time"
}
initialize_hbase_vars() {

  if [ "$clusterType" == "PaaS" ]; then
    HBASE_HOME="/usr"
    HBASE_CONF_DIR="/etc/hbase/conf"
  else
    HBASE_HOME="$(get_local_apps_path)/${HBASE_FOLDER}"
    HBASE_CONF_DIR="$(get_hbase_conf_dir)"
  fi
}

# Sets the substitution values for the Hbase config
get_hbase_substitutions() {

  local node_names="$(get_node_names)"
  local servers=''
  local region_servers=''
  local backup_server=''
  local count=0
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
s,##BACKUP_SERVER##,$backup_server,g
EOF
}

get_hbase_conf_dir() {
  echo -e "$(get_local_bench_path)/hbase_conf"
}

prepare_hbase_config() {
  logger "INFO: Preparing hbase run specific config"
  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    $DSH "mkdir -p $HBASE_CONF_DIR && cp -r $(get_local_configs_path)/${HBASE_FOLDER}_conf_template/* $HBASE_CONF_DIR/"
    subs=$(get_hbase_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $HBASE_CONF_DIR/*"
  fi
}

# $1 bench name
save_hbase() {
#  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"
#
#  local bench_name="$1"
#  local bench_name_num="$(get_bench_name_with_num "$bench_name")"
#
#  # Create Spark log dir
#  $DSH "mkdir -p $JOB_PATH/$bench_name_num/spark_logs;"
#
#  if [ "$clusterType" == "PaaS" ]; then
#    $DSH "cp -r /var/log/spark $JOB_PATH/$bench_name_num/spark_logs/" #2> /dev/null
#  else
#    if [ "$BENCH_LEAVE_SERVICES" ] ; then
#      $DSH "cp $(get_local_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
#    else
#      $DSH "mv $(get_local_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
#    fi
#  fi
#  # Save spark conf
#  $DSH_MASTER "tar -cjf $JOB_PATH/spark_conf.tar.bz2 $SPARK_CONF_DIR/*"
#  save_hadoop "$bench_name"
echo "NEED TO SAVE HBASE"
#TODO: save HBASE
}