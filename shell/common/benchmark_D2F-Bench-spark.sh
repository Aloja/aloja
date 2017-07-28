# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Benchmark to test Spark installation and configurations

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  BENCH_CURRENT_NUM_RUN="1" #reset the global counter

  mkdir /scratch/local/aloja-bench_3/spark_conf
  cp /scratch/local/aloja-bench_3/hive_conf/hive-site.xml /scratch/local/aloja-bench_3/spark_conf
  #prepare_config

  # Iterate at least one time
  while true; do
    [ "$BENCH_NUM_RUNS" ] && logger "INFO: Starting iteration $BENCH_CURRENT_NUM_RUN of $BENCH_NUM_RUNS"

    for query in $BENCH_LIST ; do
      logger "INFO: RUNNING $query of $BENCH_NUM_RUNS runs"
      execute_query_spark "$query"
    done

    # Check if requested to iterate multiple times
    if [ ! "$BENCH_NUM_RUNS" ] || [[ "$BENCH_CURRENT_NUM_RUN" -ge "$BENCH_NUM_RUNS" ]] ; then
      break
    else
      BENCH_CURRENT_NUM_RUN="$((BENCH_CURRENT_NUM_RUN + 1))"
    fi
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
execute_query_spark() {
  local query="$1"
  execute_spark-sql "$query" "-e \"USE $TPCH_DB_NAME; \$(< $D2F_local_dir/tpch/queries/$query.sql)\"" "time"
}

prepare_config() {
  
  # Spark needs the hive-site.xml to access metastore
  # common-spark.sh seems not to work properly
  mkdir $(get_local_bench_path)/spark_conf
  cp $(get_local_bench_path)/hive_conf/hive-site.xml $(get_local_bench_path)/spark_conf

}
