# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"
set_BigBench_requires

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "%g" -s " " 1 30)"

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"

  initialize_BigBench_vars
  prepare_BigBench
}

benchmark_suite_run() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

#  logger "INFO: Cleaning queries (if any)"
#  execute_BigBench "$bench_name" "cleanQueries" "time"
#
#  logger "INFO: Cleanning metastore"
#  execute_BigBench "$bench_name" "cleanMetastore" "time"
#
#  logger "INFO: generating Data"
#  logger "INFO: Automatically accepting EULA"
#  yes YES | execute_BigBench "$bench_name" "dataGen -m $MAX_MAPS -C $(get_BigBench_conf_dir)/userSettings.conf" "time" #-f scale factor
#
#  logger "INFO: populating metastore"
#  execute_BigBench "$bench-_name" "populateMetastore" "time"

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING QUERY $query"
    execute_BigBench "$query" "runQuery -q $query -C $(get_BigBench_conf_dir)/userSettings.conf" "time" #-f scale factor
  done

}