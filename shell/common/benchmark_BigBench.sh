# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"
set_BigBench_requires

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "%g" -s " "  1 30)"

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  if [ "$BB_SERVER_DERBY" == "true" ]; then
    logger "WARNING: Using Derby DB in client/server mode"
    initialize_derby_vars
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

#  logger "INFO: Running throughput test"
#  execute_BigBench "$bench_name" "runBenchmark" "time" #-f scale factor

  for query in $BENCH_LIST ; do
    benchmark_query "$query"
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
#
#benchmark_validateQuery(){
#  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
#  logger "INFO: Running $bench_name"
#  execute_BigBench "$bench_name" "validateQuery -q $1 -U" "time" #-f scale factor
#}