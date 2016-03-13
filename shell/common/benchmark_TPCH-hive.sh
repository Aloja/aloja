# TPC-Hive version
TPCH_DIR="tpch-hive-fixed"

source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

BENCH_REQUIRED_FILES["$TPCH_DIR"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/$TPCH_DIR.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "query%g" -s " " 1 22)"

# Some benchmark specific validations
[ ! "$TPCH_SCALE_FACTOR" ] && die "TPCH_SCALE_FACTOR is not set, cannot continue"

[ "$(get_hadoop_major_version)" != "2" ] && die "Hadoop v2 is required for TPCH-hive"


benchmark_suite_config() {
  [ ! "$TPCH_DATA_DIR" ] && export TPCH_DATA_DIR=/tpch/tpch-generate

  BENCH_SAVE_PREPARE_LOCATION="${BENCH_LOCAL_DIR}${TPCH_DATA_DIR}"

  EXECUTE_TPCH_HIVE=true
  TPCH_HOME=$(get_local_apps_path)/$TPCH_DIR

  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  # TODO: review to generate data first time when DELETE_HDFS=0
  if [ "$DELETE_HDFS" == "1" ]; then
    generate_TPCH_data "prep_tpch" "$TPCH_SCALE_FACTOR"
  else
    logger "INFO: Reusing previous RUN TPCH data"
  fi

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING QUERY $query"
    #execute_TPCH_query "$query"
    execute_TPCH_query_fixed "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

benchmark_suite_save() {
  logger "DEBUG: No specific ${FUNCNAME[0]} defined for $BENCH_SUITE"
}

benchmark_suite_cleanup() {
  clean_hadoop
}

get_tpch_exports() {
  local to_export

  to_export="$(get_java_exports)
    $(get_hadoop_exports)
    $(get_hive_exports)
    export TPCH_SOURCE_DIR='$(get_local_apps_path)/$TPCH_DIR';
    export TPCH_HOME='$TPCH_SOURCE_DIR';"

  echo -e "$to_export\n"
}

# $1 query number
# $2 table name
execute_TPCH_query() {

  local query=$1
  TABLE_NAME="tpch_bin_flat_orc_${TPCH_SCALE_FACTOR}"
  if [ ! -z $2 ]; then
    TABLE_NAME="$2"
  fi

  logger "INFO: # EXECUTING TPCH Q${query}"

  execute_hive "tpch-${query}" "-f ${TPCH_HOME}/sample-queries-tpch/tpch_${1}.sql --database ${TABLE_NAME}" "time"

  logger "INFO: # DONE TPCH Q${query}"
}

# $1 query number
# $2 table name
execute_TPCH_query_fixed() {

  local query=$1
  TABLE_NAME="tpch_bin_flat_orc_${TPCH_SCALE_FACTOR}"
  if [ ! -z $2 ]; then
    TABLE_NAME="$2"
  fi

  logger "INFO: Running TPCH $query"
  execute_hive "tpch-${query}" "-f ${TPCH_HOME}/queries-fixed/tpch_${1}.sql --database ${TABLE_NAME}" "time"
}

# $2 scale factor
generate_TPCH_data() {
  SCALE=$2

  local java_path="$(get_local_apps_path)/$BENCH_JAVA_VERSION"

  EXP="$(get_hive_exports)"
  DATA_GENERATOR="tpch-setup.sh $2 $TPCH_DATA_DIR"

  if [ ! -f "${TPCH_HOME}/tpch-gen/target/tpch-gen-1.0-SNAPSHOT.jar" ]; then
    logger "INFO: Building TPCH data generator"
    logger "DEBUG: COMMAND: $EXP cd ${TPCH_HOME} && PATH=\$PATH:$java_path/bin bash tpch-build.sh"
    time_cmd_master "$EXP cd ${TPCH_HOME} && PATH=\$PATH:$java_path/bin bash tpch-build.sh" "$time_exec"
     if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      die "FAILED BUILDING DATA GENERATOR FOR TCPH, exiting..."
     fi
  else
    logger "INFO: Data generator already built, skipping..."
  fi

  logger "INFO: PREPARING DIR TO GENERATE TPC-H DATA"
  if [[ "$defaultProvider" == "rackspacecbd" ]]; then
    logger "DEBUG: rackspace CBD creating data dir with hdfs user"
    sudo su hdfs -c "hdfs dfs -mkdir -p ${TPCH_DATA_DIR}"
    sudo su hdfs -c "hdfs dfs -chown pristine ${TPCH_DATA_DIR}"
  else
    time_cmd_master "$(get_hadoop_exports) ${BENCH_HADOOP_DIR}/bin/hdfs dfs -mkdir -p ${TPCH_DATA_DIR}"
  fi

  logger "INFO: # GENERATING TPCH DATA WITH SCALE FACTOR ${SCALE}"
  logger "DEBUG: COMMAND: $(get_hadoop_exports) cd ${TPCH_HOME}/tpch-gen && ${BENCH_HADOOP_DIR}/bin/hadoop jar target/*.jar $(get_hadoop_job_config) -d ${TPCH_DATA_DIR}/${SCALE}/ -s ${SCALE}"
  #execute_hadoop_new "$1" "jar ${TPCH_HOME}/tpch-gen/target/*.jar -d ${TPCH_DATA_DIR}/${SCALE}/ -s ${SCALE}" "time"
  time_cmd_master "$(get_hadoop_exports) cd ${TPCH_HOME}/tpch-gen && ${BENCH_HADOOP_DIR}/bin/hadoop jar target/*.jar $(get_hadoop_job_config) -d ${TPCH_DATA_DIR}/${SCALE}/ -s ${SCALE}"

  logger "INFO: Loading text data into external tables"
  execute_hive "prep_tpch_create_tables" "-f ${TPCH_HOME}/ddl-tpch/bin_flat/alltables.sql -d DB=tpch_text_${SCALE} -d LOCATION=${TPCH_DATA_DIR}/${SCALE}" "time"

  TABLES="part partsupp supplier customer orders lineitem nation region"
  BUCKETS=13
  # Create the optimized tables.

  total=8
  DATABASE=tpch_bin_partitioned_orc_${SCALE}
# i=1
#  for t in ${TABLES}
#  do
#          logger "INFO: Optimizing table $t ($i/$total)."
#          COMMAND="-f ${TPCH_HOME}/ddl-tpch/bin_flat/${t}.sql \
#              -d DB=tpch_bin_flat_orc_${SCALE} \
#              -d SOURCE=tpch_text_${SCALE} -d BUCKETS=${BUCKETS} \
#              -d FILE=orc"
#          execute_hive "prep_tpch_table_${t}" "$COMMAND" "time"
#          i="$((i + 1))"
#  done

  COMMAND="
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/part.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/partsupp.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/supplier.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/customer.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/orders.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/lineitem.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/nation.sql \
 -f ${TPCH_HOME}/ddl-tpch/bin_flat/region.sql \
 -d DB=tpch_bin_flat_orc_${SCALE} \
 -d SOURCE=tpch_text_${SCALE} -d BUCKETS=${BUCKETS} \
 -d FILE=orc"

  logger "INFO: Optimizing tables: $TABLES"
  execute_hive "prep_tpch_tables" "$COMMAND" "time"

  logger "INFO: Data loaded into database ${DATABASE}"
}

