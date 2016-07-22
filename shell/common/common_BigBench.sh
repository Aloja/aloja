#BIG_BENCH SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Start Hive
source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

# Start Spark
source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires

BIG_BENCH_FOLDER="Big-Data-Benchmark-for-Big-Bench-master"
BIG_BENCH_CONF_DIR="BigBench_conf_template"
BIG_BENCH_EXECUTION_DIR="src/BigBench"

# Sets the required files to download/copy
set_BigBench_requires() {
  [ ! "$MAHOUT_VERSION" ] && die "No MAHOUT_VERSION specified"


  BENCH_REQUIRED_FILES["$BIG_BENCH_FOLDER"]="https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/archive/master.zip"
#  BENCH_REQUIRED_FILES["$MAHOUT_VERSION"]="https://archive.apache.org/dist/mahout/$MAHOUT_VERSION/mahout-distribution-${MAHOUT_VERSION}.tar.gz"

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS $BIG_BENCH_CONF_DIR"
}

# Helper to print a line with requiered exports
get_BigBench_exports() {
  local to_export

  to_export="
  $(get_hive_exports)
  $(get_spark_exports)
  PATH=$PATH:$BENCH_HADOOP_DIR/bin/
  export _JAVA_OPTIONS="$JAVA_XMS"
  "
  echo -e "$to_export\n"
}

# Returns the the path to the BigBench binary with the proper exports
get_BigBench_cmd() {
  local BigBench_exports
  local BigBench_cmd

  BigBench_exports="$(get_BigBench_exports)"
  BigBench_cmd="$BigBench_exports\n$(get_BigBench_execution_dir)/bin/bigBench"

  echo -e "$BigBench_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_BigBench(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local BigBench_cmd="$(get_BigBench_cmd) $cmd"
  echo $BigBench_cmd

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: BigBench command:\n$BigBench_cmd"

  # Run the command and time it
  time_cmd_master "$BigBench_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_BigBench "$bench"
  fi
}

initialize_BigBench_vars() {
    :
    #BIG_BENCH_HOME="$(get_local_apps_path)/$BIG_BENCH_FOLDER"
}

# Sets the substitution values for the BigBench config
get_BigBench_substitutions() {

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/BigBench_logs,g;
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
s,##HDD##,$HDD,g;
s,##HIVE##,$(get_local_apps_path)/$HIVE_VERSION/bin/hive,g;
s,##HDFS_PATH##,$(get_base_bench_path),g;
s,##HADOOP_CONF##,$(get_base_bench_path)/hadoop_conf,g;
s,##HADOOP_LIBS##,$(get_local_apps_path)/$HADOOP_VERSION/lib/native,g;
s,##SPARK##,$(get_local_apps_path)/$SPARK_VERSION/bin/spark-sql,g
EOF
}

get_BigBench_execution_dir() {
    echo -e "$(get_base_bench_path)/$BIG_BENCH_EXECUTION_DIR"
}

get_BigBench_conf_dir() {
  echo -e "$HDD/$BIG_BENCH_CONF_DIR"
}

prepare_BigBench() {

  logger "INFO: Copying BigBench execution and config files to $(get_BigBench_execution_dir)"

  $DSH "mkdir -p $(get_base_bench_path)/src/BigBench && cp -r $(get_local_apps_path)/$BIG_BENCH_FOLDER/* $(get_BigBench_execution_dir)"
  $DSH "cp -r $(get_local_configs_path)/$BIG_BENCH_CONF_DIR/* $(get_BigBench_execution_dir)/;"

  # Get the values
  subs=$(get_BigBench_substitutions)
  $DSH "/usr/bin/perl -i -pe \"$subs\" $(get_base_bench_path)/src/BigBench/conf/userSettings.conf"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $(get_base_bench_path)/src/BigBench/engines/hive/conf/engineSettings.conf"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $(get_base_bench_path)/src/BigBench/engines/spark/conf/engineSettings.conf"

}

# $1 bench
save_BigBench() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  $DSH "mkdir -p $JOB_PATH/$bench_name_num/BigBench_logs;"

  if [ "$BENCH_LEAVE_SERVICES" ] ; then
    $DSH "cp $(get_base_bench_path)/src/BigBench/logs/* $JOB_PATH/$bench_name_num/BigBench_logs/"
  else
    $DSH "mv $(get_base_bench_path)/src/BigBench/logs/* $JOB_PATH/$bench_name_num/BigBench_logs/"
  fi

  save_hive "$bench_name"
}