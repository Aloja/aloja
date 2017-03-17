# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

# The common_BigBenchSchedule.sh script will in turn source the original
# common_BigBench.sh script
source_file "$ALOJA_REPO_PATH/shell/common/common_BigBenchSchedule.sh"
set_BigBench_requires

workloadFile="$ALOJA_REPO_PATH/config/schedule/sampleWorkloadTiny.txt"
scheduleFile="$ALOJA_REPO_PATH/config/schedule/schedule.txt"
generatedScript="$ALOJA_REPO_PATH/config/schedule/executeSchedule.sh"
logFile="$ALOJA_REPO_PATH/config/schedule/scheduleLog.txt"

if [ "$BENCH_LIST" ] ; then
    user_suplied_bench_list="true"
fi

BENCH_ENABLED="$(seq -f "%g" -s " "  1 30) throughput schedule"
BENCH_EXTRA="throughput schedule"

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
        for scale_factor in $BB_SCALE_FACTORS ; do
            if [ $query == "schedule" ] ; then
            	# $1 workload file, $2 schedule file, $3 output script, $4 output log, $5 scale factor, 
				# $6 batch wait time, #7 batch multiplier, #8 random seed
    			benchmark_schedule "$workloadFile" "$scheduleFile" "$generatedScript" "$logFile" "1" "60" "1" "2345"
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
        done
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

# $1 Supplied workload file
# $2 Schedule file to be generated
# $3 Script file to be generated
# $4 Log file to be generated
# $5 Scale factor
# $6 Batch wait time
# $7 Batch multiplier
# $8 Random seed
benchmark_schedule() {
	local bench_name="${FUNCNAME[0]#benchmark_}"
	logger "INFO: Running $bench_name"
	echo "----------------------EXECUTING SCHEDULE--------------------------"
	cat "$1"
	echo $1
	# Delete the old generated schedule file
	rm "$2"
	# Generate the new schedule file
	# $1 input workload file, $2 output schedule file, $3 batch multiplier
	generateScheduleFile "$1" "$2" "$7" "$8"
	cat "$2"
	echo $2
	# Delete the old generated script file and log file
	rm "$3"
	rm "$4"
	# Generate the execution script
	# $1 schedule file, $2 output script, $3 output log, $4 scale factor, $5 batch wait time
	generateExecutionScript "$2" "$3" "$4" "$5" "$6"
	cat "$3"
	echo $3s
	# Run the command and time it
	execute_master "$bench_name" "bash $3" "time"
  	# Stop metrics monitors and save bench (if needed)
	#if [ "$time_exec" ] ; then
    	save_BigBench "$bench_name"
	#fi
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