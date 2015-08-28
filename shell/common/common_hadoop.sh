#HADOOP SPECIFIC FUNCTIONS

get_hadoop_config_folder() {
  echo "hadoop1_conf_template"
}

set_hadoop_config_folder() {
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS
$(get_hadoop_config_folder)"
}

# Sets the required files to download/copy
set_hadoop_requires() {
  BENCH_REQUIRED_FILES["$BENCH_HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$BENCH_HADOOP_VERSION/$BENCH_HADOOP_VERSION-bin.tar.gz"
  #also set the config here
  set_hadoop_config_folder
}

# Helper to print a line with Hadoop requiered exports
get_hadoop_exports() {
  local to_export

#export HADOOP_HOME='$(get_local_apps_path)/${BENCH_HADOOP_VERSION}';
#$(get_java_exports)

  to_export="
export HADOOP_CONF_DIR='$HDD/conf';
"

  if [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    export="$to_export
export HADOOP_YARN_HOME='$HADOOP_HOME';
"
  fi

  echo -e "$to_export"
}

# Sets a coma separeted list of disks for the hadoop conf file
#1 disk type $2 postfix $3 port prefix
get_hadoop_conf_dir() {
  local dir

  local disks="$(get_specified_disks "$1")"
  for disk_tmp in $disks ; do
    dir="$dir\,$disk_tmp/$(get_aloja_dir "$3")/$2"
  done

  if [ "$dir" ] ; then
    dir="${dir:2}" #remove leading \,
    echo -e "$dir"
  else
    die "Cannot get disk config for specified disk $1"
  fi
}


#old code moved here
# TODO cleanup
initialize_hadoop_vars() {

  [ ! "$HDD" ] && die "HDD var not set!"

  BENCH_H_DIR="$(get_local_apps_path)/$BENCH_HADOOP_VERSION" #execution dir

  HADOOP_CONF_DIR="$HDD/conf"
  HADOOP_EXPORTS="$(get_hadoop_exports)"

  if [ "$clusterType" == "PaaS" ]; then
    HADOOP_VERSION="hadoop2"
  fi

#  if [ ! "$BENCH_HADOOP_VERSION" ] ; then
#    if [ "$HADOOP_VERSION" == "hadoop1" ]; then
#      BENCH_HADOOP_VERSION="hadoop-1.0.3"
#    elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
#      BENCH_HADOOP_VERSION="hadoop-2.6.0"
#    fi
#  fi

  # Use instrumented version of Hadoop
  if [ "$INSTRUMENTATION" == "1" ] ; then
    BENCH_HADOOP_VERSION="${BENCH_HADOOP_VERSION}-instr"
  fi

  #make sure all spawned background jobs and services are stoped or killed when done
  if [ "$INSTRUMENTATION" == "1" ] ; then
    update_traps "stop_hadoop; stop_monit; stop_sniffer;" "update_logger"
  else
    update_traps "stop_hadoop; stop_monit;" "update_logger"
  fi


logger "updated traps"
die "harder"
sleep 100


#logger "INFO: DEBUG: userAloja=$userAloja
#DEBUG: BENCH_BASE_DIR=$BENCH_BASE_DIR
#BENCH_DEFAULT_SCRATCH=$BENCH_DEFAULT_SCRATCH
#BENCH_SOURCE_DIR=$BENCH_SOURCE_DIR
#BENCH_SAVE_PREPARE_LOCATION=$BENCH_SAVE_PREPARE_LOCATION
#BENCH_HADOOP_VERSION=$BENCH_HADOOP_VERSION
#DEBUG: JAVA_HOME=$JAVA_HOME
#JAVA_XMS=$JAVA_XMS JAVA_XMX=$JAVA_XMX
#PHYS_MEM=$PHYS_MEM
#NUM_CORES=$NUM_CORES
#CONTAINER_MIN_MB=$CONTAINER_MIN_MB
#CONTAINER_MAX_MB=$CONTAINER_MAX_MB
#MAPS_MB=$MAPS_MB
#AM_MB=$AM_MB
#JAVA_AM_XMS=$JAVA_AM_XMS
#JAVA_AM_XMX=$JAVA_AM_XMX
#REDUCES_MB=$REDUCES_MB
#Master node: $master_name "

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

  logger "INFO: Copying Hive and Hive-testbench dirs"
  $DSH "cp -ru $BENCH_SOURCE_DIR/apache-hive-1.2.0-bin $HIVE_B_DIR/"

  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-env.sh.template > $HIVE_HOME/conf/hive-env.sh"
  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-default.xml.template > $HIVE_HOME/conf/hive-default.xml"
  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-log4j.properties.template > $HIVE_HOME/conf/hive-log4j.properties"
  $DSH "/usr/bin/perl -pe \"$subs\" $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME.template > $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME"
}

# Sets the substitution values for the hadoop config
get_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  IO_MB="$((IO_FACTOR * 10))"
  MAX_REDS="$MAX_MAPS"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_H_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/logs,g;
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
s,##AM_MB##,$REDUCES_MB,g;
s,##BENCH_DEFAULT_SCRATCH##,$BENCH_DEFAULT_SCRATCH,g;
s,##HDD##,$HDD,g;
EOF
}

prepare_hadoop_config(){

  logger "INFO: Preparing Hadoop run specific config"
  $DSH "mkdir -p '$HDD/conf'; cp -r $(get_local_configs_path)/$(get_hadoop_config_folder)/* '$HDD/conf';"

  # To avoid perl warnings
  local export_perl="
export LC_CTYPE=en_US.UTF-8;
export LC_ALL=en_US.UTF-8;
"

  # Get the values
  subs=$(get_substitutions)
  slaves="$(get_slaves_names)"

  $DSH "
$export_perl
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/hadoop-env.sh;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/core-site.xml;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/hdfs-site.xml;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/mapred-site.xml
echo -e '$master_name' > $HADOOP_CONF_DIR/masters;
echo -e \"$slaves\" > $HADOOP_CONF_DIR/slaves;"


  if [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    $DSH "
$export_perl
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/yarn-site.xml;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/yarn-env.sh;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/mapred-env.sh"
  fi

  # TODO this part need to be improved, it needs the node for multiple hostnames in a machine (eg. when IB)
  logger "INFO: Replacing per host config"
  for node in $node_names ; do
    ssh "$node" "
$export_perl
/usr/bin/perl -i -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/mapred-site.xml
/usr/bin/perl -i -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/hdfs-site.xml" &
    if [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      ssh "$node" "$export_perl /usr/bin/perl -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/yarn-site.xml " &
    fi
  done

  # Save config
  logger "INFO: Saving bench spefic config to job folder"
  for node in $node_names ; do
    ssh "$node" "
mkdir -p $JOB_PATH/conf_$node;
cp $HADOOP_CONF_DIR/* $JOB_PATH/conf_$node/" &
  done

  [ "$DELETE_HDFS" == "1" ] && format_HDFS "$HADOOP_VERSION"

  # Set correct permissions for instrumentation's sniffer
  [ "$INSTRUMENTATION" == "1" ] && instrumentation_set_perms
}

# Formats the HDFS and NameNode for both Hadoop versions
# $1 $HADOOP_VERSION
format_HDFS(){
  local hadoop_version="$1"
  logger "INFO: Formating HDFS and NameNode"

  if [ "$hadoop_version" == "hadoop1" ]; then
    $DSH_MASTER "$HADOOP_EXPORTS yes Y | $BENCH_H_DIR/bin/hadoop namenode -format"
    $DSH_MASTER "$HADOOP_EXPORTS yes Y | $BENCH_H_DIR/bin/hadoop datanode -format"
  elif [ "$hadoop_version" == "hadoop2" ] ; then
    $DSH_MASTER "$HADOOP_EXPORTS yes Y | $BENCH_H_DIR/bin/hdfs namenode -format"
  else
    die "Incorrect Hadoop version. Supplied: $hadoop_version"
  fi
}

restart_hadoop(){
  logger "INFO: Restart Hadoop"
  #just in case stop all first
  if [ "$HADOOP_VERSION" == "hadoop2" ]; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-dfs.sh" 2>&1 >> $LOG_PATH
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-yarn.sh" 2>&1 >> $LOG_PATH
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver" 2>&1 >> $LOG_PATH
  else
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/stop-all.sh" 2>&1 >> $LOG_PATH
  fi

  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/start-all.sh"
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/start-dfs.sh"
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/start-yarn.sh"
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh start historyserver"
  fi

  for i in {0..300} #3mins
  do
    if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      local report=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop dfsadmin -report 2> /dev/null")
      local num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
      local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      local report=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfsadmin -report 2> /dev/null")
      local num=$(echo "$report" | grep "Live datanodes" | awk '{print $3}')
      num="${num:1:${#num}-3}"
      local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    fi
    echo $report

    if [ "$num" == "$NUMBER_OF_DATA_NODES" ] ; then
      if [[ -z $safe_mode ]] ; then
        #everything fine continue
        break
      elif [ "$i" == "30" ] ; then
        logger "INFO: Still in Safe mode, MANUALLY RESETTING SAFE MODE wating for $i seconds"
        if [ "$HADOOP_VERSION" == "hadoop1" ]; then
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop dfsadmin -safemode leave"
        elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfsadmin -safemode leave 2>&1" |tee -a $LOG_PATH
        fi
      else
        logger "INFO: Still in Safe mode, wating for $i seconds"
      fi
    elif [ "$i" == "60" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      if [ "$HADOOP_VERSION" == "hadoop2" ]; then
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-dfs.sh" 2>&1 >> $LOG_PATH
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-yarn.sh" 2>&1 >> $LOG_PATH
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/start-dfs.sh"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/start-yarn.sh"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh start historyserver"
      else
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/stop-all.sh" 2>&1 >> $LOG_PATH
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/start-all.sh"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver"
      fi

    elif [ "$i" == "180" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      logger "INFO: Reseting config to retry DELETE_HDFS WAS SET TO: $DELETE_HDFS"
      DELETE_HDFS="1"
      restart_hadoop no_retry
    elif [ "$i" == "120" ] ; then
      logger "INFO: $num/$NUMBER_OF_DATA_NODES Datanodes available, EXIT"
      exit 1
    else
      logger "INFO: $num/$NUMBER_OF_DATA_NODES Datanodes available, wating for $i seconds"
      sleep 1
    fi
  done

  set_omm_killer

  logger "INFO: Hadoop ready"
}

stop_hadoop(){
 if [ "$clusterType=" != "PaaS" ]; then
  logger "INFO: Stop Hadoop"
  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/stop-all.sh"
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-yarn.sh"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/stop-dfs.sh"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver"
  fi
  logger "INFO: Stop Hadoop ready"
 fi
}

# Performs the actual benchmark execution
# TODO old code needs cleanup
# $1 benchmark name
# $2 command
# $3 if prepare (optional)
execute_hadoop(){

  #clear buffer cache exept for prepare
#  if [[ -z $3 ]] ; then
#    logger "INFO: Clearing Buffer cache"
#    $DSH "sudo /usr/local/sbin/drop_caches"
#  fi

  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec="$(timestamp)"
  local start_date="$(date --date='+1 hour' '+%Y%m%d%H%M%S')"
  logger "INFO: RUNNING ${3}${1}"

  if [ "$HADOOP_VERSION" == "hadoop1" ]; then
    local hadoop_config="$HADOOP_CONF_DIR"
    local hadoop_examples_jar="$BENCH_H_DIR/hadoop-examples-*.jar"
  elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
    local hadoop_config="$BENCH_H_DIR/etc/hadoop"
    local hadoop_examples_jar="$BENCH_H_DIR/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar"
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
die "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2"
  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2"

  local end_exec=`timestamp`

  logger "INFO: DONE RUNNING $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs"

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  #url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  #echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."
  #zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."

  stop_monit

  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    logger "INFO: Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION"
  fi

  save_disk_usage "AFTER"

  #clean output data
  logger "INFO: Cleaning output data for $bench"

  if [ "$$HADOOP_VERSION" == "hadoop1" ]; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop fs -rmr /HiBench/$(get_bench_name)/Output"
  else
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfs -rm -r /HiBench/$(get_bench_name)/Output"

  fi

  save_hadoop "${3}${1}"
}

execute_hdi_hadoop() {
  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  logger "INFO: # EXECUTING ${3}${1}"
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

  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2"

  local end_exec=`timestamp`

  logger "INFO: # DONE EXECUTING $1"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs"

  # Save execution information in an array to allow import later
  
  EXEC_TIME[${3}${1}]="$total_secs"
  EXEC_START[${3}${1}]="$start_exec"
  EXEC_END[${3}${1}]="$end_exec"

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."


  stop_monit

  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    logger "INFO: Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION
  fi

  save_disk_usage "AFTER"

  #TODO should move to cleanup function
  #clean output data
  logger "INFO: Cleaning output data for $bench"
  $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop fs -rmr /HiBench/$(get_bench_name)/Output"

  save_hadoop "${3}${1}"
}

save_hadoop() {
  logger "INFO: Saving benchmark $1"
  $DSH "mkdir -p $JOB_PATH/$1"
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $JOB_PATH/$1/ 2> /dev/null" |tee -a $LOG_PATH
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$1/"
  #$DSH "cp -r ${BENCH_H_DIR}/logs/* $JOB_PATH/$1/ 2> /dev/null" |tee -a $LOG_PATH

  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    if [ "$defaultProvider" == "rackspacecbd" ]; then
        sudo su hdfs -c "hdfs dfs -chmod -R 777 /mr-history"
        hdfs dfs -copyToLocal "/mr-history" "$JOB_PATH/$1"
        sudo su hdfs -c "hdfs dfs -rm -r /mr-history/*"
        sudo su hdfs -c "hdfs dfs -expunge"
    else
	    hdfs dfs -copyToLocal "/mr-history" "$JOB_PATH/$1"
	    hdfs dfs -rm -r "/mr-history"
	    hdfs dfs -expunge
    fi
  else
    $DSH "cp $HDD/logs/job*.xml $JOB_PATH/$1/"
  fi

  # Hadoop 2 saves job history to HDFS, get it from there and then delete
  if [[ "$HADOOP_VERSION" == "hadoop2" && "$clusterType=" != "PaaS" ]]; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfs -copyToLocal /tmp/hadoop-yarn/staging/history $JOB_PATH/$1"
    logger "INFO: Deleting history files after copy to local"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hdfs dfs -rm -r /tmp/hadoop-yarn/staging/history"
  fi

  if [[ "EXECUTE_HIBENCH" == "true" ]]; then
    #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1"
    $DSH_MASTER  "$BENCH_HIB_DIR/$bench/hibench.report" "$JOB_PATH/$1/"
  fi

  #logger "INFO: Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #pending, delete

  # Save sysstat data for instrumentation
  if [ "$INSTRUMENTATION" == "1" ] ; then
    $DSH "mkdir -p $JOB_PATH/traces"
    $DSH "cp $JOB_PATH/$1/sar*.sar $JOB_PATH/traces/"
  fi

  logger "INFO: Compresing and deleting $1"

  $DSH_MASTER "
cd $JOB_PATH;
tar -cjf $JOB_PATH/$1.tar.bz2 $1;
rm -rf $JOB_PATH/$1;
if [ \"\$(ls conf_* 2> /dev/null)\" ] ; then
  tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  rm -rf
fi
"

  logger "INFO: Done saving benchmark $1"
}