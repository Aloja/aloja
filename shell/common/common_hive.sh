#HADOOP SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

get_hadoop_config_folder() {
  local config_folder_name

  if [ "$HADOOP_CUSTOM_CONFIG" ] ; then
    config_folder_name="$HADOOP_CUSTOM_CONFIG"
  elif [ "$HADOOP_EXTRA_JARS" == "AOP4Hadoop" ] ; then
    config_folder_name="hadoop1_AOP_conf_template"
  elif [ "$(get_hadoop_major_version)" == "2" ]; then
    config_folder_name="hadoop2_conf_template"
  else
    config_folder_name="hadoop1_conf_template"
  fi

  echo -e "$config_folder_name"
}

# Sets the required files to download/copy
set_hive_requires() {
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION.tar.gz"
  else
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION-bin.tar.gz"
  fi
}

# Helper to print a line with Hadoop requiered exports
get_hive_exports() {
  local to_export

  to_export="$(get_java_exports)
$(get_hadoop_exports)
export HIVE_VERSION='apache-hive-1.2.0-bin';
export HIVE_B_DIR='$TPCH_B_DIR';
export HIVE_HOME='${TPCH_B_DIR}/${HIVE_VERSION}';"

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
# $1 query path
# $2 table name
get_hive_cmd() {
  local hive_exports
  local hive_cmd

  if [ "$EXECUTE_HIBENCH" ] ; then
    hive_exports="$(get_hive_exports)
export TPCH_B_DIR='${HDD}/aplic';
export TPCH_SOURCE_DIR='${BENCH_SOURCE_DIR}/tpch-hive';
export TPCH_HOME='$TPCH_SOURCE_DIR';
cd ${TPCH_HOME};
"
  else
    hive_exports="$(get_hive_exports)"
  fi

  EXP=$(get_hive_env)

  SETTINGS="${PREFIX}/${TPCH_SETTINGS_FILE_NAME}"
  COMMAND="hive -i $SETTINGS -f ${PREFIX}/tpch_${1}.sql --database ${TABLE_NAME}"

  hive_cmd="$hive_exports hive -i $SETTINGS"

  echo -e "$hive_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_hive(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local hadoop_cmd="$(get_hadoop_cmd) $cmd"

  logger "DEBUG: Hadoop command:$hadoop_cmd"

  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  # Run the command and time it
  time_cmd_master "$hadoop_cmd" "$time_exec"

  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_hadoop "$bench"
  fi
}