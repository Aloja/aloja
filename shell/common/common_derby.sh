# Sets the required files to download/copy
set_derby_requires() {
  [ ! "$DERBY_VERSION" ] && die "No DERBY_VERSION specified"
  BENCH_REQUIRED_FILES["$DERBY_VERSION"]="http://www-eu.apache.org/dist/db/derby/db-derby-10.13.1.1/db-derby-10.13.1.1-bin.tar.gz"
}

get_derby_exports() {
    echo
    printf 'export DERBY_HOME=%s\n' "$(get_local_apps_path)/${DERBY_VERSION}"
}

stop_derby() {
  logger "INFO: Stopping Derby database"
  cmd=("$(get_java_home)/bin/java" '-jar' "-Dderby.system.home=$(get_local_bench_path)" "${DERBY_HOME}/lib/derbyrun.jar" 'server' 'shutdown' '-h' "$master_name")
  $DSH_MASTER "${cmd[@]}"
  [ -d $(get_local_bench_path)/aplic/bigbench_metastore_db ] && rm -r $(get_local_bench_path)/aplic/bigbench_metastore_db #Force deletion of metastore folder if not properly deleted previously
}

start_derby() {
  stop_derby
  logger "INFO: Starting Derby database"
  cmd=(-r ssh -o -f "$(get_java_home)/bin/java" '-jar' "-Dderby.system.home=$(get_local_bench_path)" "${DERBY_HOME}/lib/derbyrun.jar"  'server' 'start' '-h' "$master_name")
  $DSH_MASTER "${cmd[@]}"
}

initialize_derby_vars() {
  if [ "$clusterType" == "PaaS" ]; then
    :
  else
    DB_NAME=
    DERBY_HOME="$(get_local_apps_path)/${DERBY_VERSION}"
  fi
}