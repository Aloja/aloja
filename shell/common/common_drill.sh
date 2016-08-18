#!/usr/bin/env bash
#DRILL SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires


source_file "$ALOJA_REPO_PATH/shell/common/common_zookeeper.sh"
set_zookeeper_requires

# Sets the required files to download/copy
set_drill_requires() {

  [ ! "$DRILL_VERSION" ] && die "No DRILL_VERSION specified"

  BENCH_REQUIRED_FILES["$DRILL_VERSION"]="http://apache.mesi.com.ar/drill/drill-1.6.0/$DRILL_VERSION.tar.gz"

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS drill_1.6_conf_template"

}

# Helper to print a line with requiered exports
get_drill_exports() {
  local to_export

  to_export="$(get_hadoop_exports)
export DRILL_VERSION='$DRILL_VERSION';
export DRILL_HOME='$(get_local_apps_path)/${DRILL_VERSION}';
export DRILL_CONF_DIR=$(get_local_apps_path)/${DRILL_VERSION}/conf;
export DRILL_LOG_DIR=$(get_local_bench_path)/${DRILL_VERSION}/bin;
"

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
get_drill_cmd() {
  local drill_exports
  local drill_cmd

  drill_exports="$(get_drill_exports)"


  drill_cmd="$drill_exports\n$(get_local_apps_path)/${DRILL_VERSION}/bin/sqlline -u jdbc:drill:zk:vagrant-99-00:2181 "
  #drill_cmd="$drill_exports\n$(get_local_apps_path)/${DRILL_VERSION}/bin/drill-conf "
  echo -e "$drill_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_drill(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local drill_cmd="$(get_drill_cmd) $cmd"

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: DRILL command:\n$drill_cmd"

  export JAVA_HOME="$(get_java_home)"
  #echo -e $DRILL_CONF_DIR
  start_zookeeper
  #bash $DRILL_HOME/bin/drillbit.sh restart
  bash $DRILL_HOME/bin/drillbit.sh restart
  bash $DRILL_HOME/bin/drillbit.sh status
  echo 'done'
  #curl -X POST -H "Content-Type: application/json" -d '{"queryType":"SQL", "query": "SELECT * FROM sys.drillbits"}' http://localhost:31010/query.json
  #bash $(get_local_apps_path)/${DRILL_VERSION}/bin/drill-localhost -e "select count(*) from (values(1));"
  sleep 60
  # Run the command and time it
  time_cmd_master "$drill_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_drill "$bench"
  fi
}

initialize_drill_vars() {
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS drill_1.6_conf_template"

  if [ "$clusterType" == "PaaS" ]; then
    DRILL_HOME="/usr/bin/drill"
    DRILL_CONF_DIR="/etc/drill/conf"
  else
    DRILL_HOME="$(get_local_apps_path)/${DRILL_VERSION}"
    DRILL_CONF_DIR="$HDD/drill_conf"
  fi
}

# $1 bench name
save_drill() {
  logger "WARNING: missing to implement a proper save_drill()"
  save_zookeeper
  save_hadoop "$bench_name"
  }