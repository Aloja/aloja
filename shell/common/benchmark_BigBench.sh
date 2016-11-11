# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"
set_BigBench_requires

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "%g" -s " "  1 30)"

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"

  if [ "$ENGINE" == "spark" ]; then
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
    benchmark_dataGen
  else
    logger "INFO: Reusing previous RUN BigBench data"
  fi

  if [ "$BIGBENCH_LOAD_METASTORE" == "1" ]; then
    benchmark_populateMetastore
  else
    logger "INFO: Reusing previous Hive Metastore"
  fi

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
  execute_BigBench "$bench_name" "cleanQueries" "time"
}

benchmark_cleanMetastore() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "cleanMetastore" "time"
}

benchmark_dataGen() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  logger "INFO: Automatically accepting EULA"

  yes YES | execute_BigBench "$bench_name" "dataGen" "time" #-f scale factor
}

benchmark_populateMetastore() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "populateMetastore" "time"
}

benchmark_query(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runQuery -q $1" "time" #-f scale factor
}

benchmark_validateQuery(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "validateQuery -q $1" "time" #-f scale factor
}