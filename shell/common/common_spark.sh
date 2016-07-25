#SPARK SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_spark_requires() {
  [ ! "$SPARK_VERSION" ] && die "No SPARK_VERSION specified"

  if [ "$BENCH_SUITE" == "BigBench" ]; then
    BENCH_REQUIRED_FILES["$SPARK_HIVE"]="http://aloja.bsc.es/public/files/spark_hive_ubuntu-1.6.2.tar.gz"
    SPARK_VERSION=$SPARK_HIVE
    SPARK_FOLDER=$SPARK_HIVE

  else

#      if [ "$clusterType" != "PaaS" ]; then
    SPARK_FOLDER="${SPARK_VERSION}-bin-without-hadoop"
    BENCH_REQUIRED_FILES["$SPARK_FOLDER"]="http://apache.rediris.es/spark/$SPARK_VERSION/$SPARK_FOLDER.tgz"
#      fi
  fi

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${SPARK_VERSION}_conf_template"
}

# Helper to print a line with requiered exports
get_spark_exports() {
  local to_export

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="$(get_hadoop_exports)
export SPARK_VERSION='$SPARK_VERSION';
export SPARK_HOME='$(get_local_apps_path)/${SPARK_FOLDER}';
export SPARK_CONF_DIR=$(get_spark_conf_dir);
export SPARK_LOG_DIR=$(get_local_bench_path)/spark_logs;
export SPARK_CLASSPATH=\$($(get_local_apps_path)/${HADOOP_VERSION}/bin/hadoop classpath);
"
    echo -e "$to_export\n"
  fi
}

# Returns the the path to the hadoop binary with the proper exports
get_spark_cmd() {
  local spark_exports
  local spark_cmd

  spark_exports="$(get_spark_exports)"
  spark_bin="$(get_local_apps_path)/${SPARK_FOLDER}/bin/"
  spark_cmd="$spark_exports\n $spark_bin"

  echo -e "$spark_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_spark(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local spark_cmd

  # if in PaaS use the bin in PATH and no exports
  if [ "$clusterType" == "PaaS" ]; then
    spark_cmd="$cmd"
  else
    spark_cmd="$(get_spark_cmd)$cmd"
  fi

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: Spark command:\n$spark_cmd"

  # Run the command and time it
  time_cmd_master "$spark_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_spark "$bench"
  fi
}

initialize_spark_vars() {
  if [ "$clusterType" == "PaaS" ]; then
    SPARK_HOME="/usr/bin/spark"
    SPARK_CONF_DIR="/etc/spark/conf"
  else
    SPARK_HOME="$(get_local_apps_path)/${SPARK_FOLDER}"
    SPARK_CONF_DIR="$(get_spark_conf_dir)"
  fi
}

# Sets the substitution values for the Spark config
get_spark_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/spark_logs,g;
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
s,##HDD##,$(get_base_bench_path),g;
s,##HIVE##,$(get_local_apps_path)/$HIVE_VERSION/bin/hive,g;
s,##HDFS_PATH##,$(get_base_bench_path),g;
s,##HADOOP_CONF##,$(get_base_bench_path)/hadoop_conf,g;
s,##HADOOP_LIBS##,$(get_local_apps_path)/$HADOOP_VERSION/lib/native,g;
s,##SPARK##,$(get_local_apps_path)/$SPARK_FOLDER/bin/spark,g;
s,##SPARK_CONF##,$(get_spark_conf_dir),g
EOF
}

get_spark_conf_dir() {
  echo -e "$(get_base_bench_path)/spark_conf"
}

prepare_spark_config() {

  logger "INFO: Preparing spark run specific config"
  $DSH "mkdir -p $(get_spark_conf_dir) && cp -r $(get_local_configs_path)/${SPARK_VERSION}_conf_template/* $(get_spark_conf_dir)/"
  subs=$(get_spark_substitutions)
  $DSH "/usr/bin/perl -i -pe \"$subs\" $(get_spark_conf_dir)/*"
  $DSH "cp $(get_base_bench_path)/hadoop_conf/slaves $(get_spark_conf_dir)/slaves"
}

# $1 bench name
save_spark() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create Spark log dir
  $DSH "mkdir -p $JOB_PATH/$bench_name_num/spark_logs;"
  if [ "$BENCH_LEAVE_SERVICES" ] ; then
    $DSH "cp $(get_base_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
  else
    $DSH "mv $(get_base_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
  fi

  # Save spark conf
  $DSH_MASTER "cd $(get_base_bench_path)/; tar -cjf $JOB_PATH/spark_conf.tar.bz2 spark_conf"

  save_hadoop "$bench_name"
}