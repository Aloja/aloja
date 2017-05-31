source_file "$ALOJA_REPO_PATH/shell/common/common_java.sh"
set_java_requires

# Sets the required files to download/copy
set_derby_requires() {
  [ ! "$DERBY_VERSION" ] && die "No DERBY_VERSION specified"
  BENCH_REQUIRED_FILES["$DERBY_VERSION"]="http://www-eu.apache.org/dist/db/derby/db-derby-10.13.1.1/db-derby-10.13.1.1-bin.tar.gz"
}

get_derby_exports() {
    echo
    printf "$(get_java_exports)"
    printf 'export DERBY_HOME=%s\n' "$(get_local_apps_path)/${DERBY_VERSION}"
    printf 'export CLASSPATH=$CLASSPATH:%s\n' "$DERBY_HOME/lib/derbyclient.jar:$DERBY_HOME/lib/derby.jar"
}

# Returns the the path to the derby binary with the proper exports
get_derby_cmd() {
  local derby_exports
  local derby_cmd

  #if [ "$clusterType" == "PaaS" ]; then
  #  derby_exports=""
  #  derby_bin="derby"
  #else
    derby_exports="$(get_derby_exports)"
    derby_bin="$DERBY_HOME/bin/ij"
  #fi
  derby_cmd="$derby_exports\n$derby_bin"

  echo -e "$derby_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_derby(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local derby_cmd

  derby_cmd="$(get_derby_cmd) $cmd"

  # Run the command and time it
  execute_master "$bench" "$derby_cmd" "$time_exec" "dont_save"

}

# $1 force stop, for use at restart (useful for -S)
stop_derby() {
  local force_stop="$1"

  if [ "$clusterType" != "PaaS" ] && [[ ! "$BENCH_LEAVE_SERVICES" || "$force_stop" ]] && [[ "$DELETE_HDFS" == "1" || "$force_stop" ]] ; then
    logger "INFO: Stopping Derby database"
    #cmd=("$(get_java_home)/bin/java" '-jar' "-Dderby.system.home=$(get_local_bench_path)" "${DERBY_HOME}/lib/derbyrun.jar" 'server' 'shutdown' '-h' "$master_name")
    $DSH_MASTER "$(get_java_home)/bin/java -jar -Dderby.system.home=$(get_local_bench_path) ${DERBY_HOME}/lib/derbyrun.jar server shutdown -h $master_name"

    #TODO don't execute locally use execute_master
    [ -d $(get_local_bench_path)/aplic/$DATABASE_NAME ] && rm -r $(get_local_bench_path)/aplic/$DATABASE_NAME #Force deletion of metastore folder if not properly deleted previously
  else
    log_WARN "Not stopping Derby (as requested with -S or -N or PaaS mode)."
  fi
}

start_derby() {

  if [ "$clusterType" != "PaaS" ]; then

    if [ "$DELETE_HDFS" == "1" ]; then
      stop_derby "force"
    fi

    # First, make sure we stop derby on abnormal exit
    update_traps "stop_derby;" "update_logger"

    logger "INFO: Starting Derby database"
    cmd=(-r ssh -o -f -- "$(get_java_home)/bin/java" '-jar' "-Dderby.system.home=$(get_local_bench_path)" "${DERBY_HOME}/lib/derbyrun.jar"  'server' 'start' '-h' "$master_name")
    $DSH_MASTER "${cmd[@]}"
    sleep 3
  else
    log_WARN "Not starting in PaaS cluster."
  fi
}

get_database_connection_url() {
  printf "%s" "jdbc:derby://${master_name}:1527/$(get_local_bench_path)/aplic/$DATABASE_NAME;create=true"
}

get_database_driver_path_colon() {
  printf "%s" "${DERBY_HOME}/lib/derbyclient.jar:${DERBY_HOME}/lib/derby.jar"
}

get_database_driver_path_coma() {
  printf "%s" "${DERBY_HOME}/lib/derbyclient.jar,${DERBY_HOME}/lib/derby.jar"
}

get_database_driver_name() {
  printf "org.apache.derby.jdbc.ClientDriver"
}

initialize_derby_vars() {
  local database_name

  if [ "$1" ]; then
    database_name="$1"
  else
    database_name="Derby_DB"
  fi

  if [ "$clusterType" == "PaaS" ]; then
    :
  else
    DERBY_HOME="$(get_local_apps_path)/${DERBY_VERSION}"
    DATABASE_NAME="$database_name"
  fi
}

clean_derby() {
  stop_derby
}