#SPARK SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_spark_requires() {
  [ ! "$SPARK_VERSION" ] && die "No SPARK_VERSION specified"

  if [ "$BENCH_SUITE" == "BigBench" ] || [[ "$BENCH_SUITE" =~ "D2F"* ]]; then
    log_WARN "Setting Spark version to $SPARK_HIVE (for Hive compatibility)"
    BENCH_REQUIRED_FILES["$SPARK_HIVE"]="http://aloja.bsc.es/public/files/spark_hive_ubuntu-1.6.2.tar.gz"
    SPARK_VERSION=$SPARK_HIVE
    SPARK_FOLDER=$SPARK_HIVE
  else
    SPARK_FOLDER="${SPARK_VERSION}-bin-without-hadoop"
    BENCH_REQUIRED_FILES["$SPARK_FOLDER"]="http://archive.apache.org/dist/spark/$SPARK_VERSION/$SPARK_FOLDER.tgz"
  fi

  #also set the config here
  #BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${SPARK_VERSION}_conf_template"
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS spark-1.x_conf_template"
}

# Helper to print a line with required exports
get_spark_exports() {
  local to_export

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="$(get_hadoop_exports)
export SPARK_VERSION='$SPARK_VERSION';
export SPARK_HOME='$(get_local_apps_path)/${SPARK_FOLDER}';
export SPARK_CONF_DIR='$(get_spark_conf_dir)';
export SPARK_LOG_DIR='$(get_local_bench_path)/spark_logs';
export SPARK_DIST_CLASSPATH=\"\$($(get_hadoop_cmd 'no_exports') classpath)\";
"
    echo -e "$to_export\n"
  fi
}

# Returns the the path to the spark binary with the proper exports
# $1 spark_bin (optional)
get_spark_cmd() {
  local spark_bin="${1:-spark-submit}"
  local spark_exports
  local spark_cmd

  if [ "$clusterType" == "PaaS" ]; then
    spark_exports=""
    spark_bin_path="$spark_bin"
  else
    spark_exports="$(get_spark_exports)"
    spark_bin="$(get_local_apps_path)/${SPARK_FOLDER}/bin/$spark_bin"
  fi
  spark_cmd="$spark_exports\n$spark_bin"

  echo -e "$spark_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
# $4 the spark bin to use ie., spark-sql (optional)
execute_spark(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local spark_bin="$4"
  local spark_cmd

  # if in PaaS use the bin in PATH and no exports
  if [ "$clusterType" == "PaaS" ]; then
    spark_cmd="$cmd"
  else
    spark_cmd="$(get_spark_cmd "$spark_bin") $cmd"
  fi

  # Run the command and time it
  execute_master "$bench" "$spark_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    save_spark "$bench"
  fi
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_spark-sql(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local spark_cmd

  execute_spark "$bench" "$cmd" "$time_exec" "spark-sql"
}

initialize_spark_vars() {
  if [ "$clusterType" == "PaaS" ]; then
    SPARK_HOME="/usr" ## TODO ONLY WORKING IN HDI
    SPARK_CONF_DIR="/etc/spark/conf"
  else
    SPARK_HOME="$(get_local_apps_path)/${SPARK_FOLDER}"
    SPARK_CONF_DIR="$(get_spark_conf_dir)"
  fi
}

# Sets the substitution values for the Spark config
get_spark_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  #Calculate spark instances
  EXECUTOR_INSTANCES="$(printf %.$2f $(echo "(($numberOfNodes)*($NUM_EXECUTOR_NODE))" | bc))" # default should be 1 executor per node

  #EXECUTOR_INSTANCES="$(printf %.$2f $(echo "($EXECUTOR_INSTANCES + ($NUM_EXECUTOR_NODE-1))" | bc))"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/spark_logs,g;
s,##REPLICATION##,$REPLICATION,g;
s,##MASTER##,$master_name,g;
s,##NAMENODE##,$master_name,g;
s,##TMP_DIR##,$HDD_TMP,g;
s,##HDFS_NDIR##,$HDFS_NDIR,g;
s,##HDFS_DDIR##,$HDFS_DDIR,g;
s,##MAX_MAPS##,$MAX_MAPS,g;
s,##MAX_REDS##,$MAX_REDS,g;
s,##IFACE##,$IFACE,g;
s,##IO_FACTOR##,$IO_FACTOR,g;
s,##IO_MB##,$IO_MB,g;
s,##PORT_PREFIX##,$PORT_PREFIX,g;
s,##IO_FILE##,$IO_FILE,g;
s,##BLOCK_SIZE##,$BLOCK_SIZE,g;
s,##PHYS_MEM##,$PHYS_MEM,g;
s,##NUM_CORES##,$NUM_CORES,g;
s,##CONTAINER_MIN_MB##,$CONTAINER_MIN_MB,g;
s,##CONTAINER_MAX_MB##,$CONTAINER_MAX_MB,g;
s,##MAPS_MB##,$MAPS_MB,g;
s,##REDUCES_MB##,$REDUCES_MB,g;
s,##AM_MB##,$AM_MB,g;
s,##BENCH_LOCAL_DIR##,$BENCH_LOCAL_DIR,g;
s,##HDD##,$(get_local_bench_path),g;
s,##HIVE##,$HIVE_HOME/bin/hive,g;
s,##SPARK_EXECUTOR_EXTRA_CLASSPATH##,$HIVE_HOME/lib/:$HIVE_CONF_DIR,g;
s,##HDFS_PATH##,$(get_local_bench_path)/bench_data,g;
s,##HADOOP_CONF##,$HADOOP_CONF_DIR,g;
s,##HADOOP_LIBS##,$BENCH_HADOOP_DIR/lib/native,g;
s,##SPARK##,$SPARK_HOME/bin/spark,g;
s,##SPARK_CONF##,$SPARK_CONF_DIR,g;
s,##SPARK_INSTANCES##,$EXECUTOR_INSTANCES,g;
s,##EXECUTOR_CORES##,$EXECUTOR_CORES,g;
s,##EXECUTOR_MEM##,$EXECUTOR_MEM,g
EOF
}

get_spark_conf_dir() {
  echo -e "$(get_local_bench_path)/spark_conf"
}

prepare_spark_config() {
  logger "INFO: Preparing spark run specific config"
  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    $DSH "mkdir -p $SPARK_CONF_DIR && cp -r $(get_local_configs_path)/spark-1.x_conf_template/* $SPARK_CONF_DIR/"
    subs=$(get_spark_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $SPARK_CONF_DIR/*"
  #  $DSH "cp $(get_local_bench_path)/hadoop_conf/slaves $SPARK_CONF_DIR/slaves"
  fi
#    $DSH "cp $(get_local_bench_path)/hive_conf/hive-site.xml $SPARK_CONF_DIR/"  #Spark needs Hive-Site.xml in the config dir to access Hive metastore
}

# $1 bench name
save_spark() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create Spark log dir
  $DSH "mkdir -p $JOB_PATH/$bench_name_num/spark_logs;"

  if [ "$clusterType" == "PaaS" ]; then
    $DSH "cp -r /var/log/spark $JOB_PATH/$bench_name_num/spark_logs/" #2> /dev/null
  else
    if [ "$BENCH_LEAVE_SERVICES" ] ; then
      $DSH "cp $(get_local_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
    else
      $DSH "mv $(get_local_bench_path)/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
    fi
  fi
  # Save spark conf
  $DSH_MASTER "tar -cjf $JOB_PATH/spark_conf.tar.bz2 $SPARK_CONF_DIR/*"
  save_hadoop "$bench_name"
}