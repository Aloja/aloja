#HIVE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_hive_requires() {
  [ ! "$HIVE_VERSION" ] && die "No HIVE_VERSION specified"

  if [ "$clusterType" != "PaaS" ]; then
    if [ "$(get_hadoop_major_version)" == "2" ]; then
      # TODO need to fix the paths for Hive
      BENCH_REQUIRED_FILES["$HIVE_VERSION"]="http://www-us.apache.org/dist/hive/hive-1.2.2/$HIVE_VERSION.tar.gz"
      if [ "$HIVE_ENGINE" == "tez" ]; then
        source_file "$ALOJA_REPO_PATH/shell/common/common_tez.sh"
        set_tez_requires
      fi
    else
      BENCH_REQUIRED_FILES["$HIVE_VERSION"]="http://www-us.apache.org/dist/hive/stable/$HIVE_VERSION.tar.gz"
      #BENCH_REQUIRED_FILES["apache-hive-0.13.1-bin"]="https://archive.apache.org/dist/hive/hive-0.13.1/apache-hive-0.13.1-bin.tar.gz"
    fi
  fi

  if [ ! "$BB_ZOOKEEPER_QUORUM" ]; then #TODO need to add on-premise support
    HIVE_MAJOR_VERSION="1"
  else
    HIVE_MAJOR_VERSION="2"
  fi

  #also set the config here
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS hive1_conf_template"
}

# Helper to print a line with required exports
get_hive_exports() {
  local to_export
  local tez_exports

 if [ "$clusterType" == "PaaS" ]; then
  : # Empty
 else
    to_export="$(get_hadoop_exports)
export HIVE_VERSION='$HIVE_VERSION';
export HIVE_HOME='$(get_local_apps_path)/${HIVE_VERSION}';
export HIVE_CONF_DIR='$HIVE_CONF_DIR';"

    if [ "$EXECUTE_TPCH" ]; then
      to_export="${to_export} export TPCH_HOME='$(get_local_apps_path)/$TPCH_DIR';"
    fi

    if [ "$HIVE_ENGINE" == "tez" ]; then
      tez_exports=$(get_tez_exports)
      to_export+="${tez_exports}"
    fi
    echo -e "$to_export\n"
  fi
}

# Returns the the path to the hadoop binary with the proper exports
get_hive_cmd() {
  local hive_exports
  local hive_cmd
  local hive_bin
  local hive_settings_file

  # if in PaaS use the bin in PATH and no exports
  if [ "$clusterType" == "PaaS" ]; then
    hive_bin="hive"
    hive_exports=""
  else
    hive_exports="$(get_hive_exports)"
    local hive_bin="$HIVE_HOME/bin/hive"
  fi

  [ "$HIVE_SETTINGS_FILE" ] && hive_settings_file="-i $HIVE_SETTINGS_FILE"

  hive_cmd="$hive_exports\n$hive_bin $hive_settings_file" #\ncd '$HDD_TMP';

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

  # Run the command and time it
  execute_master "$bench" "$hive_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    save_hive "$bench"
  fi
}

initialize_hive_vars() {

  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS hive_conf_template"

  if [ "$clusterType" == "PaaS" ]; then
    HIVE_HOME="/usr"
    HIVE_CONF_DIR="/etc/hive/conf"
    [ ! "$HIVE_SETTINGS_FILE" ] && HIVE_SETTINGS_FILE="$HDD/hive_conf/hive.settings_PaaS"
  else
    HIVE_HOME="$(get_local_apps_path)/${HIVE_VERSION}"
    HIVE_CONF_DIR="$HDD/hive_conf"

    [ ! "$HIVE_SETTINGS_FILE" ] && HIVE_SETTINGS_FILE="$HDD/hive_conf/hive.settings"

    if [ "$HIVE_ENGINE" == "tez" ]; then
      initialize_tez_vars
      prepare_tez_config
    fi
  fi
}

# Sets the substitution values for the hive config
get_hive_substitutions() {
  local database_driver
  local database_driver_name
  local url
  if [ "$clusterType" != "PaaS" ]; then
      if [ "$USE_EXTERNAL_DATABASE" == "true" ]; then
        database_driver="$(get_database_driver_path_colon)"
        database_driver_name="$(get_database_driver_name)"
        url=$(get_database_connection_url)
      else
        database_driver_name="org.apache.derby.jdbc.EmbeddedDriver"
        url="jdbc:derby:;databaseName=$(get_local_bench_path)/aplic/bigbench_metastore_db;create=true"
      fi
  fi

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  # Give Hive 10% of container mem for hive.auto.convert.join.noconditionaltask.size
  JOIN_HIVE="$(echo "${MAPS_MB}*0.05" | bc -l)"
  JOIN_HIVE="$(echo "${JOIN_HIVE}*1000000" | bc -l)"
  JOIN_HIVE="$(printf "%.0f" $JOIN_HIVE)"

  CONTAINER_80="$(echo "${MAPS_MB}*0.80" | bc -l)"
  CONTAINER_80="$(printf "%.0f" $CONTAINER_80)"

  CONTAINER_40="$(echo "${MAPS_MB}*0.40" | bc -l)"
  CONTAINER_40="$(printf "%.0f" $CONTAINER_40)"

  CONTAINER_10="$(echo "${MAPS_MB}*0.10" | bc -l)"
  CONTAINER_10="$(printf "%.0f" $CONTAINER_10)"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##HIVE_CONF_DIR##,$HIVE_CONF_DIR,g;
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
s,##JOIN_HIVE##,$JOIN_HIVE,g;
s,##CONTAINER_80##,$CONTAINER_80,g;
s,##CONTAINER_40##,$CONTAINER_40,g;
s,##CONTAINER_10##,$CONTAINER_10,g;
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
s,##HIVE_ENGINE##,$HIVE_ENGINE,g;
s,##HIVE_JOINS##,$HIVE_JOINS,g;
s,##DATABASE_DRIVER##,$database_driver,g;
s,##DATABASE_DRIVER_NAME##,$database_driver_name,g;
s,##URL##,$url,g
EOF
}

get_hive_conf_dir() {
  echo -e "$HDD/hive_conf"
}

prepare_hive_config() {

  if [ "$clusterType" == "PaaS" ]; then
    logger "INFO: in PaaS mode, not changing Hive system config"

    #For CBD at least TODO verify
    #log_INFO "Making sure permissions are open in hive"
    #time_cmd_master "sudo -u hive hadoop fs -chmod -R 777 /user/hive/ /hive/warehouse/"
    #just in case
    #time_cmd_master "sudo hadoop fs -chmod -R 777 /user/hive/ /hive/warehouse/"
    log_INFO "Listing hive warehouse permissions (but not changing them)"
    execute_hadoop_new "Hive folders" "fs -ls /user/hive/ /hive/warehouse/"

    $DSH "mkdir -p $(get_hive_conf_dir); cp -r $(get_local_configs_path)/hive1_conf_template/hive.settings_PaaS $(get_hive_conf_dir);"
  else
    logger "INFO: Preparing Hive run specific config"
    $DSH "mkdir -p $(get_hive_conf_dir) $HDD/hive_logs; cp -r $(get_local_configs_path)/hive1_conf_template/* $(get_hive_conf_dir);"

    # Get the values
    subs=$(get_hive_substitutions)
    $DSH "/usr/bin/perl -i -pe \"$subs\" $HIVE_SETTINGS_FILE"

    $DSH "
$(get_perl_exports)
/usr/bin/perl -i -pe \"$subs\" $HIVE_SETTINGS_FILE;
/usr/bin/perl -i -pe \"$subs\" $(get_hive_conf_dir)/*;"

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

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create the hive logs dir
  $DSH "mkdir -p $JOB_PATH/$bench_name_num/hive_logs;"

  # Save hadoop logs
  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    $DSH "mv -r /var/log/hive $JOB_PATH/$bench_name_num/hive_logs/" #2> /dev/null

    # Save Hive conf
    $DSH_MASTER "cd /etc/hive; tar -cjf $JOB_PATH/hive_conf.tar.bz2 conf"
  else
    if [ "$BENCH_LEAVE_SERVICES" ] ; then
      $DSH "cp $HDD/hive_logs/* $JOB_PATH/$bench_name_num/hive_logs/ 2> /dev/null"
    else
      $DSH "mv $HDD/hive_logs/* $JOB_PATH/$bench_name_num/hive_logs/ 2> /dev/null"
    fi

    # Save Hive conf
    $DSH_MASTER "cd $HDD/; tar -cjf $JOB_PATH/hive_conf.tar.bz2 hive_conf"
  fi

  logger "INFO: Compresing and deleting hadoop configs for $bench_name_num"

  # save tez
  if [ "$HIVE_ENGINE" == "tez" ]; then
    save_tez "$bench_name"
  fi

  # save hadoop and defaults
  save_hadoop "$bench_name"
}

clean_hive() {
  if [ "$USE_EXTERNAL_DATABASE" == "true" ]; then
    stop_derby
  fi
}