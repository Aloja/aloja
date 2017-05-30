# Sets the required files to download/copy
set_tez_requires() {
  [ ! "$TEZ_VERSION" ] && die "No tez_VERSION specified"

  TEZ_FOLDER="apache-tez-${TEZ_VERSION}-bin"
  BENCH_REQUIRED_FILES["$TEZ_FOLDER"]="http://archive.apache.org/dist/tez/$TEZ_VERSION/$TEZ_FOLDER.tar.gz"

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS apache-tez-0.x-bin_conf_template"
}

# Helper to print a line with required exports
get_tez_exports() {
  local to_export
  local TEZ_JARS=$(get_local_apps_path)/${TEZ_FOLDER}
  local TEZ_CONF_DIR=$(get_tez_conf_dir)

  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    to_export="
export TEZ_JARS='$TEZ_JARS';
export TEZ_CONF_DIR='$TEZ_CONF_DIR';
export HADOOP_CLASSPATH=\"\$HADOOP_CLASSPATH:${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*\";
export CLASSPATH=\"\$CLASSPATH:${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*\";"
    echo -e "$to_export\n"
  fi
}

initialize_tez_vars() {
  if [ "$clusterType" == "PaaS" ]; then
    TEZ_HOME=""
    TEZ_CONF_DIR="/etc/tez/conf"
  else
    TEZ_HOME="$(get_local_apps_path)/${TEZ_FOLDER}"
    TEZ_CONF_DIR="$(get_tez_conf_dir)"
    TEZ_TARBALL_NAME=$(ls ${TEZ_HOME}/share)
  fi
}

# Sets the substitution values for the tez config
get_tez_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/tez_logs,g;
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
s,##IO_TEZ##,$IO_TEZ,g;
s,##JOIN_TEZ##,$JOIN_TEZ,g;
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
s,##TEZ_EXECUTOR_EXTRA_CLASSPATH##,$HIVE_HOME/lib/:$HIVE_CONF_DIR,g;
s,##HDFS_PATH##,$(get_local_bench_path)/bench_data,g;
s,##HADOOP_CONF##,$HADOOP_CONF_DIR,g;
s,##HADOOP_LIBS##,$BENCH_HADOOP_DIR/lib/native,g;
s,##TEZ##,$TEZ_HOME/bin/tez,g;
s,##TEZ_CONF##,$TEZ_CONF_DIR,g;
s,##TEZ_URI##,/apps/$TEZ_TARBALL_NAME,g;
EOF
}

get_tez_conf_dir() {
  echo -e "$(get_local_bench_path)/tez_conf"
}

prepare_tez_config() {
  logger "INFO: Preparing tez run specific config"
  if [ "$clusterType" == "PaaS" ]; then
    : # Empty
  else
    $DSH "mkdir -p $TEZ_CONF_DIR; cp -r $(get_local_configs_path)/apache-tez-0.x-bin_conf_template/* $TEZ_CONF_DIR/"
    subs=$(get_tez_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $TEZ_CONF_DIR/*"
  #  $DSH "cp $(get_local_bench_path)/hadoop_conf/slaves $tez_CONF_DIR/slaves"

    hadoop_copy_hdfs "/apps/" "$TEZ_HOME/share/$TEZ_TARBALL_NAME"
    if [ -f $TEZ_HOME/lib/slf4j-log4j* ]; then rm $TEZ_HOME/lib/slf4j-log4j* ; fi
  fi
}

# $1 bench name
save_tez() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create the hive logs dir
#  $DSH "mkdir -p $JOB_PATH/$bench_name_num/tez_logs;"

  # Save hadoop logs
  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    $DSH "cp -r /var/log/tez $JOB_PATH/$bench_name_num/tez_logs/" #2> /dev/null

    # Save Hive conf
    $DSH_MASTER "cd /etc/tez; tar -cjf $JOB_PATH/tez_conf.tar.bz2 conf"
  else
#    if [ "$BENCH_LEAVE_SERVICES" ] ; then
#      $DSH "cp $HDD/tez_logs/* $JOB_PATH/$bench_name_num/tez_logs/ 2> /dev/null"
#    else
#      $DSH "mv $HDD/tez_logs/* $JOB_PATH/$bench_name_num/tez_logs/ 2> /dev/null"
#    fi

    # Save Tez conf
    $DSH_MASTER "cd $HDD/; tar -cjf $JOB_PATH/tez_conf.tar.bz2 tez_conf"
  fi
}