#HIVE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_hive_requires() {
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION.tar.gz"
    BENCH_REQUIRED_FILES["hive"]="http://apache.rediris.es/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz"
  else
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION-bin.tar.gz"
    BENCH_REQUIRED_FILES["hive"]="https://archive.apache.org/dist/hive/hive-0.13.1/apache-hive-0.13.1-bin.tar.gz"
  fi

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS hive_conf_template"
}

# Helper to print a line with Hadoop requiered exports
get_hive_exports() {
  local to_export

  to_export="$(get_hadoop_exports)
    export HIVE_VERSION='$HIVE_VERSION';
    export HIVE_HOME='$(get_local_apps_path)/${HIVE_VERSION}';
  "

  if [ "$EXECUTE_TPCH" ]; then
    to_export="${to_export} export TPCH_HOME='$(get_local_apps_path)/tpch-hive';"
  fi

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
get_hive_cmd() {
  local hive_exports
  local hive_cmd

  hive_exports="$(get_hive_exports)"

  hive_cmd="$hive_exports $HIVE_HOME/bin/hive -i $HIVE_SETTINGS_FILE_PATH"

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

  local hive_cmd="$(get_hive_cmd) $cmd"

  logger "DEBUG: Hive command: $hive_cmd"

  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  # Run the command and time it
  time_cmd_master "$hive_cmd" "$time_exec"

  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_hadoop "$bench"
  fi
}

initialize_hive_vars() {
  [ ! "$HIVE_SETTINGS_FILE" ] && HIVE_SETTINGS_FILE="hive.settings"
  [ ! "$HIVE_SETTINGS_FILE_PATH" ] && HIVE_SETTINGS_FILE_PATH="$HDD/hive_conf_template/${HIVE_SETTINGS_FILE}"
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS hive_conf_template"

  if [[ -z "$HIVE_VERSION" && "$(get_hadoop_major_version)" == "2" ]]; then
    HIVE_VERSION='apache-hive-1.2.1-bin'
  elif [ -z "$HIVE_VERSION" ]; then
    HIVE_VERSION='apache-hive-0.13.1-bin'
  fi
  HIVE_HOME="$(get_local_apps_path)/${HIVE_VERSION}"
}

# Sets the substitution values for the hive config
get_hive_substitutions() {

  # TODO: define the settings, right now settings file is empty
  cat <<EOF
    s,##MAX_MAPS##,$MAX_MAPS,g;
    s,##MAX_REDUCES##,$MAX_REDUCES,g;
EOF
}

# $1 HIVE_SETTINGS_FILE
# $2 HIVE_SETTINGS_FILE_PATH
prepare_hive_config() {
  logger "INFO: Preparing hive run specific config"
  $DSH "mkdir -p '$HDD/hive_conf_template'; cp -r $(get_local_configs_path)/hive_conf_template/${1} ${2};"

  # Get the values
  subs=$(get_hive_substitutions)
  $DSH "/usr/bin/perl -i -pe \"$subs\" ${HIVE_SETTINGS_FILE_PATH}"

  if [ ! -z "$MAPS_MB" ]; then
      $DSH "echo 'set mapreduce.map.memory.mb=${MAPS_MB};' >> ${HIVE_SETTINGS_FILE_PATH}"
  fi
  if [ ! -z "$REDUCES_MB" ]; then
      $DSH "echo 'set mapreduce.reduce.memory.mb=${REDUCES_MB};' >> ${HIVE_SETTINGS_FILE_PATH}"
  fi
}
