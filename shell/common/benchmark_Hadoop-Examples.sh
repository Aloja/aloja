# Benchmark suite for Hadoop examples
# Some of the options are based in HiBench https://github.com/intel-hadoop/HiBench

# Downalod the Hadoop examples jar
# we use the same jar for all executions of the same MR API version, to compare the same code
BENCH_REQUIRED_FILES["Hadoop-Examples"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/Hadoop-Examples.tar.gz"

# List of allowed benchmarks (for validation)
BENCH_ENABLED="wordcount terasort teravalidate dfsio grep sort"

# Check supplied benchmarks
check_bench_list


# list of benchmarks that require a previous benchmark run
BENCH_VALIDATES="teravalidate"
# if a validate is specified, we add it to a different list so that we don't iterate it later
BENCH_VALIDATES="$(get_bench_validates "$BENCH_LIST" "$BENCH_VALIDATES")"
BENCH_LIST="$(remove_bench_validates "$BENCH_LIST" "$BENCH_VALIDATES")"

# Some benchmark specific validations
[ ! "$BENCH_DATA_SIZE" ] && die "BENCH_DATA_SIZE is not set, cannot continue"

# Load Hadoop functions
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Set the Hadoop examples jar (it is not compatible between MR v1 and v2
if [ "$(get_hadoop_major_version)" == "2" ]; then
  examples_jar="$(get_local_apps_path)/Hadoop-Examples/hadoop-mapreduce-examples-2.7.1.jar"
  #examples_jar="\$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar"
  tests_jar="$(get_local_apps_path)/Hadoop-Examples/hadoop-common-2.7.1-tests.jar"
  mapreduce_jar="$(get_local_apps_path)/Hadoop-Examples/hadoop-mapreduce-client-jobclient-2.7.1-tests.jar"
else
  examples_jar="$(get_local_apps_path)/Hadoop-Examples/hadoop-examples-1.2.1.jar"
  tests_jar="$(get_local_apps_path)/Hadoop-Examples/hadoop-test-1.2.1.jar"
fi

# Benchmark specific globals

# regular expression for grep
if [ ! "$GREP_REGEX" ]; then
  GREP_REGEX=".oo."
fi

# size of each file in MB
if [ ! "$DFSIO_FILE_SIZE" ]; then
  #DFSIO_FILE_SIZE="$(( BENCH_DATA_SIZE / DFSIO_NUM_FILES / 1000000 ))" #in MBs
  DFSIO_FILE_SIZE="100" # in MBs
fi

# TestDFSIO input parameters
# number of files to write/read
if [ ! "$DFSIO_NUM_FILES" ]; then
  #DFSIO_NUM_FILES="10"
  DFSIO_NUM_FILES="$(( BENCH_DATA_SIZE / DFSIO_FILE_SIZE / 1000000  ))"
fi



BENCH_randomtextwriter_RAN="" # Avoids running multiple times the datagen used by wordcount, grep, and sort

# Configure and start Hadoop
benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop
}

benchmark_suite_cleanup() {
  # Delete HDFS generated files to cleanup by default
  if [ ! "$BENCH_LEAVE_SERVICES" ] && [ ! "$BENCH_KEEP_FILES" ]; then
    log_INFO "Deleting generated HDFS files in $BENCH_SUITE"
    hadoop_delete_path "Delete_$BENCH_SUITE" "$BENCH_SUITE"
  else
    log_WARN "Leaving HDFS benchmark files as requested"
  fi

  clean_hadoop
}

# wrapper for randomtextwriter
benchmark_prepare_wordcount() {
  benchmark_randomtextwriter
}

benchmark_randomtextwriter() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"

  if [ ! "$BENCH_randomtextwriter_RAN" ] ; then
    logger "INFO: Running $bench_name"

    logger "INFO: making sure $bench_input_dir dir is empty first"
    hadoop_delete_path "$bench_name" "$bench_input_dir"

    if [ "$(get_hadoop_major_version)" == "2" ]; then
      local extra_configs="-D mapreduce.randomtextwriter.totalbytes=$BENCH_DATA_SIZE"
    else
      local extra_configs="-D test.randomtextwrite.total_bytes=$BENCH_DATA_SIZE"
    fi

    execute_hadoop_new "$bench_name" "jar $examples_jar randomtextwriter $(get_hadoop_job_config) $extra_configs $bench_input_dir" "time"

    BENCH_randomtextwriter_RAN="1"
  else
    log_INFO "Data already generated"
  fi
}

benchmark_wordcount() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"

  local extra_configs
  extra_configs+=" -D mapreduce.inputformat.class=org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat"
  extra_configs+=" -D mapreduce.outputformat.class=org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat"
  extra_configs+=" -D mapreduce.job.inputformat.class=org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat"
  extra_configs+=" -D mapreduce.job.outputformat.class=org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat"

  execute_hadoop_new "$bench_name" "jar $examples_jar wordcount $(get_hadoop_job_config) $extra_configs $bench_input_dir $bench_output_dir" "time"
}

# wrapper for teragen
benchmark_prepare_terasort() {
  benchmark_teragen
}

benchmark_teragen() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_input_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_input_dir"

  # Teragen uses 100 byte rows, need to divide the datasize
  local teragen_data_size="$(( $BENCH_DATA_SIZE /100 ))"
  [ ! "$teragen_data_size" ] && die "Cannot determine teragen data size"

  execute_hadoop_new "$bench_name" "jar $examples_jar teragen $(get_hadoop_job_config) $teragen_data_size $bench_input_dir" "time"
}

benchmark_terasort() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"

  execute_hadoop_new "$bench_name" "jar $examples_jar terasort $(get_hadoop_job_config) $bench_input_dir $bench_output_dir" "time"
}

# wrapper for teravalidate
benchmark_validate_terasort() {
  benchmark_teravalidate
}

benchmark_teravalidate() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  # Check if it was selected
  if inList "$BENCH_VALIDATES" "$bench_name" ; then
    logger "INFO: Running $bench_name"

    local teravalidate_input_dir="$bench_output_dir"
    local teravalidate_output_dir="$BENCH_SUITE/$bench/validate_output"

    logger "INFO: making sure $bench_output_dir dir is empty first"
    hadoop_delete_path "$bench_name" "$teravalidate_output_dir"

    execute_hadoop_new "$bench_name" "jar $examples_jar teravalidate $(get_hadoop_job_config) $teravalidate_input_dir $teravalidate_output_dir" "time"
  else
    logger "INFO: not running validation, $bench_name not especified in BENCH_LIST"
  fi
}

# wrapper for sort
benchmark_prepare_sort() {
  benchmark_randomtextwriter
}

benchmark_sort() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"

  local extra_configs
  extra_configs+=" -outKey org.apache.hadoop.io.Text"
  extra_configs+=" -outValue org.apache.hadoop.io.Text"

  execute_hadoop_new "$bench_name" "jar $examples_jar sort $(get_hadoop_job_config) $extra_configs $bench_input_dir $bench_output_dir" "time"
}

# wrapper for TestDFSIO prepare
benchmark_prepare_dfsio() {
  # execute the write dfsio to generate files for the read dfsio
  benchmark_dfsio_write
}

# wrapper for TestDFSIO
benchmark_dfsio_write() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    execute_hadoop_new "$bench_name" "jar $mapreduce_jar TestDFSIO $(get_hadoop_job_config) -write -nrFiles $DFSIO_NUM_FILES -fileSize $DFSIO_FILE_SIZE -resFile $(get_local_bench_path)/TestDFSIOwrite.report" "time"
  else
    execute_hadoop_new "$bench_name" "jar $tests_jar TestDFSIO $(get_hadoop_job_config) -write -nrFiles $DFSIO_NUM_FILES -fileSize $DFSIO_FILE_SIZE $bench_output_dir" "time"
  fi
}

# wrapper for TestDFSIO read
benchmark_dfsio() {
  benchmark_dfsio_read
}

benchmark_dfsio_read() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"

  if [ "$(get_hadoop_major_version)" == "2" ]; then
    execute_hadoop_new "$bench_name" "jar $mapreduce_jar TestDFSIO $(get_hadoop_job_config) -read -nrFiles $DFSIO_NUM_FILES -fileSize $DFSIO_FILE_SIZE -resFile $(get_local_bench_path)/TestDFSIOread.report" "time"
  else
    execute_hadoop_new "$bench_name" "jar $tests_jar TestDFSIO $(get_hadoop_job_config) -read -nrFiles $DFSIO_NUM_FILES -fileSize $DFSIO_FILE_SIZE $bench_output_dir" "time"
  fi
}

# wrapper for grep
benchmark_prepare_grep() {
  benchmark_randomtextwriter
}

benchmark_grep() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  logger "INFO: making sure $bench_output_dir dir is empty first"
  hadoop_delete_path "$bench_name" "$bench_output_dir"

  execute_hadoop_new "$bench_name" "jar $examples_jar grep $(get_hadoop_job_config) $bench_input_dir $bench_output_dir $GREP_REGEX" "time"
}
