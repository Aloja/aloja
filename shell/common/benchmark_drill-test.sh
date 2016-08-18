# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_drill_test.sh"
set_drill_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="drill-test"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_drill_vars
  prepare_drill_config "$NET" "$DISK" "$BENCH_SUITE"
  start_drill
}

benchmark_suite_cleanup() {
  clean_hadoop
}

benchmark_drill-test() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_drill "$bench_name" '-e "use sys;' "time"
  #execute_drill "$bench_name" '-e "use sys;"' "time"
}