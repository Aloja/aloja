# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_pig.sh"
set_pig_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="pig-test"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_pig_vars
#  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
}

benchmark_suite_cleanup() {
  clean_hadoop
}

benchmark_pig-test() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_pig "$bench_name" "--version" ""
}