#HADOOP 1 SPECIFIC FUNCTIONS

#$1 port prefix (optional)
get_aloja_dir() {
 if [ "$1" ] ; then
  echo "${BENCH_FOLDER}_$PORT_PREFIX"
 else
  echo "${BENCH_FOLDER}"
 fi
}

#$1 disk type
# TODO move to benchmark common file
get_initial_disk() {

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    local dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    #set the first dir
    local dir="${BENCH_DISKS["${disks_type}1"]}"

    #[ ! "$dir" ] && logger "ERROR: cannot find disk definition"

  else
    :
    #logger "ERROR: Incorrect disk specified: $1"
  fi

  echo -e "$dir"
}

#$1 disk type
get_tmp_disk() {

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    local dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    if [ "$disks_type" == "RL" ] ; then
      local dir="${BENCH_DISKS["HDD"]}"
    elif [ "$disks_type" == "HS" ] ; then
      local dir="${BENCH_DISKS["SSD"]}"
    else
      local dir="${BENCH_DISKS["${disks_type}1"]}"
    fi

    #[ ! "$dir" ] && logger "ERROR: cannot find disk definition"

  else
    :
    #logger "ERROR: Incorrect disk specified: $1"
  fi

  echo -e "$dir"
}

#1 disk type $2 postfix $3 port prefix
get_hadoop_conf_dir() {

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    local dir="${BENCH_DISKS["$1"]}/$(get_aloja_dir "$3")/$2"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    for disk_number in $(seq 1 $disks) ; do
      local dir="$dir\,${BENCH_DISKS["${disks_type}${disk_number}"]}/$(get_aloja_dir "$3")/$2"
    done

    local dir="${dir:2}" #remove leading \,
  else
    logger "ERROR: Incorrect disk specified: $1"
  fi

  echo -e "$dir"
}

get_hive_env(){
  echo "export HADOOP_PREFIX=${BENCH_H_DIR} && \
        export HADOOP_USER_CLASSPATH_FIRST=true && \
        export PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$JAVA_HOME/bin && \
  "
}

prepare_hive_config() {

subs=$(cat <<EOF
s,##HADOOP_HOME##,$BENCH_H_DIR,g;
s,##HIVE_HOME##,$HIVE_HOME,g;
EOF
)

  #to avoid perl warnings
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  loggerb "Copying Hive and Hive-testbench dirs"
  $DSH "cp -ru $BENCH_SOURCE_DIR/apache-hive-1.2.0-bin $HIVE_B_DIR/" 2>&1 |tee -a $LOG_PATH

  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-env.sh.template > $HIVE_HOME/conf/hive-env.sh" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-default.xml.template > $HIVE_HOME/conf/hive-default.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-log4j.properties.template > $HIVE_HOME/conf/hive-log4j.properties" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME.template > $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME" 2>&1 |tee -a $LOG_PATH
}

prepare_hadoop_config(){

  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
    local HADOOP_CONF_PATH="conf"
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    local HADOOP_CONF_PATH="etc/hadoop"
  fi

  #set hadoop home
  export HADOOP_HOME="${BENCH_SOURCE_DIR}/${BENCH_HADOOP_VERSION}"
  export HADOOP_YARN_HOME="$HADOOP_HOME"
  loggerb "DEBUG: HADOOP_HOME: $HADOOP_HOME\nHADOOP_YARN_HOME: $HADOOP_YARN_HOME"

  loggerb "Creating source dir and Copying Hadoop"
  $DSH "mkdir -p $HDD/{aplic,hadoop,logs}" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $BENCH_H_DIR" 2>&1 |tee -a $LOG_PATH

  $DSH "cp -ru $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}/* $BENCH_H_DIR/" 2>&1 |tee -a $LOG_PATH

  loggerb "Preparing config"

  $DSH "rm -rf $BENCH_H_DIR/$HADOOP_CONF_PATH/*" 2>&1 |tee -a $LOG_PATH

  MASTER="$master_name"

  IO_MB="$((IO_FACTOR * 10))"

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  logger "DEBUG: HDFS_NDIR: $HDFS_NDIR\nHDFS_DDIR: $HDFS_DDIR"

MAX_REDS="$MAX_MAPS"

subs=$(cat <<EOF
s,##JAVA_HOME##,$JAVA_HOME,g;
s,##HADOOP_HOME##,$BENCH_H_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/logs,g;
s,##REPLICATION##,$REPLICATION,g;
s,##MASTER##,$MASTER,g;
s,##NAMENODE##,$MASTER,g;
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
s,##AM_MB##,$REDUCES_MB,g;
s,##BENCH_DEFAULT_SCRATCH##,$BENCH_DEFAULT_SCRATCH,g;
s,##HDD##,$HDD,g;
EOF
)

slaves="$(get_slaves_names)"


  #to avoid perl warnings
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  $DSH "cp $BENCH_H_DIR/conf_template/* $BENCH_H_DIR/$HADOOP_CONF_PATH/" 2>&1 |tee -a $LOG_PATH

  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/hadoop-env.sh > $BENCH_H_DIR/$HADOOP_CONF_PATH/hadoop-env.sh" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/core-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/core-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/hdfs-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/mapred-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml" 2>&1 |tee -a $LOG_PATH
  if [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/yarn-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml" 2>&1 |tee -a $LOG_PATH
    $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/yarn-env.sh > $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-env.sh" 2>&1 |tee -a $LOG_PATH
    $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/mapred-env.sh > $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-env.sh" 2>&1 |tee -a $LOG_PATH
  fi

  loggerb "Replacing per host config"

  for node in $node_names ; do
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml.tmp; rm $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml; mv $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml.tmp $BENCH_H_DIR/$HADOOP_CONF_PATH/mapred-site.xml" 2>&1 |tee -a $LOG_PATH &
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml.tmp; rm $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml; mv $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml.tmp $BENCH_H_DIR/$HADOOP_CONF_PATH/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH &
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml > $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml.tmp; rm $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml; mv $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml.tmp $BENCH_H_DIR/$HADOOP_CONF_PATH/yarn-site.xml" 2>&1 |tee -a $LOG_PATH &
  done

  $DSH "echo -e \"$MASTER\" > $BENCH_H_DIR/$HADOOP_CONF_PATH/masters" 2>&1 |tee -a $LOG_PATH
  $DSH "echo -e \"$slaves\" > $BENCH_H_DIR/$HADOOP_CONF_PATH/slaves" 2>&1 |tee -a $LOG_PATH


  #save config
  loggerb "Saving config"
  create_conf_dirs=""
  for node in $node_names ; do
    create_conf_dirs="$create_conf_dirs mkdir -p $JOB_PATH/conf_$node ;"
  done

  $DSH "$create_conf_dirs" 2>&1 |tee -a $LOG_PATH

  for node in $node_names ; do
    ssh "$node" "cp $BENCH_H_DIR/$HADOOP_CONF_PATH/* $JOB_PATH/conf_$node" 2>&1 |tee -a $LOG_PATH &
  done

  # Set correct permissions for instrumentation's sniffer
  if [ "$INSTRUMENTATION" == "1" ] ; then
    loggerb "Setting permissions for instrumentation's sniffer"
    $DSH "sudo apt-get install -y binutils-dev" 2>&1 |tee -a $LOG_PATH
    $DSH "sudo -n setcap cap_net_raw=eip ${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/bin/sniffer" 2>&1 |tee -a $LOG_PATH
  fi
}

full_name="Not SET"
get_bench_name(){
  if [ "$1" == "wordcount" ] ; then
    full_name="Wordcount"
  elif [ "$1" == "sort" ] ; then
    full_name="Sort"
  elif [ "$1" == "terasort" ] ; then
    full_name="Terasort"
  elif [ "$1" == "kmeans" ] ; then
    full_name="KMeans"
  elif [ "$1" == "pagerank" ] ; then
    full_name="Pagerank"
  elif [ "$1" == "bayes" ] ; then
    full_name="Bayes"
  elif [ "$1" == "hivebench" ] ; then
    full_name="Hivebench"
  elif [ "$1" == "dfsioe" ] ; then
    full_name="DFSIOE"
  else
    full_name="INVALID"
  fi
}

restart_hadoop(){
  loggerb "Restart Hadoop"
  #just in case stop all first
  if [ "$HADOOP_VERSION" == "hadoop2" ]; then
    $DSH_MASTER $BENCH_H_DIR/sbin/stop-dfs.sh 2>&1 >> $LOG_PATH
    $DSH_MASTER $BENCH_H_DIR/sbin/stop-yarn.sh 2>&1 >> $LOG_PATH
    $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver 2>&1 >> $LOG_PATH
  else
    $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH
  fi

  #delete previous run logs
  $DSH "rm -rf $HDD/logs; mkdir -p $HDD/logs" 2>&1 |tee -a $LOG_PATH

  if [ "$DELETE_HDFS" == "1" ] ; then
    loggerb "Deleting previous Hadoop HDFS"
#$DSH "rm -rf $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/*" 2>&1 |tee -a $LOG_PATH
#$DSH "mkdir -p $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/" 2>&1 |tee -a $LOG_PATH
#TODO fix for variable paths
# $DSH "rm -rf /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/{dfs,mapred,logs}" 2>&1 |tee -a $LOG_PATH
# $DSH "mkdir -p /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/dfs/data; chmod 755 /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/dfs/data;" 2>&1 |tee -a $LOG_PATH
# $DSH "mkdir -p /scratch/local/$(get_aloja_dir "$PORT_PREFIX")/dfs/data; chmod 755 /scratch/local/$(get_aloja_dir "$PORT_PREFIX")/dfs/data" 2>&1 |tee -a $LOG_PATH
    $DSH "rm -rf $HDD/{dfs,mapred,logs,nm-local-dir} $HDD_TMP/{dfs,mapred,logs,nm-local-dir}; mkdir -p $HDD/logs $HDD_TMP/;" 2>&1 |tee -a $LOG_PATH
    #send multiple yes to format
    if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      $DSH_MASTER "yes Y | $BENCH_H_DIR/bin/hadoop namenode -format" 2>&1 |tee -a $LOG_PATH
      $DSH_MASTER "yes Y | $BENCH_H_DIR/bin/hadoop datanode -format" 2>&1 |tee -a $LOG_PATH
    elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      $DSH_MASTER "yes Y | $BENCH_H_DIR/bin/hdfs namenode -format" 2>&1 |tee -a $LOG_PATH
    fi
  fi

  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      $DSH_MASTER $BENCH_H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      $DSH_MASTER $BENCH_H_DIR/sbin/start-dfs.sh 2>&1 |tee -a $LOG_PATH
      $DSH_MASTER $BENCH_H_DIR/sbin/start-yarn.sh 2>&1 |tee -a $LOG_PATH
      $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh start historyserver 2>&1 |tee -a $LOG_PATH
  fi

  for i in {0..300} #3mins
  do
    if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      local report=$($DSH_MASTER $BENCH_H_DIR/bin/hadoop dfsadmin -report 2> /dev/null)
      local num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
      local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      local report=$($DSH_MASTER $BENCH_H_DIR/bin/hdfs dfsadmin -report 2> /dev/null)
      local num=$(echo "$report" | grep "Live datanodes" | awk '{print $3}')
      num="${num:1:${#num}-3}"
      local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    fi
    echo $report 2>&1 |tee -a $LOG_PATH

    if [ "$num" == "$NUMBER_OF_DATA_NODES" ] ; then
      if [[ -z $safe_mode ]] ; then
        #everything fine continue
        break
      elif [ "$i" == "30" ] ; then
        loggerb "Still in Safe mode, MANUALLY RESETTING SAFE MODE wating for $i seconds"
        if [ "$HADOOP_VERSION" == "hadoop1" ]; then
          $DSH_MASTER $BENCH_H_DIR/bin/hadoop dfsadmin -safemode leave 2>&1 |tee -a $LOG_PATH
        elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
          $DSH_MASTER $BENCH_H_DIR/bin/hdfs dfsadmin -safemode leave 2>&1 |tee -a $LOG_PATH
        fi
      else
        loggerb "Still in Safe mode, wating for $i seconds"
      fi
    elif [ "$i" == "60" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      if [ "$HADOOP_VERSION" == "hadoop2" ]; then
        $DSH_MASTER $BENCH_H_DIR/sbin/stop-dfs.sh 2>&1 >> $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/stop-yarn.sh 2>&1 >> $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver 2>&1 |tee -a $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/start-dfs.sh 2>&1 |tee -a $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/start-yarn.sh 2>&1 |tee -a $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh start historyserver 2>&1 |tee -a $LOG_PATH
      else
        $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH
        $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver 2>&1 |tee -a $LOG_PATH
      fi

    elif [ "$i" == "180" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      loggerb "Reseting config to retry DELETE_HDFS WAS SET TO: $DELETE_HDFS"
      DELETE_HDFS="1"
      restart_hadoop no_retry
    elif [ "$i" == "120" ] ; then
      loggerb "$num/$NUMBER_OF_DATA_NODES Datanodes available, EXIT"
      exit 1
    else
      loggerb "$num/$NUMBER_OF_DATA_NODES Datanodes available, wating for $i seconds"
      sleep 1
    fi
  done

  set_omm_killer

  loggerb "Hadoop ready"
}

stop_hadoop(){
 if [ "$clusterType=" != "PaaS" ]; then
  loggerb "Stop Hadoop"
  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
    $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    $DSH_MASTER $BENCH_H_DIR/sbin/stop-yarn.sh 2>&1 |tee -a $LOG_PATH
    $DSH_MASTER $BENCH_H_DIR/sbin/stop-dfs.sh 2>&1 |tee -a $LOG_PATH
    $DSH_MASTER $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver 2>&1 |tee -a $LOG_PATH
  fi
  loggerb "Stop Hadoop ready"
 fi
}

execute_HiBench(){
  for bench in $(echo "$LIST_BENCHS") ; do
    restart_hadoop

    #Delete previous data
    #$DSH_MASTER "$BENCH_H_DIR/bin/hadoop fs -rmr /HiBench" 2>&1 |tee -a $LOG_PATH
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

    # Check if there is a custom config for this bench, and call it
    if type "benchmark_hibench_config_${bench}" &>/dev/null
    then
      eval "benchmark_hibench_config_${bench}"
    fi

    #just in case check if the input file exists in hadoop
    if [ "$DELETE_HDFS" == "0" ] ; then
      get_bench_name $bench
      input_exists=$($DSH_MASTER $BENCH_H_DIR/bin/hadoop fs -ls "/HiBench/$full_name/Input" 2> /dev/null |grep "Found ")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER $BENCH_H_DIR/bin/hadoop fs -ls "/HiBench/$full_name/Input" 2>&1 |tee -a $LOG_PATH
        DELETE_HDFS=1
        restart_hadoop
      fi
    fi

    echo "# $(date +"%H:%M:%S") STARTING $bench" 2>&1 |tee -a $LOG_PATH
    ##mkdir -p "$PREPARED/$bench"

    #if [ ! -f "$PREPARED/${i}.tbza" ] ; then

      #hive leaves tmp config files
      #if [ "$bench" != "hivebench" ] ; then
      #  $DSH_MASTER "rm /tmp/hive* /tmp/pristine/hive*" 2>&1 |tee -a $LOG_PATH
      #fi

      if [ "$DELETE_HDFS" == "1" ] ; then
        if [ "$bench" != "dfsioe" ] ; then
          execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare.sh "prep_"
        elif [ "$bench" == "dfsioe" ] ; then
          execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare-read.sh "prep_"
        fi
      else
        loggerb  "Reusing previous RUN prepared $bench"
      fi


      #if [ "$bench" = "wordcount" ] ; then
      #  echo "# $(date +"%H:%M:%S") SAVING PREPARED DATA for $bench"
      #
      #  $DIR/bin/hadoop fs -get /HiBench $PREPARED/$bench/
      #  tar -cjf $PREPARED/${i}.tbz $PREPARED/$bench/
      #  rm -rf $PREPARED/$bench
      #fi
    #else
    #  echo "# $(date +"%H:%M:%S") RESTORING PREPARED DATA for $bench"
    #  tar -xjf $PREPARED/${i}.tbz $PREPARED/
    #  $HADOOPDIR/bin/hadoop fs -put $PREPARED/HiBench /HiBench
    #  rm -rf $PREPARED/HiBench
    #fi

    loggerb  "$(date +"%H:%M:%S") RUNNING $bench"

    if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then
      execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/run.sh
    elif [ "$bench" == "hivebench" ] ; then
      execute_hadoop hivebench_agregation ${BENCH_HIB_DIR}/hivebench/bin/run-aggregation.sh
      execute_hadoop hivebench_join ${BENCH_HIB_DIR}/hivebench/bin/run-join.sh
    elif [ "$bench" == "dfsioe" ] ; then
      execute_hadoop dfsioe_read ${BENCH_HIB_DIR}/dfsioe/bin/run-read.sh
      execute_hadoop dfsioe_write ${BENCH_HIB_DIR}/dfsioe/bin/run-write.sh
    fi

  done
}

execute_HDI_HiBench(){
  for bench in $(echo "$LIST_BENCHS") ; do
    #Delete previous data
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

    # Check if there is a custom config for this bench, and call it
    if type "benchmark_hibench_config_${bench}" &>/dev/null
    then
      eval "benchmark_hibench_config_${bench}"
    fi

    #just in case check if the input file exists in hadoop
    if [ "$DELETE_HDFS" == "0" ] ; then
      get_bench_name $bench
      input_exists=$($DSH_MASTER hdfs dfs -ls "/HiBench/$full_name/Input" 2> /dev/null |grep "Found ")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER hdfs dfs -ls "/HiBench/$full_name/Input" 2>&1 |tee -a $LOG_PATH
        DELETE_HDFS=1
        format_nodes
      fi
    fi

    echo "# $(date +"%H:%M:%S") STARTING $bench" 2>&1 |tee -a $LOG_PATH

      if [ "$DELETE_HDFS" == "1" ] ; then
        if [ "$bench" != "dfsioe" ] ; then
          execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare.sh "prep_"
        elif [ "$bench" == "dfsioe" ] ; then
          execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare-read.sh "prep_"
        fi
      else
        loggerb  "Reusing previous RUN prepared $bench"
      fi

    loggerb  "$(date +"%H:%M:%S") RUNNING $bench"

    if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then
      execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/run.sh
    elif [ "$bench" == "hivebench" ] ; then
      execute_hdi_hadoop hivebench_agregation ${BENCH_HIB_DIR}/hivebench/bin/run-aggregation.sh
      execute_hdi_hadoop hivebench_join ${BENCH_HIB_DIR}/hivebench/bin/run-join.sh
    elif [ "$bench" == "dfsioe" ] ; then
      execute_hdi_hadoop dfsioe_read ${BENCH_HIB_DIR}/dfsioe/bin/run-read.sh
      execute_hdi_hadoop dfsioe_write ${BENCH_HIB_DIR}/dfsioe/bin/run-write.sh
    fi

  done	
}

execute_hadoop(){
  #clear buffer cache exept for prepare
#  if [[ -z $3 ]] ; then
#    loggerb "Clearing Buffer cache"
#    $DSH "sudo /usr/local/sbin/drop_caches" 2>&1 |tee -a $LOG_PATH
#  fi

  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  loggerb "# EXECUTING ${3}${1}"

  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
    local hadoop_config="$BENCH_H_DIR/conf"
    local hadoop_examples_jar="$BENCH_H_DIR/hadoop-examples-*.jar"
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    local hadoop_config="$BENCH_H_DIR/etc/hadoop"
    local hadoop_examples_jar="$BENCH_H_DIR/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.0.jar"
  fi

  #need to send all the environment variables over SSH
  EXP="export JAVA_HOME=$JAVA_HOME && \
export HADOOP_PREFIX=$BENCH_H_DIR && \
export HADOOP_HOME=$BENCH_H_DIR && \
export HADOOP_EXECUTABLE=$BENCH_H_DIR/bin/hadoop && \
export HADOOP_CONF_DIR=$hadoop_config && \
export YARN_CONF_DIR=$hadoop_config && \
export HADOOP_EXAMPLES_JAR=$hadoop_examples_jar && \
export MAPRED_EXECUTABLE=$BENCH_H_DIR/bin/mapred && \
export HADOOP_VERSION=$HADOOP_VERSION && \
export HADOOP_COMMON_HOME=$HADOOP_HOME && \
export HADOOP_HDFS_HOME=$HADOOP_HOME && \
export HADOOP_MAPRED_HOME=$HADOOP_HOME && \
export HADOOP_YARN_HOME=$HADOOP_HOME && \
export COMPRESS_GLOBAL=$COMPRESS_GLOBAL && \
export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL && \
export COMPRESS_CODEC_MAP=$COMPRESS_CODEC_MAP && \
export NUM_MAPS=$NUM_MAPS && \
export NUM_REDS=$NUM_REDS && \
export DATASIZE=$DATASIZE && \
export PAGES=$PAGES && \
export CLASSES=$CLASSES && \
export NGRAMS=$NGRAMS && \
export RD_NUM_OF_FILES=$RD_NUM_OF_FILES && \
export RD_FILE_SIZE=$RD_FILE_SIZE && \
export WT_NUM_OF_FILES=$WT_NUM_OF_FILES && \
export WT_FILE_SIZE=$WT_FILE_SIZE && \
export NUM_OF_CLUSTERS=$NUM_OF_CLUSTERS && \
export NUM_OF_SAMPLES=$NUM_OF_SAMPLES && \
export SAMPLES_PER_INPUTFILE=$SAMPLES_PER_INPUTFILE && \
export DIMENSIONS=$DIMENSIONS && \
export MAX_ITERATION=$MAX_ITERATION && \
export NUM_ITERATIONS=$NUM_ITERATIONS
"
  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2" 2>&1 |tee -a $LOG_PATH

  local end_exec=`timestamp`

  loggerb "# DONE EXECUTING $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s." 2>&1 |tee -a $LOG_PATH
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."


  stop_monit

  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    loggerb "Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER $BENCH_H_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

  save_disk_usage "AFTER"

  #clean output data
  loggerb "INFO: Cleaning Output data for $bench"
  get_bench_name $bench
  if [ "$hadoop_version" == "hadoop1" ]; then
    $DSH_MASTER "$BENCH_H_DIR/bin/hadoop fs -rmr /HiBench/$full_name/Output"
  else
    $DSH_MASTER "$BENCH_H_DIR/bin/hdfs dfs -rm -r /HiBench/$full_name/Output"
  fi

  save_hadoop "${3}${1}"
}

execute_hdi_hadoop() {
  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  loggerb "# EXECUTING ${3}${1}"
  local HADOOP_EXECUTABLE=hadoop
  local HADOOP_EXAMPLES_JAR=/home/pristine/hadoop-mapreduce-examples.jar
  if [ "$defaultProvider" == "rackspacecbd" ]; then
    HADOOP_EXECUTABLE='sudo -u hdfs hadoop'
    HADOOP_EXAMPLES_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar
  fi

  #need to send all the environment variables over SSH
  EXP="export JAVA_HOME=$JAVA_HOME && \
export HADOOP_HOME=/usr/hdp/2.*/hadoop && \
export HADOOP_EXECUTABLE='$HADOOP_EXECUTABLE' && \
export HADOOP_CONF_DIR=/etc/hadoop/conf && \
export HADOOP_EXAMPLES_JAR='$HADOOP_EXAMPLES_JAR' && \
export MAPRED_EXECUTABLE=ONLY_IN_HADOOP_2 && \
export HADOOP_VERSION=$HADOOP_VERSION && \
export COMPRESS_GLOBAL=$COMPRESS_GLOBAL && \
export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL && \
export COMPRESS_CODEC_MAP=$COMPRESS_CODEC_MAP && \
export NUM_MAPS=$NUM_MAPS && \
export NUM_REDS=$NUM_REDS && \
export DATASIZE=$DATASIZE && \
export PAGES=$PAGES && \
export CLASSES=$CLASSES && \
export NGRAMS=$NGRAMS && \
export RD_NUM_OF_FILES=$RD_NUM_OF_FILES && \
export RD_FILE_SIZE=$RD_FILE_SIZE && \
export WT_NUM_OF_FILES=$WT_NUM_OF_FILES && \
export WT_FILE_SIZE=$WT_FILE_SIZE && \
export NUM_OF_CLUSTERS=$NUM_OF_CLUSTERS && \
export NUM_OF_SAMPLES=$NUM_OF_SAMPLES && \
export SAMPLES_PER_INPUTFILE=$SAMPLES_PER_INPUTFILE && \
export DIMENSIONS=$DIMENSIONS && \
export MAX_ITERATION=$MAX_ITERATION && \
export NUM_ITERATIONS=$NUM_ITERATIONS && \
"

  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2" 2>&1 |tee -a $LOG_PATH

  local end_exec=`timestamp`

  loggerb "# DONE EXECUTING $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s." 2>&1 |tee -a $LOG_PATH
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."


  stop_monit

  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    loggerb "Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

  save_disk_usage "AFTER"

  #clean output data
  loggerb "INFO: Cleaning Output data for $bench"
  get_bench_name $bench
  $DSH_MASTER "$BENCH_H_DIR/bin/hadoop fs -rmr /HiBench/$full_name/Output"

  save_hadoop "${3}${1}"
}

save_hadoop() {
  loggerb "Saving benchmark $1"
  $DSH "mkdir -p $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  $DSH "cp -r ${BENCH_H_DIR}/logs/* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH

  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    if [ "$defaultProvider" == "rackspacecbd" ]; then
        sudo su hdfs -c "hdfs dfs -chmod -R 777 /mr-history"
        hdfs dfs -copyToLocal /mr-history $JOB_PATH/$1
        sudo su hdfs -c "hdfs dfs -rm -r /mr-history/*"
        sudo su hdfs -c "hdfs dfs -expunge"
    else
	    hdfs dfs -copyToLocal /mr-history $JOB_PATH/$1
	    hdfs dfs -rm -r /mr-history
	    hdfs dfs -expunge
    fi
  else
    $DSH "cp $BENCH_H_DIR/logs/job*.xml $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  fi

  # Hadoop 2 saves job history to HDFS, get it from there and then delete
  if [[ "$HADOOP_VERSION" == "hadoop2" && "$clusterType=" != "PaaS" ]]; then
    $BENCH_H_DIR/bin/hdfs dfs -copyToLocal /tmp/hadoop-yarn/staging/history $JOB_PATH/$1 2>&1 |tee -a $LOG_PATH
    loggerb "Deleting history files after copy to local"
    $BENCH_H_DIR/bin/hdfs dfs -rm -r /tmp/hadoop-yarn/staging/history 2>&1 |tee -a $LOG_PATH
  fi

  if [[ "EXECUTE_HIBENCH" == "true" ]]; then
    #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
    cp "${BENCH_HIB_DIR}/$bench/hibench.report" "$JOB_PATH/$1/"
  fi

  #loggerb "Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH" 2>&1 |tee -a $LOG_PATH
  #pending, delete

  # Save sysstat data for instrumentation
  if [ "$INSTRUMENTATION" == "1" ] ; then
    $DSH "mkdir -p $JOB_PATH/traces" 2>&1 |tee -a $LOG_PATH
    $DSH "cp $JOB_PATH/$1/sar*.sar $JOB_PATH/traces/" 2>&1 |tee -a $LOG_PATH
  fi

  loggerb "Compresing and deleting $1"

  $DSH_MASTER "cd $JOB_PATH; tar -cjf $JOB_PATH/$1.tar.bz2 $1;" 2>&1 |tee -a $LOG_PATH
  tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  $DSH_MASTER "rm -rf $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #$JOB_PATH/conf_* #TODO check

  #empy the contents from original disk  TODO check if still necessary
  $DSH "for i in $HDD/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH

  loggerb "Done saving benchmark $1"
}

instrumentation_post_process() {

  stop_sniffer

  # Emulate vars.sh from instrumentation project setting the required environment variables
  local EXTRAE_DIR="${HDD}/traces"
  local BIN_DIR="${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/bin"
  local LIB_DIR="${BENCH_DEFAULT_SCRATCH}/aplic/instrumentation/lib"
  local JAVA="${JAVA_HOME}/bin/java"
  # Has to be an export because Undef2prv has to read it
  export TRACES_OUTPUT="${JOB_PATH}/traces"

  echo "##################################################"
  echo "### POST PROCESS DUMPINGD ########################"
  echo "##################################################"

  #dumping: filtrado del volcado del lsof
  while read node
  do
  ssh $node <<ENDSSH
  cp $EXTRAE_DIR/dumping-host-port-pid $EXTRAE_DIR/dumping-host-port-pid.unfiltered
  cat $EXTRAE_DIR/dumping-host-port-pid.unfiltered | grep -v COMMAND | grep -v LISTEN | grep java | tr -s ' ' | sed -e 's/:/ /g' | sed -e 's/->/ /g' | cut -d ' ' -f 2,9,10 | sed -e 's/ /:/g' >> $EXTRAE_DIR/dumping-host-port-pid.filtered
  cat $EXTRAE_DIR/dumping-host-port-pid.unfiltered | grep -v COMMAND | grep LISTEN | grep java | tr -s ' ' | sed -e 's/:/ /g' | sed -e 's/->/ /g' | cut -d ' ' -f 2,9,10 | sed -e 's/ /:/g'  >> $EXTRAE_DIR/dumping-host-port-pid.filtered
  cp $EXTRAE_DIR/dumping-host-port-pid.filtered $EXTRAE_DIR/dumping-host-port-pid_unsorted
  sort -k1,3 -u  $EXTRAE_DIR/dumping-host-port-pid_unsorted   > $EXTRAE_DIR/dumping-host-port-pid_sorted
  cat $EXTRAE_DIR/dumping-host-port-pid_sorted | eval sed 's/[^:]*/\$(hostname --ip-address)/'2 > $EXTRAE_DIR/dumping-host-port-pid.lsof
ENDSSH
  done <<< "$node_names"

  #get dumping-host-port-pid from hadoop nodes
  mkdir -p $TRACES_OUTPUT/distributed-merge
  while read node
  do
  scp $node:$EXTRAE_DIR/dumping-host-port-pid.lsof $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid_$node.lsof
  done <<< "$node_names"

  #merge all nodes dumping-host-port-pid into a unique
  rm -f $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid
  for f in `ls -d $TRACES_OUTPUT/distributed-merge/* | grep dumping-host-port-pid_`
  do
  cat $f >> $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid
  done



  echo "##################################################"
  echo "### POST PROCESS EXTRAE TRACES ###################"
  echo "##################################################"

  #get extrae traces from hadoop nodes
  rm -f $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  while read node
  do
  rm -rf $TRACES_OUTPUT/distributed-merge/$node
  mkdir -p $TRACES_OUTPUT/distributed-merge/$node
  scp -r $node:$EXTRAE_DIR/set-* $TRACES_OUTPUT/distributed-merge/$node
  scp -r $node:$EXTRAE_DIR/TRACE.mpits $TRACES_OUTPUT/distributed-merge/$node
  for f in $TRACES_OUTPUT/distributed-merge/$node/set-*/*mpit
  do
  echo $f on minerva-$node named>> $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  echo "--" >> $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  done
  done <<< "$node_names"

  #quito el ultimo -- para que mpi2prv no me de error
  cp $TRACES_OUTPUT/distributed-merge/TRACE.mpits $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp
  head -n -1 $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp > $TRACES_OUTPUT/distributed-merge/TRACE.mpits
  rm $TRACES_OUTPUT/distributed-merge/TRACE.mpits.tmp

  #Generacion de todos los mpits con el TRACE.mpits separados por apps
  ${BIN_DIR}/mpi2prv -no-syn -f $TRACES_OUTPUT/distributed-merge/TRACE.mpits -o $TRACES_OUTPUT/mergeoutput.prv



  echo "##################################################"
  echo "### POST PROCESS SYSSTAT #########################"
  echo "##################################################"

  rm -f $TRACES_OUTPUT/sar*.txt
  rm -f $TRACES_OUTPUT/sysstat*.txt
  while read node
  do

  sadf_version=$(echo `sadf -V` | cut --delimiter=' ' --fields=3)
  sadf_version=( ${sadf_version//./ } )
  # if version is 10.1.1 or newer
  if (( ${sadf_version[0]} >= "10" )) && (( ${sadf_version[1]} >= "1" )) ; then
    sadf -d -h -U $TRACES_OUTPUT/sar-$node.sar -- -u -B -r -q > $TRACES_OUTPUT/sar-$node.txt
  else
    sadf -d -h -T $TRACES_OUTPUT/sar-$node.sar -- -u -B -r -q > $TRACES_OUTPUT/sar-$node.txt
  fi

  sed -i '1d' $TRACES_OUTPUT/sar-$node.txt
  ip=$(ssh -n $node "hostname --ip-address")
  awk -v "IP=$ip" '{$1=IP}1' FS=';' OFS=';' $TRACES_OUTPUT/sar-$node.txt >> $TRACES_OUTPUT/sar.txt
  done <<< "$node_names"



  echo "##################################################"
  echo "### POST PROCESS UNDEF2PRV #######################"
  echo "##################################################"

  #clean log files
  rm -f $TRACES_OUTPUT/undef2prv.log*

  #execute the undef2prv post-processing
  #procesa els ports i els genera al output
  ${JAVA} -Xmx1536m -cp "${LIB_DIR}/*" es.bsc.tools.undef2prv.Undef2prv $TRACES_OUTPUT/distributed-merge/dumping-host-port-pid $TRACES_OUTPUT/mergeoutput.prv $TRACES_OUTPUT/mergeoutput.row $TRACES_OUTPUT/mergeoutput.pcf $TRACES_OUTPUT/sar.txt

}

stop_sniffer(){
  $DSH_C "killall sniffer" 2> /dev/null |tee -a $LOG_PATH
}

execute_TPCH(){
  restart_hadoop

  ##putting hadoop binaries to path

  if [ "$DELETE_HDFS" == "1" ]; then
    generate_TPCH_data "prep_tpch" "$TPCH_SCALE_FACTOR"
  else
    loggerb  "Reusing previous RUN TPCH data"
  fi

  if [ "$LIST_BENCHS" == "all" ]; then
     LIST_BENCHS=""
     for number in $(seq 1 22) ; do
        LIST_BENCHS="${LIST_BENCHS} query${number}"
     done
  fi

  for query in $(echo "$LIST_BENCHS") ; do
    # Check if there is a custom config for this bench, and call it
    if type "benchmark_TPCH_config_${query}" &>/dev/null
    then
      eval "benchmark_TPCH_config_${query}"
    fi

    #deleting old history files
    loggerb "delete old history files"
    $DSH_MASTER $BENCH_H_DIR/bin/hdfs dfs -rm -r "/tmp/hadoop-yarn/history" 2> /dev/null

    echo "# $(date +"%H:%M:%S") STARTING $query" 2>&1 |tee -a $LOG_PATH

    loggerb  "$(date +"%H:%M:%S") RUNNING QUERY $query"

    execute_TPCH_query "$query"

  done
}

# $2 scale factor
generate_TPCH_data() {
  EXP=$(get_hive_env)
  DATA_GENERATOR="${TPCH_HOME}/tpch-setup.sh $2 $TPCH_DATA_DIR"

  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  loggerb "# GENERATING TPCH DATA WITH SCALE FACTOR ${2}"
  loggerb "COMMAND: $EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' $DATA_GENERATOR"

  $DSH_MASTER "$EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' bash $DATA_GENERATOR" 2>&1 | tee -a $LOG_PATH

  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    loggerb "DATA GENERATOR NOT BUILD, TRYING TO BUILD IT"

     $DSH_MASTER "$EXP cd ${TPCH_HOME}; bash tpch-build.sh" 2>&1 | tee -a $LOG_PATH
     if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      loggerb "ERROR WHEN BUILDING DATA GENERATOR FOR TCPH, exiting..."
      exit 1;
     fi

    loggerb "RETRYING TO GENERATE DATA WITH SCALE FACTOR ${2}"
    $DSH_MASTER "$EXP cd $TPCH_HOME && /usr/bin/time -f 'Time data generator %e' bash $DATA_GENERATOR" 2>&1 | tee -a $LOG_PATH
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      loggerb "ERROR: GENERATING DATA FAILED FOR A SECOND TIME, exiting..."
      exit 1
    fi
  fi

  #save the data
  if [ "$SAVE_BENCH" == "1" ] ; then
    loggerb "Saving TPCH_DATA to: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER $BENCH_H_DIR/bin/hdfs dfs -get -ignoreCrc $TPCH_DATA_DIR $BENCH_SAVE_PREPARE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

  local end_exec=`timestamp`

  loggerb "# DONE GENERATING TPCH DATA"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  stop_monit

  save_disk_usage "AFTER"

  bench_name="$1"
  save_hadoop "${bench_name}"
}

# $1 table name
execute_TPCH_query() {

  TABLE_NAME="tpch_bin_flat_orc_${TPCH_SCALE_FACTOR}"
  if [ ! -z $2 ]; then
    TABLE_NAME="$2"
  fi

  query=$1
  save_disk_usage "BEFORE"
  restart_monit

  EXP=$(get_hive_env)
  PREFIX="${TPCH_HOME}/sample-queries-tpch"
  SETTINGS="${PREFIX}/${TPCH_SETTINGS_FILE_NAME}"
  COMMAND="hive -i $SETTINGS -f ${PREFIX}/tpch_${1}.sql --database ${TABLE_NAME}"

  loggerb "COMMAND: $COMMAND\nSETTINGS FILE: $SETTINGS"

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  loggerb "# EXECUTING TPCH $query"

  $DSH_MASTER "$EXP cd ${TPCH_HOME} && /usr/bin/time -f 'Time ${3}${1} %e' $COMMAND" 2>&1 |tee -a $LOG_PATH

  local end_exec=`timestamp`

  loggerb "# DONE TPCH $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  stop_monit
  save_disk_usage "AFTER"

  save_hadoop "tpch-${query}"
}
