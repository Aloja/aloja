#Zookeeper SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_java.sh"
set_java_requires

# Sets the required files to download/copy
set_zookeeper_requires() {
  [ ! "$ZOOKEEPER_VERSION" ] && die "No ZOOKEEPER_VERSION specified"

  if [ "$clusterType" != "PaaS" ]; then
    BENCH_REQUIRED_FILES["$ZOOKEEPER_VERSION"]="http://www-eu.apache.org/dist/zookeeper/$ZOOKEEPER_VERSION/$ZOOKEEPER_VERSION.tar.gz"
  fi
  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS zookeeper-3.4.9_conf_template"
}

# Helper to print a line with requiered exports
get_zookeeper_exports() {
  local to_export

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="
    $(get_java_exports)
    export ZOOCFGDIR='$(get_zookeeper_conf_dir)'
    export ZOOCFG=''
"
    echo -e "$to_export\n"
  fi
}

# Returns the the path to the zookeeper binary with the proper exports
get_zookeeper_cmd() {
  local zookeeper_exports
  local zookeeper_cmd

  if [ "$clusterType" == "PaaS" ]; then
    zoopeeper_exports=""
    zookeeper_bin="zookeeper-server"
  else
    zookeeper_exports="$(get_zookeeper_exports)"
    zookeeper_bin="$ZOOKEEPER_HOME/bin/zkServer.sh"
  fi
  zookeeper_cmd="$zookeeper_exports\n $zookeeper_bin"

  echo -e "$zookeeper_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_zookeeper(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local zookeeper_cmd

  zookeeper_cmd="$(get_zookeeper_cmd)$cmd"

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: Zookeeper command:\n$zookeeper_cmd"

  # Run the command
  $DSH "$zookeeper_cmd"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_zookeeper "$bench"
  fi
}

stop_zookeeper(){
    #Stop Zookeeper
    logger "INFO: Stopping Zookeeper"
    cmd=" stop"
    zookeeper_cmd="$(get_zookeeper_cmd)$cmd"
    $DSH "$zookeeper_cmd"
}

start_zookeeper(){

    #Stop Zookeeper
    stop_zookeeper
    #Start Zookeeper
    logger "INFO: Starting Zookeeper"
    cmd=" start"
    zookeeper_cmd="$(get_zookeeper_cmd)$cmd"
    $DSH "$zookeeper_cmd"

}

initialize_zookeeper_vars() {

  if [ "$clusterType" == "PaaS" ]; then
    ZOOKEEPER_HOME="/usr"
    ZOOKEEPER_CONF_DIR="/etc/zookeeper/conf"
  else
    ZOOKEEPER_HOME="$(get_local_apps_path)/${ZOOKEEPER_VERSION}"
    ZOOKEEPER_CONF_DIR="$(get_zookeeper_conf_dir)"
  fi
}

# Sets the substitution values for the Zookeeper config
get_zookeeper_substitutions() {

  local node_names="$(get_node_names)"
  local servers=''
  local count=1
  for node in $node_names ; do
    servers+="server.${count}=${node}:2888:3888\n"
    count=$((count+1))
  done

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$(get_local_bench_path)/zookeeper_logs,g;
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
s,##SERVERS#,$servers,g
EOF
}

get_zookeeper_conf_dir() {
  echo -e "$(get_local_bench_path)/zookeeper_conf"
}

prepare_zookeeper_config() {
  logger "INFO: Preparing zookeeper run specific config"
  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    $DSH "mkdir -p $ZOOKEEPER_CONF_DIR && cp -r $(get_local_configs_path)/${ZOOKEEPER_VERSION}_conf_template/* $ZOOKEEPER_CONF_DIR/"
    $DSH "mkdir -p $(get_local_bench_path)/zookeeper"
    subs=$(get_zookeeper_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $ZOOKEEPER_CONF_DIR/*"
    #Create myid file in each node
    count=1
    for node in $(get_node_names) ; do
      ssh "$node" "
      echo ${count} >> /tmp/zookeeper/myid" &
      count=$((count+1))
    done
  fi
}

# $1 bench name
save_zookeeper() {
#TODO code save zookeeper
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
echo "NEED TO SAVE ZOOKEEPER"
#TODO: save HBASE
}