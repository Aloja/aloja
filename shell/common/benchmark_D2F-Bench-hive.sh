# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Hive version
# Benchmark to test Hive installation and configurations

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING $query"
    execute_query_hive "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
execute_query_hive() {
  local query="$1"
  execute_hive "$query" "-f $D2F_local_dir/tpch/queries/$query.sql --database $TPCH_DB_NAME" "time"
}