# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_zookeeper.sh"
set_zookeeper_requires

#BENCH_REQUIRED_FILES["tpch-spark"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-spark.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="status"

benchmark_suite_config() {
  initialize_zookeeper_vars
  prepare_zookeeper_config
  start_zookeeper
}

benchmark_suite_run() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_zookeeper-status
  #stop_zookeeper
}

  benchmark_zookeeper-status() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_zookeeper "$bench_name" ' status' "time"
}
