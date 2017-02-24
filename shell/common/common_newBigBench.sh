

set_newBigBench_requires() {
  if [ ! -d "$ALOJA_REPO_PATH/config/newBigBench" ]; then
    BENCH_REQUIRED_FILES["BigBench_$QUERY_TYPE"]="$ALOJA_PUBLIC_HTTP/BigBench/Queries/BigBench_$QUERY_TYPE.tar.gz"
  else
      copy_queries="true"
  fi
}

# $1: Type of queries to execute
initialize_newBigBench_vars() {

  if [ "$BENCH_SCALE_FACTOR" == 0 ] ; then #Should only happen when BENCH_SCALE_FACTOR is not set and BENCH_DATA_SIZE < 1GB
    logger "WARNING: BigBench SCALE_FACTOR is set below minimum value, setting BENCH_SCALE_FACTOR to 1 (1 GB) and recalculating BENCH_DATA_SIZE"
    BENCH_SCALE_FACTOR=1
    BENCH_DATA_SIZE="$((BENCH_SCALE_FACTOR * 1000000000 ))" #in bytes
  fi

  DATASIZE=$BENCH_SCALE_FACTOR
  if [ "$BB_MINIMUM_DATA" == "1" ]; then
    DATASIZE=min
  fi

  DATA_BASENAME="BigBench_$DATASIZE"
  DATA_DIR="$BENCH_LOCAL_DIR/aplic2/newBigBench/$DATA_BASENAME"

  QUERIES_DIR="$(get_local_apps_path)/BigBench_$QUERY_TYPE"

  LOCAL_QUERIES_DIR="$(get_local_bench_path)/newBigBench_queries"
  LOCAL_RESULTS_DIR="$(get_local_bench_path)/newBigBench_results"
}

prepare_newBigBench_data() {

  if [ ! -d "$BENCH_LOCAL_DIR/aplic2/newBigBench/$DATA_BASENAME" ]; then
    logger "INFO: Downloading BigBench data"
    execute_master "Creating BigBench data local folder" "mkdir -p $DATA_DIR"
    execute_master "Downloading BigBench data" "wget --progress=dot -e dotbytes=10M '$ALOJA_PUBLIC_HTTP/BigBench/Data/compressed/$DATA_BASENAME.tar.gz' -O '$DATA_DIR.tar.gz' &&
    tar xzf '$DATA_DIR.tar.gz' -C $BENCH_LOCAL_DIR/aplic2/newBigBench/ && rm $DATA_DIR.tar.gz;"
  fi
}

prepare_newBigBench() {
    $DSH "mkdir -p $LOCAL_QUERIES_DIR"
    $DSH "mkdir -p $LOCAL_RESULTS_DIR"

    if [[ ! -d "$(get_local_apps_path)/BigBench_$QUERY_TYPE" && $copy_queries ]]; then
        logger "WARNING: Detected BigBench queries in aloja repo"
        $DSH  "cp -r $ALOJA_REPO_PATH/config/newBigBench/BigBench_$QUERY_TYPE $(get_local_apps_path)"
      else
        logger "WARNING: Not copying queries to aplication folder"
    fi
}

save_newBigBench() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/newBigBench_queries; mkdir -p $JOB_PATH/$bench_name_num/newBigBench_results"
  logger "INFO: Saving newBigBench queries and results"

  if [ "$BENCH_LEAVE_SERVICES" ] ; then
    execute_master "$bench_name" "cp $LOCAL_QUERIES_DIR/* $JOB_PATH/$bench_name_num/newBigBench_queries/ 2> /dev/null;
      cp $LOCAL_RESULTS_DIR/* $JOB_PATH/$bench_name_num/newBigBench_results/ 2> /dev/null"
  else
    execute_master "$bench_name" "mv $LOCAL_QUERIES_DIR/* $JOB_PATH/$bench_name_num/newBigBench_queries/ 2> /dev/null;
      mv $LOCAL_RESULTS_DIR/* $JOB_PATH/$bench_name_num/newBigBench_results/ 2> /dev/null"
  fi
}
