

set_newBigBench_requires() {
  BENCH_REQUIRED_FILES["BigBench_$QUERY_TYPE"]="$ALOJA_PUBLIC_HTTP/BigBench/Queries/BigBench_$QUERY_TYPE.tar.gz"
}

# $1: Type of queries to execute
initialize_newBigBench_vars() {
  DATASIZE=$BENCH_SCALE_FACTOR
  if [ "$BB_MINIMUM_DATA" == "1" ]; then
    DATASIZE=min
  fi

  DATA_BASENAME="BigBench_$DATASIZE"
  DATA_DIR="$BENCH_LOCAL_DIR/aplic2/newBigBench/$DATA_BASENAME"

  QUERIES_DIR="$(get_local_apps_path)/BigBench_$QUERY_TYPE"
}

prepare_newBigBench_data() {

  if [ ! -d "$BENCH_LOCAL_DIR/aplic2/newBigBench/$DATA_BASENAME" ]; then
    logger "INFO: Downloading BigBench data"
    execute_master "Creating BigBench data local folder" "mkdir -p $DATA_DIR"
    execute_master "Downloading BigBench data" "wget --progress=dot -e dotbytes=10M '$ALOJA_PUBLIC_HTTP/BigBench/Data/$DATA_BASENAME.tar.gz' -O '$DATA_DIR.tar.gz' &&
    tar xzf '$DATA_DIR.tar.gz' -C $BENCH_LOCAL_DIR/aplic2/newBigBench/ && rm $DATA_DIR.tar.gz ;"
  fi
}


## $1 bench
#save_BigBench() {
#  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"
#
#  local bench_name="$1"
#  local bench_name_num="$(get_bench_name_with_num "$bench_name")"
#
#  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/BigBench_logs;"
#  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/BigBench_results;"
#
#  logger "INFO: Saving BigBench query results to $JOB_PATH/$bench_name_num/BigBench_results"
#
#  if [ "$BENCH_LEAVE_SERVICES" ] ; then
#    execute_master "$bench_name" "cp $(get_local_bench_path)/BigBench_logs/* $JOB_PATH/$bench_name_num/BigBench_logs/ 2> /dev/null"
##    execute_hadoop_new "$bench_name" "fs -copyToLocal ${HDFS_DATA_ABSOLUTE_PATH}/queryResults/* $JOB_PATH/$bench_name_num/BigBench_results"
#  else
#    execute_master "$bench_name" "mv $(get_local_bench_path)/BigBench_logs/* $JOB_PATH/$bench_name_num/BigBench_logs/ 2> /dev/null"
##    execute_hadoop_new "$bench_name" "fs -copyToLocal ${HDFS_DATA_ABSOLUTE_PATH}/queryResults/* $JOB_PATH/$bench_name_num/BigBench_results"
##    execute_hadoop_new "$bench_name" "fs -rm ${HDFS_DATA_ABSOLUTE_PATH}/queryResults/*"
#  fi
#
#  # Compressing BigBench config
#  execute_master "$bench_name" "cd  $(get_local_bench_path) && tar -cjf $JOB_PATH/BigBench_conf.tar.bz2 BigBench_conf"
#  save_hive "$bench_name"
#}
