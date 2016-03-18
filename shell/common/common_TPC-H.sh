# Common functions for different TPC-H implementations
# Based on Hadoop and Hive

source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

[ ! "$TPCH_SCALE_FACTOR" ] &&  TPCH_SCALE_FACTOR=2 #2 GB min size
BENCH_DATA_SIZE="$((TPCH_SCALE_FACTOR * 1024 * 1024 * 1024))" #in bytes


TPCH_HDFS_DIR="/tmp/tpch-generate"
TPCH_DB_NAME="tpch_${BENCH_FILE_FORMAT}_${TPCH_SCALE_FACTOR}"

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "tpch_query%g" -s " " 1 22)"

# Validations
[ "$(get_hadoop_major_version)" != "2" ] && die "Hadoop v2 is required for $BENCH_SUITE"
[ "$BENCH_FILE_FORMAT" != "orc" ] && die "Only orc file format is supported for now, got: $BENCH_FILE_FORMAT"


D2F_folder_name="D2F-Bench-master"
BENCH_REQUIRED_FILES["$D2F_folder_name"]="http://github.com/Aloja/D2F-Bench/archive/master.zip"
D2F_local_dir="$(get_local_apps_path)/$D2F_folder_name"


benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hive_vars
  prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING $query"
    execute_query_pig "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# Build the datagen from sources, it should only be needed the first time the bench is run
tpc-h_build(){
  local java_path="$(get_local_apps_path)/$BENCH_JAVA_VERSION"

  if [ ! -f "$D2F_local_dir/tpch/tpch-gen/target/tpch-gen-1.0-SNAPSHOT.jar" ]; then
    logger "INFO: Building TPCH data generator in: $D2F_local_dir"
    time_cmd_master "cd $D2F_local_dir/bin && PATH=\$PATH:$java_path/bin bash tpch-build.sh" "time_exec"
     if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      die "FAILED BUILDING DATA GENERATOR FOR TCPH, exiting..."
     fi
  else
    logger "INFO: Data generator already built, skipping..."
  fi

}

tpc-h_hadoop_datagen() {
  local bench_name="${FUNCNAME[0]}"
  logger "Running TPC-H data generator M/R job"
  hadoop_delete_path "$bench_name" "$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR"
  execute_hadoop_new "$bench_name" "jar target/*.jar $(get_hadoop_job_config) -d $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/ -s $TPCH_SCALE_FACTOR" "time" "$D2F_local_dir/tpch/tpch-gen"
}

tpc-h_load-text(){
  local bench_name="${FUNCNAME[0]}"

  logger "INFO: Loading text data into external tables"
  execute_hive "$bench_name" "-f $D2F_local_dir/tpch/ddl/alltables.sql -d DB=tpch_text_$TPCH_SCALE_FACTOR -d LOCATION=$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR" "time"
}

tpc-h_load-optimize() {
  local bench_name="${FUNCNAME[0]}"

  local tables="part partsupp supplier customer orders lineitem nation region"

  local tables_files=""
  for table in $tables ; do
    tables_files="$tables_files $D2F_local_dir/tpch/ddl/$table.sql"
  done

  local all_path="$D2F_local_dir/tpch/ddl/all_optimized.sql"

  # Concatenate different table files
  cat $tables_files > "$all_path"

  local optimize_cmd="-f $all_path \
  -d DB=$TPCH_DB_NAME \
  -d SOURCE=tpch_text_$TPCH_SCALE_FACTOR -d BUCKETS=13 \
  -d FILE=$BENCH_FILE_FORMAT"

  logger "INFO: Optimizing tables: $TABLES"
  execute_hive "$bench_name" "$optimize_cmd" "time"
}

tpc-h_datagen() {
  if [ ! "$BENCH_KEEP_FILES" ] ; then
    # Check if need to build the dbgen
    tpc-h_build

    # Generate the data
    tpc-h_hadoop_datagen

    # Load external tables as text
    tpc-h_load-text

    # Optimize tables to format
    tpc-h_load-optimize

    logger "INFO: Data loaded and optimized into database $TPCH_DB_NAME"
  else
    logger "WARNING: reusing HDFS files"
  fi
}