# Sets the required files to download/copy
set_derby_requires() {
  [ ! "$DERBY_VERSION" ] && die "No DERBY_VERSION specified"
  BENCH_REQUIRED_FILES["$DERBY_VERSION"]="http://www-eu.apache.org/dist/db/derby/db-derby-10.13.1.1/db-derby-10.13.1.1-bin.tar.gz"
}

get_derby_exports() {
    echo
    printf 'export DERBY_HOME=%s\n' "$(get_local_apps_path)/${DERBY_VERSION}"
    printf 'export CLASSPATH=${CLASSPATH}:%s:%s:%s;\n' "$(get_local_apps_path)/${DERBY_VERSION}/lib/derbyclient.jar" "$(get_local_apps_path)/${DERBY_VERSION}/lib/derbytools.jar" "$(get_local_apps_path)/${DERBY_VERSION}/lib/derby.jar"
#  $DSH "cp $(get_local_apps_path)/${DERBY_VERSION}/lib/derbyclient.jar $HADOOP_HOME/lib"
#  $DSH "cp $(get_local_apps_path)/${DERBY_VERSION}/lib/derbytools.jar $HADOOP_HOME/lib"

}

stop_derby() {
  logger "INFO: Stopping Derby database"
  cmd=("$(get_java_home)/bin/java" '-jar' "$(get_local_apps_path)/${DERBY_VERSION}/lib/derbyrun.jar" 'server' 'shutdown' '-h' "$master_name")
  $DSH_MASTER "${cmd[@]}"
}

start_derby() {
  stop_derby
  logger "INFO: Starting Derby database"
  cmd=('nohup' "$(get_java_home)/bin/java" '-jar' "$(get_local_apps_path)/${DERBY_VERSION}/lib/derbyrun.jar" 'server' 'start' '-h' "$master_name")
  set -x
  $DSH_MASTER "${cmd[@]}" & 2>/dev/null
  set +x
}

#initialize_derby_vars() {
#  if [ "$clusterType" == "PaaS" ]; then
#    :
#  else
#    DERBY_HOME="$(get_local_apps_path)/${DERBY_VERSION}"
#  fi
#}