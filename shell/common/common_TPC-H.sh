# Common functions for different TPC-H implementations
# Based on Hadoop and Hive
#
if [[ "$NATIVE_FORMAT" = "text" && "$BENCH_SUITE" = *"native-spark"* ]]; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
  set_hadoop_requires
else
  source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
  set_hive_requires
fi

if [[ "$BB_SERVER_DERBY" == "true" ]]; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
  set_derby_requires
fi

if [ "$(get_benchmark_data_size_gb)" -lt 1 ] ; then #Should only happen when BENCH_DATA_SIZE < 1GB
  logger "WARNING: TPC-H data size is set below minimum value, setting data size to 1GB"
  BENCH_DATA_SIZE=1000000000
fi

TPCH_HDFS_DIR="/tmp/tpch-generate"

if [[ ! "$NATIVE_FORMAT" == "text"  || ! "$BENCH_SUITE" == *"native-spark"* ]]; then
  [[ ! -z $NATIVE_FORMAT ]] && BENCH_FILE_FORMAT=$NATIVE_FORMAT
  TPCH_DB_NAME="tpch_${BENCH_FILE_FORMAT}_$(get_benchmark_data_size_gb)"
fi

[[ ! "$BENCH_LIST" ]] && BENCH_LIST="$(printf '%d ' {1..22})"

# Validations
[[ "$(get_hadoop_major_version)" != "2" ]] && die "Hadoop v2 is required for $BENCH_SUITE"
[[ "$BENCH_FILE_FORMAT" != "orc" ]] && [[ "$BENCH_SUITE" != *"native-spark"* ]] && die "Only orc file format is supported for now, got: $BENCH_FILE_FORMAT"

# TODO: temporary patch for missing gcc on azure ubuntu
[[ ! "$(which gcc)" ]] && sudo apt-get install -y -q gcc make
[[ ! "$(which gcc)" ]] && die "Build tools not installed for TPC-H datagen to work"

D2F_folder_name="D2F-Bench-master"
BENCH_REQUIRED_FILES["$D2F_folder_name"]="https://github.com/Aloja/D2F-Bench/archive/master.zip"
D2F_local_dir="$(get_local_apps_path)/$D2F_folder_name"

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  # Set hive for ORC
  if [[ ! "$NATIVE_FORMAT" == "text" ]] || [[ ! "$BENCH_SUITE" = *"native-spark"* ]]; then
    initialize_hive_vars
    prepare_hive_config "$HIVE_SETTINGS_FILE" "$HIVE_SETTINGS_FILE_PATH"
      if [["$BB_SERVER_DERBY" == "true" ]]; then
        logger "WARNING: Using Derby DB in client/server mode"
        USE_EXTERNAL_DATABASE="true"
        initialize_derby_vars "TPCH_DB"
        start_derby
      else
        logger "WARNING: Using Derby DB in embedded mode"
      fi
  fi


  if [[ ! "$use_spark" ]]; then
    initialize_spark_vars
    prepare_spark_config
  fi
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING $query"
    execute_query_hive "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# Build the datagen from sources, it should only be needed the first time the bench is run
tpc-h_build(){
  local java_path="$(get_local_apps_path)/$BENCH_JAVA_VERSION"

  if [[ ! -f "$D2F_local_dir/tpch/tpch-gen/target/tpch-gen-1.0-SNAPSHOT.jar" ]]; then
    logger "INFO: Building TPCH data generator in: $D2F_local_dir"
    time_cmd_master "cd $D2F_local_dir/bin && PATH=\$PATH:$java_path/bin bash tpch-build.sh" "time_exec"
     if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
      die "FAILED BUILDING DATA GENERATOR FOR TCPH, exiting..."
     fi
  else
    logger "INFO: Data generator already built, skipping..."
  fi

}

tpc-h_hadoop_datagen() {
  local bench_name="${FUNCNAME[0]}"
  local data_size_gb=$(get_benchmark_data_size_gb)
  local dst_dir="$TPCH_HDFS_DIR/$data_size_gb"
  logger "Running TPC-H data generator M/R job"
  hadoop_delete_path "$bench_name" "$dst_dir"
  execute_hadoop_new "$bench_name" "jar target/*.jar \"$(get_hadoop_job_config)\" -d \"$dst_dir\"/ -s \"$data_size_gb\"" "time" "$D2F_local_dir/tpch/tpch-gen"
}

# Generate the data using the command line version (non-distributed)
# $1 scale factor
tpc-h_cmd_datagen() {
  local scale_factor="$1"
  local src_dir="$D2F_local_dir/tpch/tpch-gen/target/tools/"
  local dst_dir="$TPCH_HDFS_DIR/$(get_benchmark_data_size_gb)"
  local bench_name="${FUNCNAME[0]}"
  logger "Running TPC-H cmd line data generator for scale $scale_factor"

  # Generate the data
  time_cmd_master "cd \"$src_dir\"; ./dbgen -b dists.dss -vf -s \"$scale_factor\""

  # Move the files to HDFS
  hadoop_delete_path "$bench_name" "$dst_dir"
  local tables=( customer lineitem nation orders part partsupp region supplier )
  execute_hadoop_new "$bench_name" "fs -mkdir -p $(printf '%q ' "${tables[@]/#/$dst_dir}")"

  for table in "${tables[@]}"; do
    execute_hadoop_new "$bench_name" "fs -moveFromLocal \"$src_dir/$table.tbl\" \"$dst_dir/$table/\""
  done
}

tpc-h_load-text(){
  local bench_name="${FUNCNAME[0]}"

  logger "INFO: Loading text data into external tables"
  execute_hive "$bench_name" "-f $D2F_local_dir/tpch/ddl/alltables.sql -d DB=tpch_text_$(get_benchmark_data_size_gb) -d LOCATION=$TPCH_HDFS_DIR/$(get_benchmark_data_size_gb)" "time"
}

tpc-h_delete-text(){
  local bench_name="${FUNCNAME[0]}"

  logger "INFO: Deleting external plain tables to save space (if BENCH_KEEP_FILES is not set)"
  clean_HDFS "$bench_name" "$TPCH_HDFS_DIR/$(get_benchmark_data_size_gb)"
}

tpc-h_load-optimize() {
  local bench_name="${FUNCNAME[0]}"

  [[ ! "$BUCKETS" ]] && BUCKETS=13

  local tables="part partsupp supplier customer orders lineitem nation region"

  local tables_files=""
  for table in $tables ; do
    tables_files="$tables_files $D2F_local_dir/tpch/ddl/$table.sql"
  done

  local all_path="$D2F_local_dir/tpch/ddl/all_optimized.sql"

  # Concatenate different table files
  cat $tables_files > "$all_path"


  local optimize_cmd="-f \"$all_path\" \
  -d DB=\"$TPCH_DB_NAME\" \
  -d SOURCE=\"tpch_text_$(get_benchmark_data_size_gb)\" \
  -d BUCKETS=\"$BUCKETS\" \
  -d FILE=\"$BENCH_FILE_FORMAT\""

  logger "INFO: Optimizing tables: $TABLES using $BUCKETS buckets."
  execute_hive "$bench_name" "$optimize_cmd" "time"

  tpc-h_delete-text
}

# Interrupts run if data has not been created properly
tpc-h_validate_load() {
  local bench_name="${FUNCNAME[0]}"

  logger "INFO: attempting to validate load and optimize to DB: $TPCH_DB_NAME"
  local db_stats="$(execute_hadoop_new "$bench_name" "fs -du \"/apps/hive/warehouse/tpch_orc_$(get_benchmark_data_size_gb).db\"" 2>&1)"

  logger "INFO: DB stats = $db_stats";
  logger "INFO: num tables = $(echo -e "$db_stats" |wc -l)";
}

tpc-h_delete_dbgen(){
  if [[ ! "$BENCH_KEEP_FILES" == "1" ]] && [[ ! "$BENCH_LEAVE_SERVICES" == "1" ]] ; then
    logger "INFO: deleting original DBGEN files to save space"
    hadoop_delete_path "$bench_name" "$TPCH_HDFS_DIR/$(get_benchmark_data_size_gb)"
  fi
}

tpc-h_datagen_only(){
if [[ ! "$BENCH_KEEP_FILES" ]] ; then
    # Check if need to build the dbgen
    tpc-h_build

    # Generate the data
    if [[ "$(get_benchmark_data_size_gb)" -eq "1" ]] ; then
      tpc-h_cmd_datagen "1"
    else
      tpc-h_hadoop_datagen
    fi

    logger "INFO: Data are not deleted"
  else
    logger "WARNING: reusing HDFS files"
fi
}

tpc-h_datagen() {
  if [[ ! "$BENCH_KEEP_FILES" ]] ; then
    # Check if need to build the dbgen
    tpc-h_build

    # Generate the data
    if [[ "$(get_benchmark_data_size_gb)" -eq "1" ]] ; then
      tpc-h_cmd_datagen "1"
    else
      tpc-h_hadoop_datagen
    fi

    # Keep files for TPCH on native Spark & no need to load into DB
    if [[ ! "$NATIVE_FORMAT" == "text" || ! "$BENCH_SUITE" == "D2F-native-spark" ]]; then
      # Load external tables as text
      tpc-h_load-text

      # Optimize tables to format
      tpc-h_load-optimize

      # Try to validate data creation
      tpc-h_validate_load

      # Delete source files
      tpc-h_delete_dbgen

      logger "INFO: Data loaded and optimized into database $TPCH_DB_NAME"
    else
      logger "INFO: Only generating Data no load into database"
    fi
  else
    logger "WARNING: reusing HDFS files"
  fi
}
