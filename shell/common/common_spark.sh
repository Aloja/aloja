#SPARK SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_spark_requires() {
  [ ! "$SPARK_VERSION" ] && die "No SPARK_VERSION specified"

  if [ "$clusterType" != "PaaS" ]; then
    BENCH_REQUIRED_FILES["$SPARK_VERSION"]="http://apache.rediris.es/spark/spark-1.6.1/$SPARK_VERSION.tgz"
  fi

  #also set the config here
  #BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS spark_conf_template"
}

# Helper to print a line with requiered exports
get_spark_exports() {
  local to_export

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="$(get_hadoop_exports)
export SPARK_VERSION='$SPARK_VERSION';
export SPARK_HOME='$(get_local_apps_path)/${SPARK_VERSION}';
export SPARK_CONF_DIR=$(get_local_apps_path)/${SPARK_VERSION}/conf;
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

  spark_cmd="$spark_exports\n$(get_local_apps_path)/${SPARK_VERSION}/bin/"

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
    SPARK_HOME="$(get_local_apps_path)/${SPARK_VERSION}"
    SPARK_CONF_DIR="$(get_local_apps_path)/${SPARK_VERSION}/conf"
  fi
}

# $1 bench name
save_spark() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  logger "WARNING: missing to implement a proper save_spark()"
  save_hive "$bench_name"
}