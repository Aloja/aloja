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
    for scale_factor in $BB_SCALE_FACTORS; do
        if [ $scale_factor == "min" ]; then
          logger "INFO: Using BigBench minimum dataset (170 MB)"
          BENCH_DATA_SIZE=170000000 #170MB
          prepare_BigBench_minimum_dataset
          benchmark_populateMetastore "min"
        else
          logger "INFO: Generating BigBench data"
          benchmark_dataGen $scale_factor
          benchmark_populateMetastore $scale_factor
        fi
    done
  else
    logger "INFO: Reusing previous RUN BigBench data"
  fi

  benchmark_query "6" $BENCH_SCALE_FACTOR "6-1" &
  sleep 150

  benchmark_query "7" $BENCH_SCALE_FACTOR "7-1" &
  sleep 30

  benchmark_query "6" $BENCH_SCALE_FACTOR "6-2" &
  sleep 100

  benchmark_query "9" $BENCH_SCALE_FACTOR "9-1" &
  sleep 340

  benchmark_query "6" $BENCH_SCALE_FACTOR "6-3" &
  sleep 30

  benchmark_query "7" $BENCH_SCALE_FACTOR "7-2" &
  sleep 300

  benchmark_query "6" $BENCH_SCALE_FACTOR "6-4" &
  sleep 10

  benchmark_query "9" $BENCH_SCALE_FACTOR "9-2" &
  sleep 10

  benchmark_query "9" $BENCH_SCALE_FACTOR "9-3" &
  sleep 10

  benchmark_query "9" $BENCH_SCALE_FACTOR "9-4" &
  sleep 10

  benchmark_query "9" $BENCH_SCALE_FACTOR "9-5"

  wait

}

benchmark_cleanAll() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  local cmd

  for scale_factor in $BB_SCALE_FACTORS ; do
    cmd+="cleanAll -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor; "
  done

  execute_BigBench "$bench_name" "$cmd" "time"
}

# $1: Scale factor to use
benchmark_dataGen() {
  local scale_factor="$1"
  local bench_name="BB_$scale_factor_${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  logger "INFO: Automatically accepting EULA"

  execute_BigBench "$bench_name" "dataGen -U -f $scale_factor -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
}

# $1: Scale factor to use
benchmark_populateMetastore() {
  local scale_factor="$1"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}"

  logger "INFO: Running $bench_name"

  echo "$bench_name"
  execute_BigBench "$bench_name" "populateMetastore -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
}

# $1: Query to execute
# $2: Scale factor to use
# $3: Instance of the query
benchmark_query(){
  local scale_factor="$2"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}-$1_$3"

  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runQuery -q $1 -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor" "$3"
}

benchmark_parallel_power() {
  local bench_name="BB__${FUNCNAME[0]#benchmark_}-$1"

  for query in $BENCH_LIST ; do
      local cmd=""

      for scale_factor in $BB_SCALE_FACTORS ; do
        cmd+="runQuery -q $query -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor;"
      done
      echo "CMD:
      $cmd"
      echo "done"
      execute_parallel_BigBench "$bench_name-$query" "$cmd" "time"
  done

  logger "INFO: Running $bench_name"
#  execute_parallel_BigBench "$bench_name" "$cmd" "time"

}

# $1 Number of throughput run
# $2 Scale factor to use
benchmark_throughput() {
  local scale_factor="$2"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}-${BB_PARALLEL_STREAMS}"

  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runBenchmark -U -i THROUGHPUT_TEST_$1 -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
}

# $1 Number of throughput run
# $2 Scale factor to use
benchmark_parallel_throughput() {
  local bench_name="BB__${FUNCNAME[0]#benchmark_}-${BB_PARALLEL_STREAMS}"
  local cmd

  for scale_factor in $BB_SCALE_FACTORS ; do
    cmd+="runBenchmark -U -i THROUGHPUT_TEST_$1 -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor;"
  done

  logger "INFO: Running $bench_name"
  execute_parallel_BigBench "$bench_name" "$cmd" "time"
}

benchmark_refreshMetastore() {
  local scale_factor="$1"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}"

  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "refreshMetastore -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
}

benchmark_validateQuery(){
  local scale_factor="$2"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}-$1"

  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "validateQuery -q $1 -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
}