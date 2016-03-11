#HIVE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_hive_requires() {
  [ ! "$HIVE_VERSION" ] && die "No HIVE_VERSION SPECIFIED"

  if [ "$(get_hadoop_major_version)" == "2" ]; then
    BENCH_REQUIRED_FILES["$HIVE_VERSION"]="http://www-us.apache.org/dist/hive/stable/$HIVE_VERSION.tar.gz"
  else
    BENCH_REQUIRED_FILES["$HIVE_VERSION"]="http://www-us.apache.org/dist/hive/stable/$HIVE_VERSION.tar.gz"
    #BENCH_REQUIRED_FILES["apache-hive-0.13.1-bin"]="https://archive.apache.org/dist/hive/hive-0.13.1/apache-hive-0.13.1-bin.tar.gz"
  fi

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS hive1_conf_template"
}

# Helper to print a line with Hadoop requiered exports
get_hive_exports() {
  local to_export

  to_export="$(get_hadoop_exports)
export HIVE_VERSION='$HIVE_VERSION';
export HIVE_HOME='$(get_local_apps_path)/${HIVE_VERSION}';
export HIVE_CONF_DIR=$HIVE_CONF_DIR;
"

  if [ "$EXECUTE_TPCH" ]; then
    to_export="${to_export} export TPCH_HOME='$(get_local_apps_path)/tpch-hive';"
  fi

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
get_hive_cmd() {
  local hive_exports
  local hive_cmd

  hive_exports="$(get_hive_exports)"

  local hive_settings_file
  [ "$HIVE_SETTINGS_FILE" ] && hive_settings_file="-i $HIVE_SETTINGS_FILE"

  hive_cmd="$hive_exports\ncd '$HDD_TMP';\n$HIVE_HOME/bin/hive $hive_settings_file"

  echo -e "$hive_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_hive(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local hive_cmd="$(get_hive_cmd) $cmd"

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: Hive command:\n$hive_cmd"

  # Run the command and time it
  time_cmd_master "$hive_cmd" "$time_exec"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_hive "$bench"
  fi
}

initialize_hive_vars() {
  [ ! "$HIVE_SETTINGS_FILE" ] && HIVE_SETTINGS_FILE="$HDD/hive_conf/hive.settings"
  #[ ! "$HIVE_SETTINGS_FILE_PATH" ] && HIVE_SETTINGS_FILE_PATH="$HDD/hive_conf_template/${HIVE_SETTINGS_FILE}"

  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS
hive_conf_template"

  if [ "$clusterType" == "PaaS" ]; then
    HIVE_HOME="/usr/bin/hive"
    HIVE_CONF_DIR="/etc/hive/conf"
  else
    HIVE_HOME="$(get_local_apps_path)/${HIVE_VERSION}"
    HIVE_CONF_DIR="$HDD/hive_conf"
  fi
}

# Sets the substitution values for the hive config
get_hive_substitutions() {

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
s,##LOG_DIR##,$HDD/hive_logs,g;
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
EOF
}

get_hive_conf_dir() {
  echo -e "$HDD/hive_conf"
}

prepare_hive_config() {

  if [ "$clusterType" == "PaaS" ]; then
    logger "INFO: in PaaS mode, not changing Hive system config"
  else
    logger "INFO: Preparing Hive run specific config"
    $DSH "mkdir -p $(get_hive_conf_dir) $HDD/hive_logs; cp -r $(get_local_configs_path)/hive1_conf_template/* $(get_hive_conf_dir);"

    # Get the values
    subs=$(get_hive_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $HIVE_SETTINGS_FILE"

    $DSH "
$(get_perl_exports)
/usr/bin/perl -i -pe \"$subs\" $HIVE_SETTINGS_FILE;
/usr/bin/perl -i -pe \"$subs\" $(get_hive_conf_dir)/*.xml;
/usr/bin/perl -i -pe \"$subs\" $(get_hive_conf_dir)/*.properties;"

#    if [ ! -z "$MAPS_MB" ]; then
#        $DSH "echo 'set mapreduce.map.memory.mb=${MAPS_MB};' >> ${HIVE_SETTINGS_FILE_PATH}"
#    fi
#    if [ ! -z "$REDUCES_MB" ]; then
#        $DSH "echo 'set mapreduce.reduce.memory.mb=${REDUCES_MB};' >> ${HIVE_SETTINGS_FILE_PATH}"
#    fi
#    if  [[ "$defaultProvider" == "rackspacecbd" ]]; then
#      $DSH "echo 'set hive.metastore.warehouse.dir=/user/${userAloja}/warehouse;' >> ${HIVE_SETTINGS_FILE_PATH}"
#    fi

    # Make sure default folders exists in Hadoop
    create_hive_folders

  fi
}

# Creates required Hive folders in HDFS
create_hive_folders() {
  if [ ! "$BENCH_KEEP_FILES" ] ; then
    logger "INFO: Creating Hive default folders in HDFS"
    execute_hadoop_new "Hive folders" "fs -mkdir -p /tmp/hive /user/hive/warehouse"
    execute_hadoop_new "Hive folders" "fs -chmod 777 /tmp/hive /user/hive/warehouse"
    #execute_hadoop_new "Hive folders" "fs -chmod g+w /tmp"
    #execute_hadoop_new "Hive folders" "fs -chmod g+w /user/hive/warehouse"
  fi
}

# $1 bench
save_hive() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  # Create the hive logs dir
  $DSH "mkdir -p $JOB_PATH/$1/hive_logs;"

  # Save hadoop logs
  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    $DSH "cp -r /var/log/hive $JOB_PATH/$1/hive_logs/" #2> /dev/null

    # Save Hive conf
    $DSH_MASTER "cd /etc/hive; tar -cjf $JOB_PATH/hive_conf.tar.bz2 conf"
  else
    if [ "$BENCH_LEAVE_SERVICES" ] ; then
      $DSH "cp $HDD/hive_logs/* $JOB_PATH/$1/hive_logs/ " #2> /dev/null
    else
      $DSH "mv $HDD/hive_logs/* $JOB_PATH/$1/hive_logs/ " #2> /dev/null
    fi

    # Save Hive conf
    $DSH_MASTER "cd $HDD/; tar -cjf $JOB_PATH/hive_conf.tar.bz2 hive_conf"
  fi

  logger "INFO: Compresing and deleting hadoop configs for $1"

  $DSH_MASTER "
cd $JOB_PATH;
if [ \"\$(ls conf_* 2> /dev/null)\" ] ; then
  tar -cjf $JOB_PATH/hadoop_host_conf.tar.bz2 conf_*;
  rm -rf conf_*;
fi
"

  # save hadoop and defaults
  save_hadoop "$1"
}