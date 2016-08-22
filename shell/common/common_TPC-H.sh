# Common functions for different TPC-H implementations
# Based on Hadoop and Hive

source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

[ ! "$TPCH_SCALE_FACTOR" ] &&  TPCH_SCALE_FACTOR=1 #1 GB min size
[ ! "$TPCH_USE_LOCAL_FACTOR" ] && TPCH_USE_LOCAL_FACTOR="" #set to a scale factor to use the local DBGEN instead of the M/R version

BENCH_DATA_SIZE="$((TPCH_SCALE_FACTOR * 1000000000 ))" #in bytes


TPCH_HDFS_DIR="/tmp/tpch-generate"
TPCH_DB_NAME="tpch_${BENCH_FILE_FORMAT}_${TPCH_SCALE_FACTOR}"

[ ! "$BENCH_LIST" ] && BENCH_LIST="$(seq -f "tpch_query%g" -s " " 1 22)"

# Validations
[ "$(get_hadoop_major_version)" != "2" ] && die "Hadoop v2 is required for $BENCH_SUITE"
[ "$BENCH_FILE_FORMAT" != "orc" ] && die "Only orc file format is supported for now, got: $BENCH_FILE_FORMAT"

# TODO: temporary patch for missing gcc on azure ubuntu
[ ! "$(which gcc)" ] && sudo apt-get install -y -q gcc make
[ ! "$(which gcc)" ] && die "Build tools not installed for TPC-H datagen to work"

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
    execute_query_hive "$query"
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

# Generate the data using the command line version (non-distributed)
# $1 scale factor
tpc-h_cmd_datagen() {
  local scale_factor="$1"
  local bench_name="${FUNCNAME[0]}"
  logger "Running TPC-H cmd line data generator for scale $scale_factor"

  # Generate the data
  time_cmd_master "cd $D2F_local_dir/tpch/tpch-gen/target/tools; $D2F_local_dir/tpch/tpch-gen/target/tools/dbgen -b $D2F_local_dir/tpch/tpch-gen/target/tools/dists.dss -vf -s $scale_factor; "

  # Move the files to HDFS
  hadoop_delete_path "$bench_name" "$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR"
  execute_hadoop_new "$bench_name" "fs -mkdir -p $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/{customer,lineitem,nation,orders,part,partsupp,region,supplier}"

  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/customer.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/customer/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/lineitem.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/lineitem/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/nation.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/nation/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/orders.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/orders/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/part.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/part/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/partsupp.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/partsupp/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/region.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/region/"
  execute_hadoop_new "$bench_name" "fs -moveFromLocal $D2F_local_dir/tpch/tpch-gen/target/tools/supplier.tbl $TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/supplier/"
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

# Interrupts run if data has not been created properly
tpc-h_validate_load() {
  local bench_name="${FUNCNAME[0]}"

  logger "INFO: attempting to validate load and optimize to DB: $TPCH_DB_NAME"
  local db_stats="$(execute_hadoop_new "$bench_name" "fs -du /apps/hive/warehouse/tpch_orc_${TPCH_SCALE_FACTOR}.db" 2>1)"

  #db_stats="$(echo -e "$db_stats"|grep 'warehouse'|grep -v '-du')" # remove extra linesTPCH_USE_LOCAL_FACTOR

  logger "INFO: DB stats = $db_stats";
  logger "INFO: num tables = $(echo -e "$db_stats" |wc -l)";
}

tpc-h_delete_dbgen(){
  #if [ ! "$BENCH_KEEP_FILES" == "1" ] && [ ! "$BENCH_LEAVE_SERVICES" "1"  ] ; then
    logger "INFO: deleting original DBGEN files to save space"
    hadoop_delete_path "$bench_name" "$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR"
  #fi
}

tpc-h_datagen() {
  if [ ! "$BENCH_KEEP_FILES" ] ; then
    # Check if need to build the dbgen
    tpc-h_build

    # Generate the data
    if [ "$TPCH_SCALE_FACTOR" == "1" ] ; then
      tpc-h_cmd_datagen "1"
    elif [[ "$TPCH_USE_LOCAL_FACTOR" > 0 ]] ; then
      tpc-h_cmd_datagen "$TPCH_USE_LOCAL_FACTOR"
    else
      tpc-h_hadoop_datagen
    fi

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
    logger "WARNING: reusing HDFS files"
  fi
}