# Benchmark definition file for WordCount

# 1.) Load sources
# Load Hadoop and java functions and defaults
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

#[ ! "$BENCH_LIST" ] &&
#BENCH_LIST="Hecuba-WordCount"

in_dir="$BENCH_SUITE/input"
out_dir="$BENCH_SUITE/output"
job="\$HADOOP_HOME/hadoop-examples-*.jar wordcount $in_dir $out_dir"

[ ! "$INPUT_FILE" ] && INPUT_FILE="$homePrefixAloja/$userAloja/.bashrc"
[ ! "$NUM_RUNS" ] && NUM_RUNS="4"

benchmark_config() {
  initialize_hadoop_vars
  #initialize_HiBench_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  restart_hadoop
}

benchmark_run() {
  logger "INFO: Executing $BENCH_SUITE in all nodes"
BENCH_LIST="Hecuba-WordCount"
  for bench in $BENCH_LIST ; do

    # Prepare

    # Check if the file exists
    local test_action="$($DSH_MASTER "[ -f '$INPUT_FILE' ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
      logger "INFO: deleting previous inputs (if any)"
      execute_hadoop_new "${bench}_prepare" "fs -rmr $in_dir"
      logger "INFO: Loading $INPUT_FILE into Hadoop"
      execute_hadoop_new "${bench}_prepare" "fs -put '$INPUT_FILE' $in_dir" "time"
    else
      die "File $INPUT_FILE could not be found in master node"
    fi


    # Run
    for run_number in $(seq 1 "$NUM_RUNS") ; do
      logger "INFO: making sure output dir is empty first"
      execute_hadoop_new "${bench}_${run_number}" "fs -rmr $out_dir"
      execute_hadoop_new "${bench}_${run_number}" "jar $job" "time"
    done

  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

benchmark_teardown() {
  : # Empty
}

benchmark_save() {
  : # Empty
}

benchmark_cleanup() {
  stop_hadoop
}