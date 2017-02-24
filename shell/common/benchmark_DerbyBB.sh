# Benchmark to test derby installation, data load and query completion

QUERY_TYPE="SQL"

source_file "$ALOJA_REPO_PATH/shell/common/common_newBigBench.sh"
set_newBigBench_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
set_derby_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="6 7 9 12 13 14"

benchmark_suite_config() {
    logger "WARNING: Using Derby DB in client/server mode"
    initialize_derby_vars "BigBench_DB"
    start_derby

    initialize_newBigBench_vars
    prepare_newBigBench
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

benchmark_populateDerby() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$LOCAL_QUERIES_DIR/create_tables.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  cat "$QUERIES_DIR/Load_Derby/createTables.sql" >> $query_file

  execute_derby "$bench_name"  "$query_file" "time"

  #Load the data into the tables by a generated script
  load_file=$LOCAL_QUERIES_DIR/load_tables.sql
  echo "connect '$url';" > $load_file

  for f in $DATA_DIR/base/* ; do
    #The table has the same name as the file, minus the extension and it must be in uppercase
    tableName=$(basename "$f")
    #Remove the extension
    tableName="${tableName%.*}"
    #Convert table name to uppercase
    tableName=${tableName^^}
#    fFull=$(realpath "$f")
    stmt="CALL SYSCS_UTIL.SYSCS_IMPORT_TABLE (NULL,'$tableName','$f','|','\"',NULL,0);"
    echo $stmt >> $load_file
  done
  execute_derby "$bench_name"  "$load_file" "time" > $LOCAL_RESULTS_DIR/$bench_name

  save_newBigBench "$bench_name"
}

benchmark_query(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"

  query_file=$LOCAL_QUERIES_DIR/q$1.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  cat "$QUERIES_DIR/Queries/q$1.sql" >> $query_file

  execute_derby "$bench_name" "$query_file" "time" #-f scale factor
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


