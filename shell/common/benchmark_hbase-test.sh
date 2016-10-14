# Benchmark to test Hbase installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_hbase.sh"
set_hbase_requires

#BENCH_REQUIRED_FILES["tpch-spark"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-spark.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="hbase-version"

benchmark_suite_config() {
#  initialize_hadoop_vars
#  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
#  start_hadoop
#
  initialize_zookeeper_vars
  prepare_zookeeper_config
  start_zookeeper

  initialize_hbase_vars
  prepare_hbase_config
  start_hbase
}

benchmark_hbase-version() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_spark "$bench_name" 'spark-submit --version' "time"
}

#benchmark_SparkPi() {
#  local bench_name="${FUNCNAME[0]##*benchmark_}"
#  logger "INFO: Running $bench_name"
#
#  execute_spark "$bench_name" 'run-example SparkPi $SparkPiSize' "time"
#}