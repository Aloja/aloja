# Source the original script and add functions
source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"

# Returns the the path to the BigBench binary, the proper exports are
#assumed to be set already
get_BigBench_cmd_schedule() {
  local BigBench_cmd
  BigBench_bin="$(get_local_apps_path)/${BIG_BENCH_FOLDER}/bin/bigBench"
  BigBench_cmd="$BigBench_bin"
  echo -e "$BigBench_cmd"
}

# Helper to print a line with required exports for a particular query
# $1 scale factor to use
# $2 batch number
get_BigBench_exports_query() {
  local to_export
  to_export="
    export BIG_BENCH_LOGS_DIR='$(get_local_bench_path)/BigBench_logs/bigbench_$1/batch_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_QUERY_RESULT_DIR='$HDFS_DATA_ABSOLUTE_PATH/query_results/bigbench_$1/batch_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_TEMP_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1/batch_$2/temp';
    export BIG_BENCH_HDFS_ABSOLUTE_INIT_DATA_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1/base';
    export BIG_BENCH_DEFAULT_DATABASE='bigbench_$1';
    #################################### IMPORTANT #################################################
    export HADOOP_OPTS=' -Djava.io.tmpdir=./tmp ';"
  echo -e "$to_export\n"
}

get_BigBenchElasticity_substitutions() {
  #TODO spacing when a @ is found
    cat <<EOF
s,##ELASTICITY_WORKLOAD_FILE##,$ELASTICITY_WORKLOAD_FILE,g
EOF
}

prepare_BigBenchElasticity() {
 #Assumes prepare_BigBench has been called. 
 logger "INFO: Preparing BigBenchSchedule"
  # Get the values
  subs=$(get_BigBenchElasticity_substitutions)
  logger "INFO: Making substitutions"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $BIG_BENCH_CONF_DIR/elasticity/elasticitySettings.conf"
}

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
execute_BigBench_schedule() {
	local bench_name="${FUNCNAME[0]#benchmark_}"
	logger "INFO: Running $bench_name"

	local time_exec="$12"
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
	# args[2] logs dir
	# args[3] batch multiplier
	# args[4] random seed
	# args[5] queries array
	# args[6] scale factors array
	# args[7] probabilities array
	# args[8] default degree of parallelism
	# args[9] queries degree of parallelism table file (null to use default)
	# args[10] max queries
	# args[11] enable void batches
	# Generate the new schedule file
	# Use -cp instead of -jar in order to run a class which is not the Main-Class of the jar.
	javaGenCmd='$JAVA_HOME/bin/java -cp $driverJar io.bigdatabenchmark.v1.driver.ScheduleGenerator '
	javaGenCmd+='$1 $2 $3 $4 $5 "$BB_QUERIES" "$BB_SCALE_FACTORS" "$BB_PROBABILITIES" $6 ${11} $7 ${13}'
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
	# args[4] batch wait time in seconds
	# args[5] spread queries (true/false) spread evenly the queries within a batch and ignore internal batch delay
	# args[6] maximum number of queries to execute for the run
	javaCmd+="${10} AlojaHiveWrapper $2 $3 $8 $9 $7"
	echo "$javaCmd"
	# The following line executes the java command as a simple shell command
	# $javaCmd
	# Run the command and time it
	# execute_master "$bench_name" "bash $3" "time"
	# Apparently, from within java the environment variables exported by sourcing the mainExportsFile
	# are not available when invoking System.getenv() if execute_master is used. Therefore in the java
	# driver the scripts to execute individual queries must have all the exports.
	execute_master "$bench_name" "$javaCmd" "$time_exec" "dont_save"
  	# Stop metrics monitors and save bench (if needed)
	if [ "$time_exec" ] ; then
    	save_BigBench "$bench_name"
	fi
}

