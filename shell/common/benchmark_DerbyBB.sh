# Benchmark to test derby installation, data load and query completion

QUERY_TYPE="SQL"

source_file "$ALOJA_REPO_PATH/shell/common/common_newBigBench.sh"
set_newBigBench_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
set_derby_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST=""

benchmark_suite_config() {
    logger "WARNING: Using Derby DB in client/server mode"
    initialize_derby_vars "BigBench_DB"
    start_derby

    initialize_newBigBench_vars
}

benchmark_suite_cleanup() {
  clean_derby
}

benchmark_suite_run() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  # TODO: review to generate data first time when DELETE_HDFS=0
  if [ "$DELETE_HDFS" == "1" ]; then
    prepare_newBigBench_data
    benchmark_populateDerby
  else
    logger "INFO: Reusing previous RUN BigBench data"
  fi

  for query in $BENCH_LIST ; do
    benchmark_query "$query"
  done
}


benchmark_cleanAll() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "cleanAll -U -z $HIVE_SETTINGS_FILE" "time"
}

benchmark_dataGen() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  logger "INFO: Automatically accepting EULA"

  yes YES | execute_BigBench "$bench_name" "dataGen -U -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}

benchmark_populateDerby() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$(get_local_bench_path)/create_tables.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  cat "$QUERIES_DIR/Load_Derby/createTables.sql" >> $query_file

  execute_derby "$bench_name"  "$query_file" "time"
}

benchmark_query(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"
  execute_derby "$bench_name" "runQuery -q $1 -U -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}

# $1 Number of throughput run
benchmark_throughput() {
  local bench_name="${FUNCNAME[0]#benchmark_}-${BB_PARALLEL_STREAMS}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runBenchmark -U -i THROUGHPUT_TEST_$1 -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}

benchmark_refreshMetastore() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "refreshMetastore -U -z $HIVE_SETTINGS_FILE" "time"
}

benchmark_validateQuery(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "validateQuery -q $1 -U -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}