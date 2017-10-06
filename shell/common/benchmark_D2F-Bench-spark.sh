# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Benchmark to test Spark installation and configurations
SPARK_VERSION=$SPARK2_VERSION
HIVE_VERSION=$HIVE2_VERSION
use_spark="true"

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires


benchmark_suite_config() {

    initialize_hadoop_vars
    prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
    start_hadoop

    if [ "$BB_SERVER_DERBY" == "true" ]; then
      logger "WARNING: Using Derby DB in client/server mode"
      USE_EXTERNAL_DATABASE="true"
      initialize_derby_vars "TPCH_DB"
      start_derby
    else
      logger "WARNING: Using Derby DB in embedded mode"
    fi

    initialize_hive_vars
    prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
    use_hive="true"

    if [ "$HIVE_ENGINE" == "tez" ]; then
      initialize_tez_vars
      prepare_tez_config
    fi

    initialize_spark_vars
    prepare_spark_config
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  BENCH_CURRENT_NUM_RUN="1" #reset the global counter

  prepare_config

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
  if [ -f "$D2F_local_dir/tpch/queries/tpch_query2_${query}.sql" ]; then
    execute_spark-sql "$query" "-e \"USE $TPCH_DB_NAME; \$(< $D2F_local_dir/tpch/queries/tpch_query2_${query}.sql)\"" "time"
  else
    execute_spark-sql "$query" "-e \"USE $TPCH_DB_NAME; \$(< $D2F_local_dir/tpch/queries/tpch_query${query}.sql)\"" "time"
  fi
}

prepare_config() {

  # Spark needs the hive-site.xml to access metastore
  # common-spark.sh seems not to work properly
  cp "$(get_local_bench_path)"/hive_conf/hive-site.xml "$(get_local_bench_path)"/spark_conf

}
