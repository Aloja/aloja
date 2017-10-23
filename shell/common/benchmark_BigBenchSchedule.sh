# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

# The common_BigBenchSchedule.sh script will in turn source the original
# common_BigBench.sh script
source_file "$ALOJA_REPO_PATH/shell/common/common_BigBenchSchedule.sh"
set_BigBench_requires

#workloadFile="$ALOJA_REPO_PATH/config/schedule/max8queries.txt"
workloadFile="$(get_local_configs_path)/BigBench_conf_template/elasticity/max8queries.txt"
logDir="$(get_local_bench_path)/BigBench_logs/"
scheduleFile="$logDir/schedule.txt"
driverJar="$(get_local_apps_path)/${ELASTICITY_DRIVER_FOLDER}/alojabbdriver.jar"
mainExportsFile="$logDir/mainExports.sh"

if [ "$BENCH_LIST" ] ; then
    user_suplied_bench_list="true"
fi

BENCH_ENABLED="$(seq -f "%g" -s " "  1 30) throughput schedule"
BENCH_EXTRA="throughput schedule"

if [ ! $BB_QUERIES ]; then
    BB_QUERIES="6 7 9 11 12 13 14 15 16 17 21 22 23 24"
fi
if [ ! $BB_PROBABILITIES ]; then
    BB_PROBABILITIES="0.0 1.0"
fi


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

  if [ "$BB_MODE" == "parallel" ]; then
      echo $BENCH_LIST
      if ! inList "$BENCH_LIST" "throughput" ; then
        benchmark_parallel_power

      else
        benchmark_parallel_throughput "1"
      fi

  else
      for query in $BENCH_LIST ; do
        # for scale_factor in $BB_SCALE_FACTORS ; do
            if [ $query == "schedule" ] ; then
            	# $1 Supplied workload file
				# $2 Schedule file to be generated
				# $3 Log directory
				# $4 Batch multiplier
				# $5 Random seed
				# $6 Degree of parallelism
				# $7 Maximum number of queries
				# $8 Batch wait time
				# $9 Spread queries across batch
				# ${10} Thread pool size
				# ${11} Queries degree of parallelism table file (null to use default)
				# ${12} time (internal to aloja)
				# ${13} enable void batches
    			execute_BigBench_schedule "$workloadFile" "$scheduleFile" "$logDir" "1.0" "2345" "5" "4" "60" "false" "4" "null" "time" "false"
            elif [ ! $query == "throughput" ] ; then
              benchmark_query "$query" "$scale_factor"
              if [ "$scale_factor" == 1 ] ; then
                benchmark_validateQuery "$query" "$scale_factor"
              fi
            else
              benchmark_throughput "1" "$scale_factor"
            #      benchmark_refreshMetastore "$scale_factor"
            #      benchmark_throughput "2" "$scale_factor"
            fi
        # done
      done
  fi
}

benchmark_cleanAll() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "cleanAll -U -z $BIG_BENCH_PARAMETERS_FILE" "time"
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
benchmark_query(){
  local scale_factor="$2"
  local bench_name="BB_${scale_factor}_${FUNCNAME[0]#benchmark_}-$1"

  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runQuery -q $1 -U -z ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor" "time" "$scale_factor"
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

