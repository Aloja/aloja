# Benchmark to test HBase installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_hbase.sh"
set_hbase_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="hbase_create hbase_insert hbase_drop"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hbase_vars
  prepare_hbase_config "$HBASE_SETTINGS_FILE" "$HBASE_SETTINGS_FILE_PATH"
  start_hbase
}

benchmark_suite_cleanup() {
  clean_hbase
  clean_hadoop
}

benchmark_hbase_create() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"create \\\"usertable\\\", \\\"family\\\";\"" "time"
}

benchmark_hbase_insert() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"put \\\"usertable\\\",\\\"row1\\\",\\\"family:testcol\\\",\\\"42\\\";\"" "time"
}

benchmark_hbase_drop() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"disable \\\"usertable\\\"; drop \\\"usertable\\\";\"" "time"
}

