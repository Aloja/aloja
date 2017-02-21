# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"
set_BigBench_requires

if [ "$BENCH_LIST" ] ; then
    user_suplied_bench_list="true"
fi

BENCH_ENABLED="$(seq -f "%g" -s " "  1 30) throughput"
BENCH_EXTRA="throughput"

# Check supplied benchmarks
check_bench_list

if [ ! $user_suplied_bench_list ]; then
    BENCH_LIST="$(remove_bench_validates "$BENCH_LIST" "$BENCH_EXTRA")"
fi

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  if [ "$BB_SERVER_DERBY" == "true" ]; then
    logger "WARNING: Using Derby DB in client/server mode"
    USE_EXTERNAL_DATABASE="true"
    initialize_derby_vars "BigBench_DB"
    start_derby
  else
    logger "WARNING: Using Derby DB in embedded mode"
  fi

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"

  if [ "$ENGINE" == "spark_sql" ] || [ "$HIVE_ML_FRAMEWORK" == "spark" ]; then
    initialize_spark_vars
    prepare_spark_config
  fi

  if [ "$HIVE_ENGINE" == "tez" ]; then
    initialize_tez_vars
    prepare_tez_config
fi

  initialize_BigBench_vars
  prepare_BigBench
}

benchmark_suite_cleanup() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"

  if [ "$BB_SERVER_DERBY" == "true" ]; then
    clean_derby
  fi
  clean_hadoop
}

benchmark_suite_run() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  # TODO: review to generate data first time when DELETE_HDFS=0
  if [ "$DELETE_HDFS" == "1" ]; then
    benchmark_cleanAll
    if [ "$BB_MINIMUM_DATA" == "1" ]; then
      logger "INFO: Using BigBench minimum dataset (170 MB)"
      BENCH_DATA_SIZE=170000000 #170MB
      prepare_BigBench_minimum_dataset
    else
      logger "INFO: Generating BigBench data"
      benchmark_dataGen
    fi
    benchmark_populateMetastore
  else
    logger "INFO: Reusing previous RUN BigBench data"
  fi

  for query in $BENCH_LIST ; do
    if [ ! $query == "throughput" ] ; then
      benchmark_query "$query"
    else
      benchmark_throughput
    fi
  done

#  for query in $BENCH_LIST ; do
#    benchmark_validateQuery "$query"
#  done
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

benchmark_populateMetastore() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "populateMetastore -U -z $HIVE_SETTINGS_FILE" "time"
}

benchmark_query(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runQuery -q $1 -U -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}

benchmark_throughput() {
  local bench_name="${FUNCNAME[0]#benchmark_}-${BB_PARALLEL_STREAMS}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runBenchmark -U -i THROUGHPUT_TEST_1 -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}
#benchmark_validateQuery(){
#  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
#  logger "INFO: Running $bench_name"
#  execute_BigBench "$bench_name" "validateQuery -q $1 -U" "time" #-f scale factor
#}