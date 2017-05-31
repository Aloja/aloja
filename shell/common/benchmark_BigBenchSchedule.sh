# Big Bench implementation more on: https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/

# The common_BigBenchSchedule.sh script will in turn source the original
# common_BigBench.sh script
source_file "$ALOJA_REPO_PATH/shell/common/common_BigBenchSchedule.sh"
set_BigBench_requires

workloadFile="$ALOJA_REPO_PATH/config/schedule/sampleWorkloadTiny.txt"
scheduleFile="$ALOJA_REPO_PATH/config/schedule/schedule.txt"
javaScheduleFile="schedule.txt"
generatedScript="$ALOJA_REPO_PATH/config/schedule/executeSchedule.sh"
logFile="$ALOJA_REPO_PATH/config/schedule/scheduleLog.txt"
logDir="$ALOJA_REPO_PATH/config/schedule/"
driverJar="$ALOJA_REPO_PATH/config/schedule/alojabbdriver.jar"
mainExportsFile="$ALOJA_REPO_PATH/config/schedule/mainExports.sh"

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
        # for scale_factor in $BB_SCALE_FACTORS ; do
            if [ $query == "schedule" ] ; then
            	# $1 workload file, $2 schedule file, $3 output script, $4 output log, $5 scale factor, $6 batch wait time, $7 batch multiplier,
				# $8 random seed, $9 batch internal delay factor, ${10} degree of parallelism, ${11} spread queries, ${12} max queries
    			benchmark_schedulejavagen "$workloadFile" "$javaScheduleFile" "$generatedScript" "$logFile" "1" "120" "0.3" "2345" "0" "1" "true" "4"
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

# $1 Supplied workload file
# $2 Schedule file to be generated
# $3 Script file to be generated
# $4 Log file to be generated
# $5 Scale factor (no longer effective, multiple scale factors are supported and exports are now done for each query)
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
	echo $3
	# Run the command and time it
	execute_master "$bench_name" "bash $3" "time"
  	# Stop metrics monitors and save bench (if needed)
	#if [ "$time_exec" ] ; then
    	save_BigBench "$bench_name"
	#fi
}

# $1 Supplied workload file
# $2 Schedule file to be generated
# $3 Script file to be generated (not used for the java version)
# $4 Log file to be generated
# $5 Scale factor (no longer effective, multiple scale factors are supported and exports are now done for each query)
# $6 Batch wait time
# $7 Batch multiplier
# $8 Random seed
benchmark_schedulejava() {
	local bench_name="${FUNCNAME[0]#benchmark_}"
	logger "INFO: Running $bench_name"
	echo "----------------------EXECUTING SCHEDULE--------------------------"
	cat "$1"
	echo $1
	# Delete the old generated schedule file
	rm "$2"
	# Generate the new schedule file
	# $1 input workload file, $2 output schedule file, $3 batch multiplier, $4 random seed
	generateScheduleFile "$1" "$2" "$7" "$8"
	cat "$2"
	echo $2
	rm $mainExportsFile
	mainExports="$(get_BigBench_exports  "$5")"
	printf "%s\n" "$mainExports"  >> $mainExportsFile
	# sourcing the script may not make available the environment variables within java
	# if execute_master is used (more comments below)
	source $mainExportsFile
	echo "RUNNING JAVA ALOJABBDRIVER"
	bbBinary="$(get_BigBench_cmd_schedule)"
	localBenchPath="$(get_local_bench_path)"
	javaCmd="$JAVA_HOME/bin/java -Dalojarepo.path=$ALOJA_REPO_PATH -Dbigbench.binary=$bbBinary "
	javaCmd+="-Dmainexports.file=$mainExportsFile -Dhdfsdata.absolutepath=$HDFS_DATA_ABSOLUTE_PATH "
	javaCmd+="-Dlocalbench.path=$localBenchPath "
	javaCmd+="-Dbigbench.paramsfile=$BIG_BENCH_PARAMETERS_FILE -jar $driverJar "
	# args[0] thread pool size
	# args[1] wrapper for the engine 
	# args[2] schedule file
	# args[3] log file directory
	# args[4] scale factor (now unused)
	# args[5] batch wait time in seconds
	javaCmd+="6 AlojaHiveWrapper $scheduleFile $logDir $5 $6"
	echo $javaCmd
	# $javaCmd
	# Delete the old generated script file and log file
	rm "$4"
	# Run the command and time it
	# execute_master "$bench_name" "bash $3" "time"
	# Apparently, from within java the environment variables exported by sourcing the mainExportsFile
	# are not available when invoking System.getenv() if execute_master is used. Therefore in the java
	# driver the scripts to execute individual queries must have all the exports.
	execute_master "$bench_name" "$javaCmd" "time"
  	# Stop metrics monitors and save bench (if needed)
	#if [ "$time_exec" ] ; then
    	save_BigBench "$bench_name"
	#fi
}

# $1 Supplied workload file
# $2 Schedule file to be generated
# $3 Script file to be generated (not used for the java version)
# $4 Log file to be generated
# $5 Scale factor (no longer effective, multiple scale factors are supported and exports are now done for each query)
# $6 Batch wait time
# $7 Batch multiplier
# $8 Random seed
# $9 Batch internal delay factor
# ${10} Degree of parallelism
# ${11} Spread queries across batch
# ${12} Maximum number of queries to execute in the batch
benchmark_schedulejavagen() {
	# Set the queries to choose from
	# This line enables all 30 queries (specified as a sequence)
	# queries="\"1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30\""
	# This line enables only particular queries (e.g. only SQL queries)
	queries="\"6 7 9 11 12 13 14 15 16 17 21 22 23 24\""
	scaleFactorsArray="\"1 10\""
	probsArray="\"0.0 0.99999 1.0\""
	local bench_name="${FUNCNAME[0]#benchmark_}"
	logger "INFO: Running $bench_name"
	echo "----------------------EXECUTING SCHEDULE--------------------------"
	cat "$1"
	echo $1
	# Delete the old generated schedule file
	rm "$2"
	# mainExports sets JAVA_HOME, which is needed by the schedule generator
	rm $mainExportsFile
	mainExports="$(get_BigBench_exports  "$5")"
	printf "%s\n" "$mainExports"  >> $mainExportsFile
	# sourcing the script may not make available the environment variables within java
	# if execute_master is used (more comments below)
	source $mainExportsFile
	# args[0] input workload file
	# args[1] output schedule file
	# args[2] output directory
	# args[3] batch multiplier
	# args[4] random seed
	# args[5] queries array
	# args[6] scale factors array
	# args[7] probabilities array
	# args[8] batch internal delay factor
	# args[9] deegree of parallelism
	# Generate the new schedule file
	# Use -cp instead of -jar in order to run a class which is not the Main-Class of the jar.
	javaGenCmd="$JAVA_HOME/bin/java -cp $driverJar io.bigdatabenchmark.v1.driver.ScheduleGenerator "
	javaGenCmd+="$1 $2 $logDir $7 $8 $queries $scaleFactorsArray $probsArray $9 ${10}"
	echo $javaGenCmd
	# Use eval because of the escaped quotes in the arrays
	eval $javaGenCmd
	cat "$2"
	echo $2
	echo "RUNNING JAVA ALOJABBDRIVER"
	bbBinary="$(get_BigBench_cmd_schedule)"
	localBenchPath="$(get_local_bench_path)"
	javaCmd="$JAVA_HOME/bin/java -Dalojarepo.path=$ALOJA_REPO_PATH -Dbigbench.binary=$bbBinary "
	javaCmd+="-Dmainexports.file=$mainExportsFile -Dhdfsdata.absolutepath=$HDFS_DATA_ABSOLUTE_PATH "
	javaCmd+="-Dlocalbench.path=$localBenchPath "
	javaCmd+="-Dbigbench.paramsfile=$BIG_BENCH_PARAMETERS_FILE -jar $driverJar "
	# args[0] thread pool size
	# args[1] wrapper for the engine 
	# args[2] schedule file
	# args[3] log file directory
	# args[4] scale factor (now unused)
	# args[5] batch wait time in seconds
	# args[6] degree of parallelism (used for ADLA only)
	# args[7] spread queries (true/false) spread evenly the queries within a batch and ignore internal batch delay
	javaCmd+="6 AlojaHiveWrapper $scheduleFile $logDir $5 $6 ${10} ${11} ${12}"
	echo $javaCmd
	# $javaCmd
	# Delete the old generated script file and log file
	rm "$4"
	# Run the command and time it
	# execute_master "$bench_name" "bash $3" "time"
	# Apparently, from within java the environment variables exported by sourcing the mainExportsFile
	# are not available when invoking System.getenv() if execute_master is used. Therefore in the java
	# driver the scripts to execute individual queries must have all the exports.
	execute_master "$bench_name" "$javaCmd" "time"
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