# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires

[ ! "$BENCH_LIST" ] && BENCH_LIST="spark-version SparkPi"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_spark_vars
  prepare_spark_config
}

benchmark_suite_cleanup() {
  clean_hadoop
}

benchmark_spark-version() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_spark "$bench_name" "--version" "time"
}

benchmark_SparkPi() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local pi_size="100" # Defaults 100 pis if not overidden
  [ "$BENCH_EXTRA_CONFIG" ] && pi_size="$BENCH_EXTRA_CONFIG"

  execute_spark "$bench_name" "--class org.apache.spark.examples.SparkPi $SPARK_HOME/lib/spark-examples*.jar $pi_size" "time"
}