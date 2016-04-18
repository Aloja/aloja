# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="hive-now create-database"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
}

benchmark_suite_cleanup() {
  clean_hadoop
}

benchmark_hive-now() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hive "$bench_name" '-e "SELECT from_unixtime(unix_timestamp());"' "time"
}

#benchmark_validate_hive-now() {
#  local bench_name="${FUNCNAME[0]##*benchmark_}"
#  logger "INFO: Running $bench_name"
#
#  local file_content="$(get_local_file "$bench.out")"
#
#  if [[ "$file_content" =~ "$(date +"%Y-%m-%d")" ]] ; then
#    logger "INFO: $bench_name OK"
#  else
#    logger "WARNING: $bench_name KO. Content:\n$file_content"
#  fi
#}

benchmark_create-database() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hive "$bench_name" '-e "CREATE DATABASE testdb;"' "time"
}

#benchmark_validate_create-database() {
#  local bench_name="${FUNCNAME[0]##*benchmark_}"
#  logger "INFO: Running $bench_name"
#
#  local show_output="$(execute_hive "$bench_name" '-e "SHOW DATABASES;"' "time")"
#
#
#  if [[ "$show_output" =~ "testdb" ]] ; then
#    logger "INFO: $bench_name OK"
#  else
#    logger "WARNING: $bench_name KO. Content:\n$file_content"
#  fi
#}