#SPARK SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_spark_requires() {
  [ ! "$SPARK_VERSION" ] && die "No SPARK_VERSION specified"

  if [[ "$BENCH_SUITE" =~ "BigBench"* || "$BENCH_SUITE" =~ "D2F"* ]]; then
    if [[ "$(get_spark_major_version)" = "2" ]]; then
        SPARK_HIVE="$SPARK2_HIVE"
    fi
    log_WARN "Setting Spark version to $SPARK_HIVE (for Hive compatibility)"
    BENCH_REQUIRED_FILES["$SPARK_HIVE"]="http://aloja.bsc.es/public/aplic2/tarballs/$SPARK_HIVE.tar.gz"
    SPARK_VERSION=$SPARK_HIVE
    SPARK_FOLDER=$SPARK_HIVE
  else
    SPARK_FOLDER="${SPARK_VERSION}-bin-without-hadoop"
    BENCH_REQUIRED_FILES["$SPARK_FOLDER"]="http://archive.apache.org/dist/spark/$SPARK_VERSION/$SPARK_FOLDER.tgz"
  fi

  #also set the config here
  #BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${SPARK_VERSION}_conf_template"
  if [[ "$(get_spark_major_version)" = "2" ]]; then
    BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS spark-2.x_conf_template"
  else
    BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS spark-1.x_conf_template"
  fi
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

  if [[ "$clusterType" = "PaaS" ]]; then
    spark_exports=""
    spark_bin_path="$spark_bin"
  else
    spark_exports="$(get_spark_exports)"
    if [[ "$use_hive" = "true" ]]; then
        spark_exports+="$(get_hive_exports)"
    fi
    spark_bin="$(get_local_apps_path)/${SPARK_FOLDER}/bin/$spark_bin"
    if [[ "$USE_EXTERNAL_DATABASE" = "true" ]]; then
      database_jars="$(get_database_driver_path_coma),"
      spark_database_opts="--jars "
    fi
  fi
  spark_cmd="$spark_exports\n$spark_bin $spark_database_opts $database_jars"

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

get_spark_major_version() {
  local spark_string="$SPARK_VERSION"
  local major_version=""

  if [[ "$spark_string" == *"-1"* ]] ; then
    major_version="1"
  elif [[ "$spark_string" == *"-2"* ]] ; then
    major_version="2"
  else
    logger "WARNING: Cannot determine Spark major version."
  fi

  echo -e "$major_version"
}

# Sets the substitution values for the Spark config
get_spark_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  #Calculate spark instances
  EXECUTOR_INSTANCES="$(printf %.$2f $(echo "(($numberOfNodes)*($NUM_EXECUTOR_NODE))" | bc))" # default should be 1 executor per node

  #EXECUTOR_INSTANCES="$(printf %.$2f $(echo "($EXECUTOR_INSTANCES + ($NUM_EXECUTOR_NODE-1))" | bc))"

  [ ! "$SPARK_MAJOR_VERSION" ] && SPARK_MAJOR_VERSION="0"

  local java_home=$(get_java_home)
  local hdd=$(get_local_bench_path)
  local log_dir=$hdd/spark_logs
  local hdfs_path=$hdd/bench_data

  local hive=$HIVE_HOME/bin/hive
  local spark_executor_extra_classpath=$HIVE_HOME/lib/:$HIVE_CONF_DIR
  local hadoop_libs=$BENCH_HADOOP_DIR/lib/native
  local spark=$SPARK_HOME/bin/spark

  cat <<EOF
\$r = q/${java_home//\//\\/}/;                     s/##JAVA_HOME##/\$r/g;
\$r = q/${BENCH_HADOOP_DIR//\//\\/}/;              s/##HADOOP_HOME##/\$r/g;
\$r = q/${JAVA_XMS//\//\\/}/;                      s/##JAVA_XMS##/\$r/g;
\$r = q/${JAVA_XMX//\//\\/}/;                      s/##JAVA_XMX##/\$r/g;
\$r = q/${JAVA_AM_XMS//\//\\/}/;                   s/##JAVA_AM_XMS##/\$r/g;
\$r = q/${JAVA_AM_XMX//\//\\/}/;                   s/##JAVA_AM_XMX##/\$r/g;
\$r = q/${log_dir//\//\\/}/;                       s/##LOG_DIR##/\$r/g;
\$r = q/${REPLICATION//\//\\/}/;                   s/##REPLICATION##/\$r/g;
\$r = q/${master_name//\//\\/}/;                   s/##MASTER##/\$r/g;
\$r = q/${master_name//\//\\/}/;                   s/##NAMENODE##/\$r/g;
\$r = q/${HDD_TMP//\//\\/}/;                       s/##TMP_DIR##/\$r/g;
\$r = q/${HDFS_NDIR//\//\\/}/;                     s/##HDFS_NDIR##/\$r/g;
\$r = q/${HDFS_DDIR//\//\\/}/;                     s/##HDFS_DDIR##/\$r/g;
\$r = q/${MAX_MAPS//\//\\/}/;                      s/##MAX_MAPS##/\$r/g;
\$r = q/${MAX_REDS//\//\\/}/;                      s/##MAX_REDS##/\$r/g;
\$r = q/${IFACE//\//\\/}/;                         s/##IFACE##/\$r/g;
\$r = q/${IO_FACTOR//\//\\/}/;                     s/##IO_FACTOR##/\$r/g;
\$r = q/${IO_MB//\//\\/}/;                         s/##IO_MB##/\$r/g;
\$r = q/${PORT_PREFIX//\//\\/}/;                   s/##PORT_PREFIX##/\$r/g;
\$r = q/${IO_FILE//\//\\/}/;                       s/##IO_FILE##/\$r/g;
\$r = q/${BLOCK_SIZE//\//\\/}/;                    s/##BLOCK_SIZE##/\$r/g;
\$r = q/${PHYS_MEM//\//\\/}/;                      s/##PHYS_MEM##/\$r/g;
\$r = q/${NUM_CORES//\//\\/}/;                     s/##NUM_CORES##/\$r/g;
\$r = q/${CONTAINER_MIN_MB//\//\\/}/;              s/##CONTAINER_MIN_MB##/\$r/g;
\$r = q/${CONTAINER_MAX_MB//\//\\/}/;              s/##CONTAINER_MAX_MB##/\$r/g;
\$r = q/${MAPS_MB//\//\\/}/;                       s/##MAPS_MB##/\$r/g;
\$r = q/${REDUCES_MB//\//\\/}/;                    s/##REDUCES_MB##/\$r/g;
\$r = q/${AM_MB//\//\\/}/;                         s/##AM_MB##/\$r/g;
\$r = q/${BENCH_LOCAL_DIR//\//\\/}/;               s/##BENCH_LOCAL_DIR##/\$r/g;
\$r = q/${hdd//\//\\/}/;                           s/##HDD##/\$r/g;
\$r = q/${hive//\//\/}/;                           s/##HIVE##/$hive/g
\$r = q/${spark_executor_extra_classpath//\//\/}/; s/##SPARK_EXECUTOR_EXTRA_CLASSPATH##/\$r/g
\$r = q/${hdfs_path//\//\/}/;                      s/##HDFS_PATH##/\$r/g
\$r = q/${HADOOP_CONF_DIR//\//\/}/;                s/##HADOOP_CONF##/\$r/g
\$r = q/${hadoop_libs//\//\/}/;                    s/##HADOOP_LIBS##/\$r/g
\$r = q/${spark//\//\/}/;                          s/##SPARK##/\$r/g
\$r = q/${SPARK_CONF_DIR//\//\/}/;                 s/##SPARK_CONF##/\$r/g
\$r = q/${EXECUTOR_INSTANCES//\//\/}/;             s/##EXECUTOR_INSTANCES##/\$r/g
\$r = q/${EXECUTOR_CORES//\//\/}/;                 s/##EXECUTOR_CORES##/\$r/g
\$r = q/${SPARK_MAJOR_VERSION//\//\/}/;            s/##SPARK_MAJOR_VERSION##/\$r/g
\$r = q/${SPARK_MEMORY_OVERHEAD//\//\/}/;          s/##SPARK_MEMORY_OVERHEAD##/\$r/g
\$r = q/${EXECUTOR_MEM//\//\/}/;                   s/##EXECUTOR_MEM##/\$r/g
\$r = q/${EXPERIMENT_ID//\//\\/}/;                 s/##EXPERIMENT_ID##/\$r/g;
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
    $DSH "mkdir -p $SPARK_CONF_DIR && cp -r $(get_local_configs_path)/spark-$(get_spark_major_version).x_conf_template/* $SPARK_CONF_DIR/"
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
      $DSH "cp $HDD/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
    else
      $DSH "mv $HDD/spark_logs/* $JOB_PATH/$bench_name_num/spark_logs/ 2> /dev/null"
    fi

    # Save spark conf
    $DSH_MASTER "tar -cjf $JOB_PATH/spark_conf.tar.bz2 $SPARK_CONF_DIR"
  fi

  save_hadoop "$bench_name"
}
