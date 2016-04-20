# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Spark version
# Benchmark to test Hive installation and configurations

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
#set_spark_requires

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING $query"
    execute_query_spark "$query"

  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
execute_query_spark() {
  local query="$1"
  execute_spark "$query" "spark-sql -e \"USE $TPCH_DB_NAME; \$(< $D2F_local_dir/tpch/queries/$query.sql)\"" "time"
}