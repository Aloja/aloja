# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Hive version
# Benchmark to test Hive installation and configurations
HIVE_VERSION=$HIVE2_VERSION
source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

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

    if [ "$HIVE_ENGINE" == "tez" ]; then
      initialize_tez_vars
      prepare_tez_config
    fi

}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  BENCH_CURRENT_NUM_RUN="1" #reset the global counter

  # Iterate at least one time
  while true; do
    [ "$BENCH_NUM_RUNS" ] && logger "INFO: Starting iteration $BENCH_CURRENT_NUM_RUN of $BENCH_NUM_RUNS"

    for query in $BENCH_LIST ; do
      logger "INFO: RUNNING $query of $BENCH_NUM_RUNS runs"
      execute_query_hive "$query"
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
execute_query_hive() {
  local query="$1"
  if [ -f "$D2F_local_dir/tpch/queries/tpch_query2_${query}.sql" ]; then
    execute_hive "$query" "-f $D2F_local_dir/tpch/queries/tpch_query2_${query}.sql --database $TPCH_DB_NAME" "time"
  else
    execute_hive "$query" "-f $D2F_local_dir/tpch/queries/tpch_query${query}.sql --database $TPCH_DB_NAME" "time"
  fi
}