#JAVA SPECIFIC FUNCTIONS

# Returns a list of required files
set_java_requires() {
  #download it from ALOJA's public file server as oracle requires licence acceptance
  BENCH_REQUIRED_FILES["$BENCH_JAVA_VERSION"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/$BENCH_JAVA_VERSION.tar.gz"
}

get_java_home(){
  if [ "$BENCH_JAVA_VERSION" ] ; then
    echo -e "$(get_local_apps_path)/$BENCH_JAVA_VERSION"
  else
    die "Cannot determine JAVA_HOME, BENCH_JAVA_VERSION not set"
  fi
}

get_java_bin() {
  if [ "$clusterType" == "PaaS" ]; then
    echo -e "`which java`"
  else
    if [ "$BENCH_JAVA_VERSION" ] ; then
      echo -e "$(get_local_apps_path)/$BENCH_JAVA_VERSION/bin/java"
    else
      die "Cannot determine JAVA_HOME, BENCH_JAVA_VERSION not set"
    fi
  fi
}

get_java_exports() {
  if [ "$clusterType" != "PaaS" ]; then #on PaaS use the system version
    local java_path="$(get_local_apps_path)/$BENCH_JAVA_VERSION"
    echo -e "export JAVA_HOME='$java_path';"
  fi
}

# Sets the JAVA_HOME for the benchmark
# TODO this assumes you are in the head node and only sets it there, should finish export_var_path funct
# also that it is run from the main run_bench.sh file
#set_java_home(){
#  if [ ! "$JAVA_HOME" ] ; then
#    local java_path="$(get_local_apps_path)/$BENCH_JAVA_VERSION"
#    if [ -d "$java_path" ] ; then
#      logger "INFO: Exporting JAVA_HOME to $java_path"
#      export JAVA_HOME="$java_path"
#    else
#      die "JAVA_HOME not set and $java_path not existent"
#    fi
#  else
#   logger "INFO: Using already set JAVA_HOME at $JAVA_HOME"
#  fi
#}