# Benchmark definition file for HiBench2

# 1.) Load sources
# Load Hadoop and java functions and defaults
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

benchmark_config() {
  initialize_hadoop_vars
  #initialize_HiBench_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH"
  restart_hadoop
}

benchmark_run() {
  logger "INFO: Executing $BENCH in all nodes"

  restart_monit
  set_bench_start "$BENCH"

  ################# START BENCHMARK CUSTOM CODE HERE ####################

#  if [ "$(get_hadoop_major_version)" == "1" ]; then
#    hadoop_cmd="$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -rmr $folder_in_HDFS"
#  elif [ "$(get_hadoop_major_version)" == "2" ] ; then
#    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r $folder_in_HDFS"
#  else
#    die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
#  fi

  local in_dir="$BENCH/input"
  local out_dir="$BENCH/output"
  execute_hadoop_new "$BENCH" "jar \$HADOOP_HOME/hadoop-examples-*.jar randomtextwriter $in_dir"
  execute_hadoop_new "$BENCH" "jar \$HADOOP_HOME/hadoop-examples-*.jar wordcount $in_dir $out_dir"

  ################# END BENCHMARK CUSTOM CODE HERE   ####################

  set_bench_end "$BENCH"
  stop_monit

  logger "INFO: DONE executing $BENCH"
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