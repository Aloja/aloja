# TPC-Hive version
source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

# TODO
BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
BENCH_REQUIRED_FILES["maven"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/fallara.tar.gz"

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "query%g" 1 22)"

# Some benchmark specific validations
[ ! "$TPCH_SCALE_FACTOR" ] && die "TPCH_SCALE_FACTOR is not set, cannot continue"

[ "$(get_hadoop_major_version)" != "2" ] && die "Need to use Hadoop v2"


# Load Hadoop functions
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires


benchmark_suite_config() {


  [ ! "$TPCH_SETTINGS_FILE_NAME" ] && export TPCH_SETTINGS_FILE_NAME="tpch.settings"
  [ ! "$TPCH_DATA_DIR" ] && export TPCH_DATA_DIR=/tpch/tpch-generate
  BENCH_SAVE_PREPARE_LOCATION="${BENCH_LOCAL_DIR}${TPCH_DATA_DIR}"

  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  prepare_hive_config

  start_hadoop
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  if [ "$DELETE_HDFS" == "1" ]; then
    generate_TPCH_data "prep_tpch" "$TPCH_SCALE_FACTOR"
  else
    logger "INFO: Reusing previous RUN TPCH data"
    #deleting old history files
    logger "INFO: delete old history files"
  fi

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING QUERY $query"
    execute_TPCH_query "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

benchmark_suite_save() {
  : # Empty
}

benchmark_suite_cleanup() {
  stop_hadoop
}


# $1 query number
# $2 table name
execute_TPCH_query() {

  local query=$1

  TABLE_NAME="tpch_bin_flat_orc_${TPCH_SCALE_FACTOR}"
  if [ ! -z $2 ]; then
    TABLE_NAME="$2"
  fi

  PREFIX="${TPCH_HOME}/sample-queries-tpch"

  logger "DEBUG: COMMAND: $COMMAND\nSETTINGS FILE: $SETTINGS"

  logger "INFO: # EXECUTING TPCH $query"

  $DSH_MASTER "$EXP cd ${TPCH_HOME} && export TIMEFORMAT='Time ${3}${1} %R' && time $COMMAND"

  execute_hive "tpch-${query}" "-f ${PREFIX}/tpch_${1}.sql --database ${TABLE_NAME}" "time"

  logger "INFO: # DONE TPCH $1"
}

# $2 scale factor
generate_TPCH_data() {
  EXP=$(get_hive_env)
  DATA_GENERATOR="${TPCH_HOME}/tpch-setup.sh $2 $TPCH_DATA_DIR"

  logger "INFO: # GENERATING TPCH DATA WITH SCALE FACTOR ${2}"
  logger "INFO: COMMAND: $EXP cd $TPCH_HOME && export TIMEFORMAT='Time data generator %R' && time $DATA_GENERATOR"

time_cmd_master "$EXP cd $TPCH_HOME  bash $DATA_GENERATOR" "$time_exec"

  #execute_hive "tpch-${query}" "-f ${PREFIX}/tpch_${1}.sql --database ${TABLE_NAME}" "time"


  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    logger "INFO: DATA GENERATOR NOT BUILD, TRYING TO BUILD IT"

     $DSH_MASTER "$EXP cd ${TPCH_HOME}; bash tpch-build.sh" 2>&1 | tee -a $LOG_PATH
     if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      logger "INFO: ERROR WHEN BUILDING DATA GENERATOR FOR TCPH, exiting..."
      exit 1;
     fi

    logger "INFO: RETRYING TO GENERATE DATA WITH SCALE FACTOR ${2}"
    $DSH_MASTER "$EXP cd $TPCH_HOME && export TIMEFORMAT='Time data generator %R' && time bash $DATA_GENERATOR" 2>&1 | tee -a $LOG_PATH
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      logger "INFO: ERROR: GENERATING DATA FAILED FOR A SECOND TIME, exiting..."
      exit 1
    fi
  fi
}

