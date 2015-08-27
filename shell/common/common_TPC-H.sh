#TPC-H BENCHMARK SPECIFIC FUNCTIONS

execute_TPCH(){
  restart_hadoop

  ##putting hadoop binaries to path

  if [ "$DELETE_HDFS" == "1" ]; then
    generate_TPCH_data "prep_tpch" "$TPCH_SCALE_FACTOR"
  else
    loggerb  "Reusing previous RUN TPCH data"
  fi

  if [ "$LIST_BENCHS" == "all" ]; then
     LIST_BENCHS=""
     for number in $(seq 1 22) ; do
        LIST_BENCHS="${LIST_BENCHS} query${number}"
     done
  fi

  for query in $(echo "$LIST_BENCHS") ; do
    # Check if there is a custom config for this bench, and call it
    if type "benchmark_TPCH_config_${query}" &>/dev/null
    then
      eval "benchmark_TPCH_config_${query}"
    fi

    #deleting old history files
    logger "INFO: delete old history files"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfs -rm -r /tmp/hadoop-yarn/history" 2> /dev/null

    logger " STARTING $query"

    loggerb  "$(date +"%H:%M:%S") RUNNING QUERY $query"

    execute_TPCH_query "$query"

  done
}

# $2 scale factor
generate_TPCH_data() {
  EXP=$(get_hive_env)
  DATA_GENERATOR="${TPCH_HOME}/tpch-setup.sh $2 $TPCH_DATA_DIR"

  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  logger "INFO: # GENERATING TPCH DATA WITH SCALE FACTOR ${2}"
  logger "INFO: COMMAND: $EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' $DATA_GENERATOR"

  $DSH_MASTER "$EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' bash $DATA_GENERATOR" 2>&1 | tee -a $LOG_PATH

  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    logger "INFO: DATA GENERATOR NOT BUILD, TRYING TO BUILD IT"

     $DSH_MASTER "$EXP cd ${TPCH_HOME}; bash tpch-build.sh" 2>&1 | tee -a $LOG_PATH
     if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      logger "INFO: ERROR WHEN BUILDING DATA GENERATOR FOR TCPH, exiting..."
      exit 1;
     fi

    logger "INFO: RETRYING TO GENERATE DATA WITH SCALE FACTOR ${2}"
    $DSH_MASTER "$EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' bash $DATA_GENERATOR" 2>&1 | tee -a $LOG_PATH
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      logger "INFO: ERROR: GENERATING DATA FAILED FOR A SECOND TIME, exiting..."
      exit 1
    fi
  fi

  #save the data
  if [ "$SAVE_BENCH" == "1" ] ; then
    logger "INFO: Saving TPCH_DATA to: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfs -get -ignoreCrc $TPCH_DATA_DIR $BENCH_SAVE_PREPARE_LOCATION"
  fi

  local end_exec=`timestamp`

  logger "INFO: # DONE GENERATING TPCH DATA"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs"

  # Save execution information in an array to allow import later

  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  stop_monit

  save_disk_usage "AFTER"

  bench_name="$1"
  save_hadoop "${bench_name}"
}

# $1 table name
execute_TPCH_query() {

  TABLE_NAME="tpch_bin_flat_orc_${TPCH_SCALE_FACTOR}"
  if [ ! -z $2 ]; then
    TABLE_NAME="$2"
  fi

  query=$1
  save_disk_usage "BEFORE"
  restart_monit

  EXP=$(get_hive_env)
  PREFIX="${TPCH_HOME}/sample-queries-tpch"
  SETTINGS="${PREFIX}/${TPCH_SETTINGS_FILE_NAME}"
  COMMAND="hive -i $SETTINGS -f ${PREFIX}/tpch_${1}.sql --database ${TABLE_NAME}"

  logger "INFO: COMMAND: $COMMAND\nSETTINGS FILE: $SETTINGS"

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  logger "INFO: # EXECUTING TPCH $query"

  $DSH_MASTER "$EXP cd ${TPCH_HOME} && /usr/bin/time -f 'Time ${3}${1} %e' $COMMAND"

  local end_exec=`timestamp`

  logger "INFO: # DONE TPCH $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs"

  # Save execution information in an array to allow import later

  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  stop_monit
  save_disk_usage "AFTER"

  save_hadoop "tpch-${query}"
}