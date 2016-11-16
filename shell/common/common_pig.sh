#PIG SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_pig_requires() {
  [ ! "$PIG_VERSION" ] && die "No PIG_VERSION specified"

  BENCH_REQUIRED_FILES["$PIG_VERSION"]="http://apache.rediris.es/pig/$PIG_VERSION/$PIG_VERSION.tar.gz"

  #also set the config here
  #BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS pig_conf_template"
}

# Helper to print a line with required exports
get_pig_exports() {
  local to_export

  to_export="$(get_hadoop_exports)
export PIG_VERSION='$PIG_VERSION';
export PIG_HOME='$(get_local_apps_path)/${PIG_VERSION}';
export PIG_CONF_DIR=$(get_local_apps_path)/${PIG_VERSION}/conf;
export PIG_LOG_DIR=$(get_local_bench_path)/pig_logs;
"

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
get_pig_cmd() {
  local pig_exports
  local pig_cmd

  pig_exports="$(get_pig_exports)"

  pig_cmd="$pig_exports\n$(get_local_apps_path)/${PIG_VERSION}/bin/pig "

  echo -e "$pig_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_pig(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local pig_cmd="$(get_pig_cmd) $cmd"

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: Pig command:\n$pig_cmd"

  # Run the command and time it
  time_cmd_master "$pig_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_pig "$bench"
  fi
}

initialize_pig_vars() {
  if [ "$clusterType" == "PaaS" ]; then
    PIG_HOME="/usr/bin/pig"
    PIG_CONF_DIR="/etc/pig/conf"
  else
    PIG_HOME="$(get_local_apps_path)/${PIG_VERSION}"
    PIG_CONF_DIR="$(get_local_apps_path)/${PIG_VERSION}/conf"
  fi
}

# $1 bench name
save_pig() {
  logger "WARNING: missing to implement a proper save_pig()"
  save_hive
}