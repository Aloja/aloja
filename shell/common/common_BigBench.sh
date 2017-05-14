# Start Spark if needed
if [ "$ENGINE" == "spark_sql" ] || [ "$HIVE_ML_FRAMEWORK" == "spark" ]; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
  set_spark_requires
#  HIVE_ENGINE="mr"
fi

# Start Hive
source_file "$ALOJA_REPO_PATH/shell/common/common_hive.sh"
set_hive_requires

# Start Tez if needed
if [ "$HIVE_ENGINE" == "tez" ]; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_tez.sh"
  set_tez_requires
fi

if [ "$BB_SERVER_DERBY" == "true" ]; then
  source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
  set_derby_requires
fi

BIG_BENCH_FOLDER="Big-Data-Benchmark-for-Big-Bench-master"

if [ "$BENCH_SCALE_FACTOR" == 0 ] ; then #Should only happen when BENCH_SCALE_FACTOR is not set and BENCH_DATA_SIZE < 1GB
  logger "WARNING: BigBench SCALE_FACTOR is set below minimum value, setting BENCH_SCALE_FACTOR to 1 (1 GB) and recalculating BENCH_DATA_SIZE"
  BENCH_SCALE_FACTOR=1
  BENCH_DATA_SIZE="$((BENCH_SCALE_FACTOR * 1000000000 ))" #in bytes
fi

# Sets the required files to download/copy
set_BigBench_requires() {
  [ ! "$MAHOUT_VERSION" ] && die "No MAHOUT_VERSION specified"

  MAHOUT_FOLDER="apache-mahout-distribution-${MAHOUT_VERSION}"

  BENCH_REQUIRED_FILES["$BIG_BENCH_FOLDER"]="https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench/archive/master.zip"
  #BENCH_REQUIRED_FILES["$BIG_BENCH_FOLDER"]="https://github.com/Aloja/Big-Data-Benchmark-for-Big-Bench_OLD/archive/master.zip" #Old BB version
  BENCH_REQUIRED_FILES["$MAHOUT_FOLDER"]="https://archive.apache.org/dist/mahout/$MAHOUT_VERSION/apache-mahout-distribution-${MAHOUT_VERSION}.tar.gz"

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS BigBench_conf_template"
}

# Helper to print a line with required exports
# $1 scale factor to use
# $2 instance of the query
get_BigBench_exports() {

  local to_export
  local to_export_spark
  local to_export_tez

  #Mandatory environment variables
  #BIG_BENCH_HDFS_ABSOLUTE_INIT_DATA_DIR Only used in the data-generation section
  to_export="
    export BIG_BENCH_HOME='$BIG_BENCH_HOME';
    export BIG_BENCH_CONF_DIR='$BIG_BENCH_CONF_DIR';
    export BIG_BENCH_LOGS_DIR='$(get_local_bench_path)/BigBench_logs/bigbench_$1_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_INIT_DATA_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1/base';
    export BIG_BENCH_HDFS_ABSOLUTE_REFRESH_DATA_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1/data_refresh';
    export BIG_BENCH_HDFS_ABSOLUTE_QUERY_RESULT_DIR='$HDFS_DATA_ABSOLUTE_PATH/query_results/bigbench_$1_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_TEMP_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1_$2/temp';
    export BIG_BENCH_DEFAULT_DATABASE='bigbench_$1';
    export BIG_BENCH_HADOOP_CONF=${HADOOP_CONF_DIR};"

  if [ "$clusterType" == "PaaS" ]; then
    to_export+="
    export JAVA_HOME=${JAVA_HOME};
    "
  else
    to_export+="
    $(get_hive_exports)
    export PATH='$PATH:$BENCH_HADOOP_DIR/bin:$MAHOUT_HOME/bin';"

    if [ "$ENGINE" == "spark_sql" ] || [ "$HIVE_ML_FRAMEWORK" == "spark" ]; then
      to_export_spark="$(get_spark_exports)"
      to_export+="$to_export_spark"
    fi

    if [ "$HIVE_ENGINE" == "tez" ]; then
      to_export_tez="$(get_tez_exports)"
      to_export+="$to_export_tez"
    fi

    if [ "$USE_EXTERNAL_DATABASE" == "true" ]; then
      server_exports=$(get_derby_exports)
      to_export+="${server_exports}"
    fi
  fi
  echo -e "$to_export\n"
}

# Returns the the path to the BigBench binary with the proper exports
# $1 scale factor to use
# $2 instance of the query
get_BigBench_cmd() {
  local BigBench_exports
  local BigBench_cmd

  BigBench_exports="$(get_BigBench_exports "$1" "$2")"
  BigBench_bin="$(get_local_apps_path)/${BIG_BENCH_FOLDER}/bin/bigBench"
  BigBench_cmd="$BigBench_exports\n$BigBench_bin"

  echo -e "$BigBench_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
# $4 scale factor to use
# $5 instance of the query to use
execute_BigBench(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local scale_factor="$4"
  local BigBench_exports
  local BigBench_cmd="$(get_BigBench_cmd "$scale_factor" "$5") $cmd"

  logger "DEBUG: BigBench command:\n$BigBench_cmd"

  # Run the command and time it
  execute_master "$bench" "$BigBench_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    save_BigBench "$bench"
  fi
}


# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_parallel_BigBench(){
  local bench="$1"
  local cmds="$2"
  local time_exec="$3"
  local BigBench_cmd

  IFS=';' read -ra cmds_vectorized <<< "$cmds"; IFS=' ' read -ra scales_vectorized <<< "$BB_SCALE_FACTORS" #Vectorize cmds and scale factors to access them in a single loop
  for i in "${!cmds_vectorized[@]}"; do
#    BigBench_cmd+="$(get_BigBench_cmd "$scales_vectorized[$i]") $cmds_vectorized[$1]"
     BigBench_cmd+="$(get_BigBench_cmd "${scales_vectorized[i]}") ${cmds_vectorized[i]} &
     "
  done
#  BigBench_cmd+="wait"


  logger "DEBUG: BigBench command:\n$BigBench_cmd"

  # Run the command and time it
  execute_master "$bench" "$BigBench_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    save_BigBench "$bench"
  fi
}

prepare_BigBench_minimum_dataset() {
    #Copying main data
    execute_hadoop_new "$bench_name" "fs -mkdir -p $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/base/"
    execute_hadoop_new "$bench_name" "fs -copyFromLocal $BIG_BENCH_HOME/data-generator/minimum_dataset/BB_data/* $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/base"
    execute_hadoop_new "$bench_name" "fs -ls $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/base"

    #Copying data_refresh
    execute_hadoop_new "$bench_name" "fs -mkdir -p $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/data_refresh"
    execute_hadoop_new "$bench_name" "fs -copyFromLocal $BIG_BENCH_HOME/data-generator/minimum_dataset/BB_data_refresh/* $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/data_refresh/"
    execute_hadoop_new "$bench_name" "fs -ls $HDFS_DATA_ABSOLUTE_PATH/bigbench_min/data_refresh"
}

initialize_BigBench_vars() {
  BIG_BENCH_HOME="$(get_local_apps_path)/$BIG_BENCH_FOLDER"
  BIG_BENCH_RESOURCE_DIR=${BIG_BENCH_HOME}/engines/hive/queries/Resources
  BIG_BENCH_CONF_DIR="$(get_local_bench_path)/BigBench_conf"
  HDFS_DATA_ABSOLUTE_PATH="/dfs/benchmarks/bigbench/data"
  BIG_BENCH_PARAMETERS_FILE="$(get_local_bench_path)/BigBench_conf/engines/hive/conf/BigBenchParameters"
  BIG_BENCH_QUERY_PARAMETERS="$(get_local_bench_path)/BigBench_conf/engines/hive/conf/queryParameters.sql"

  if [ "$clusterType" == "PaaS" ]; then
    MAHOUT_HOME="$(get_local_apps_path)/${MAHOUT_FOLDER}" #TODO need to change mahout usage in PaaS

  else
    MAHOUT_HOME="$(get_local_apps_path)/${MAHOUT_FOLDER}"
  fi
}

# Sets the substitution values for the BigBench config
get_BigBench_substitutions() {
  local java_bin
  local bin
  local hive_bin
  local hive_params
  local spark_params
  local hive_joins
  local database_jars
  local spark_database_opts


  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"


  if [ "$HIVE_ENGINE" == "mr" ]; then #For MapReduce DO NOT do MapJoins, MR uses lots of memory and tends to fail anyways because of high Garbage Collection times.
    hive_joins="true"
  else
    hive_joins="false"
  fi

  #TODO: Eliminate the Beeline patch when hive 2 client is available.
  if [ "$HIVE_MAJOR_VERSION" == "2" ]; then # Temporal patch to use Hive2 in HDI until they upgrade it to use Hive client.
    bin="beeline"
    hive_params="-n hive -p hive -u '${BB_ZOOKEEPER_QUORUM}'"
  else
    bin="hive"
  fi

  if [ "$clusterType" == "PaaS" ]; then
    java_bin="$(which java)"
    hive_bin="$HIVE_HOME/bin/${bin}"
    spark_params="--driver-memory 5g" #BB is memory intensive in the driver, 1GB (default) is not enough (override)

  else
    java_bin="$(get_java_home)/bin/java"
    hive_bin="$HIVE_HOME/bin/${bin}"
        #Calculate Spark settings for BigBench
    if [ "$USE_EXTERNAL_DATABASE" == "true" ]; then
      database_jars="$(get_database_driver_path_coma),"
      spark_database_opts="--jars "
    fi
  fi

#TODO spacing when a @ is found
    cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##JAVA_BIN##,$java_bin,g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##HIVE_SETTINGS_FILE##,$HIVE_SETTINGS_FILE,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/BigBench_logs,g;
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
s,##HDD##,$HDD,g;
s,##HIVE##,$HIVE_HOME,g;
s,##HIVE_BIN##,$hive_bin,g;
s%##HIVE_PARAMS##%$hive_params%g;
s,##HDFS_DATA_ABSOLUTE_PATH##,$HDFS_DATA_ABSOLUTE_PATH/data,g;
s,##HDFS_PATH##,$(get_local_bench_path)/bench_data,g;
s,##HADOOP_CONF##,$HADOOP_CONF_DIR,g;
s,##HADOOP_LIBS##,$BENCH_HADOOP_DIR/lib/native,g;
s,##SPARK##,$SPARK_HOME/bin/spark-sql,g;
s,##SPARK_SUBMIT##,$SPARK_HOME/bin/spark-submit,g;
s,##SCALE##,$BENCH_SCALE_FACTOR,g;
s,##SPARK_PARAMS##,$spark_params,g;
s,##BB_HDFS_ABSPATH##,$BB_HDFS_ABSPATH,g;
s,##ENGINE##,$ENGINE,g;
s,##HIVE_ML_FRAMEWORK##,$HIVE_ML_FRAMEWORK,g;
s,##BB_PARALLEL_STREAMS##,$BB_PARALLEL_STREAMS,g;
s%##DATABASE_JARS##%$database_jars%g;
s%##SPARK_DATABASE_OPTS##%$spark_database_opts%g
EOF
}

# $1: Bench name
prepare_BigBench_config_files() {

  for scale_factor in $BB_SCALE_FACTORS ; do

      logger "INFO: Preparing BigBench parameter files"
      cat $BIG_BENCH_QUERY_PARAMETERS > ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor

      if [ ! "$clusterType" == "PaaS" ]; then
        cat $HIVE_SETTINGS_FILE >> ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor
      fi

      echo "set bigbench.hive.optimize.sampling.orderby=true;
    set bigbench.hive.optimize.sampling.orderby.number=20000;
    set bigbench.hive.optimize.sampling.orderby.percent=0.1;
    set bigbench.resources.dir=$BIG_BENCH_RESOURCE_DIR;
    set bigbench.tableFormat_source=$HIVE_FILEFORMAT;
    set bigbench.tableFormat=TEXTFILE;
    set bigbench.data_path=$HDFS_DATA_ABSOLUTE_PATH/bigbench_$scale_factor/base;
    set bigbench.data_refresh_path=$HDFS_DATA_ABSOLUTE_PATH/bigbench_$scale_factor/data_refresh;" >> ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor

      echo " -- Database - DO NOT DELETE OR CHANGE
    CREATE DATABASE IF NOT EXISTS bigbench_$scale_factor;
    use bigbench_$scale_factor;" >> ${BIG_BENCH_PARAMETERS_FILE}_$scale_factor
  done
}

prepare_BigBench() {

  logger "INFO: Preparing BigBench"

  $DSH "mkdir -p $BIG_BENCH_CONF_DIR && cp -r $(get_local_configs_path)/BigBench_conf_template/* $BIG_BENCH_CONF_DIR/"

  # Get the values
  subs=$(get_BigBench_substitutions)
  logger "INFO: Making substitutions"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $BIG_BENCH_CONF_DIR/conf/userSettings.conf"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $BIG_BENCH_CONF_DIR/engines/hive/conf/engineSettings.conf"
  $DSH "/usr/bin/perl -i -pe \"$subs\" $BIG_BENCH_CONF_DIR/engines/spark_sql/conf/engineSettings.conf"

  if [[ "$USE_EXTERNAL_DATABASE" == "true" ]]  && [[ "$ENGINE" == "spark_sql" || "$HIVE_ML_FRAMEWORK" == "spark" ]]; then
    logger "WARNING: copying Hive-site.xml to spark conf folder"
    $DSH "cp $(get_local_bench_path)/hive_conf/hive-site.xml $SPARK_CONF_DIR/"
  fi
  prepare_BigBench_config_files
}

# $1 bench
save_BigBench() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/BigBench_logs;"
  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/BigBench_results;"

  logger "INFO: Saving BigBench query results to $JOB_PATH/$bench_name_num/BigBench_results"

  # Check if we copy or move the logs
  if [[ ! "$BENCH_LEAVE_SERVICES" || "$BENCH_LIST" != *"$bench"  ]] ; then
    execute_master "$bench_name" "mv $(get_local_bench_path)/BigBench_logs/* $JOB_PATH/$bench_name_num/BigBench_logs/"
  else
    execute_master "$bench_name" "cp -r $(get_local_bench_path)/BigBench_logs/* $JOB_PATH/$bench_name_num/BigBench_logs/"
  fi

  # Copy to the query results to the job folder
  execute_hadoop_new "$bench_name" "fs -copyToLocal $HDFS_DATA_ABSOLUTE_PATH/query_results/* $JOB_PATH/$bench_name_num/BigBench_results"
  # Then ALWAYS delete from HDFS, as they take a LOT of space
  execute_hadoop_new "$bench_name" "fs -rm $HDFS_DATA_ABSOLUTE_PATH/query_results/*"

  # If the scale factor is >1, we want to truncate the results as the are quite large.  And only 1GB validates
  if (( BENCH_SCALE_FACTOR > 1 )); then
    log_INFO "Truncating results to 10K lines for scale factor $BENCH_SCALE_FACTOR"
    execute_master "find $JOB_PATH/$bench_name_num/BigBench_results -type f -exec sed -i '10001,$ d'"
  fi



  # Compressing BigBench config
  execute_master "$bench_name" "cd  $(get_local_bench_path) && tar -cjf $JOB_PATH/BigBench_conf.tar.bz2 BigBench_conf"
  save_hive "$bench_name"
}
