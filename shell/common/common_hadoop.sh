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

prepare_hadoop_config(){

  #before running hibench, set exports and vars
  EXP="export JAVA_HOME=$JAVA_HOME && \
export HADOOP_HOME=$BENCH_H_DIR && \
export COMPRESS_GLOBAL=$COMPRESS_GLOBAL && \
export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL && \
export NUM_MAPS=$MAX_MAPS && \
export NUM_REDS=$MAX_MAPS && \
"

  loggerb "Preparing exe dir"



  if [ "$DELETE_HDFS" == "1" ] ; then
     loggerb "Deleting previous PORT files"
     $DSH "rm -rf $HDD/*" 2>&1 |tee -a $LOG_PATH
$DSH "rm -rf $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/*" 2>&1 |tee -a $LOG_PATH
  else
     $DSH "rm -rf $HDD/{aplic,logs}" 2>&1 |tee -a $LOG_PATH
  fi

  loggerb "Creating source dir and Copying Hadoop"
$DSH "mkdir -p $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/{aplic,hadoop,logs}" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $HDD/{aplic,hadoop,logs}" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $BENCH_H_DIR" 2>&1 |tee -a $LOG_PATH

  $DSH "cp -ru $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}/* $BENCH_H_DIR/" 2>&1 |tee -a $LOG_PATH

  $DSH "cp /usr/bin/vmstat $vmstat" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $bwm_source $bwm" 2>&1 |tee -a $LOG_PATH
  $DSH "cp /usr/bin/sar $sar" 2>&1 |tee -a $LOG_PATH

  loggerb "Preparing config"

  $DSH "rm -rf $BENCH_H_DIR/conf/*" 2>&1 |tee -a $LOG_PATH

  MASTER="$master_name"

  IO_MB="$((IO_FACTOR * 10))"



if [ "$DISK" == "SSD" ] || [ "$DISK" == "HDD" ] ; then
  HDFS_NDIR="$HDD/dfs/name"
  HDFS_DDIR="$HDD/dfs/data"
elif [ "$DISK" == "RL1" ] || [ "$DISK" == "RR1" ]; then
  HDFS_NDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/name"
  HDFS_DDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/data"
elif [ "$DISK" == "RL2" ] || [ "$DISK" == "RR2" ]; then
  HDFS_NDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/name\,/scratch/attached/2/hadoop-hibench_$PORT_PREFIX/dfs/name"
  HDFS_DDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/data\,/scratch/attached/2/hadoop-hibench_$PORT_PREFIX/dfs/data"
elif [ "$DISK" == "RL3" ] || [ "$DISK" == "RR3" ]; then
  HDFS_NDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/name\,/scratch/attached/2/hadoop-hibench_$PORT_PREFIX/dfs/name\,/scratch/attached/3/hadoop-hibench_$PORT_PREFIX/dfs/name"
  HDFS_DDIR="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX/dfs/data\,/scratch/attached/2/hadoop-hibench_$PORT_PREFIX/dfs/data\,/scratch/attached/3/hadoop-hibench_$PORT_PREFIX/dfs/data"
else
  echo "Incorrect disk specified2: $DISK"
  exit 1
fi

logger "DEBUG: HDFS_NDIR: $HDFS_NDIR \nHDFS_DDIR: $HDFS_DDIR"

MAX_REDS="$MAX_MAPS"

subs=$(cat <<EOF
s,##JAVA_HOME##,$JAVA_HOME,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##LOG_DIR##,$HDD/logs,g;
s,##REPLICATION##,$REPLICATION,g;
s,##MASTER##,$MASTER,g;
s,##NAMENODE##,$MASTER,g;
s,##TMP_DIR##,$HDD,g;
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
EOF
)

slaves="$(get_slaves_names)"


  #to avoid perl warnings
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  $DSH "cp $BENCH_H_DIR/conf_template/* $BENCH_H_DIR/conf/" 2>&1 |tee -a $LOG_PATH

  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/hadoop-env.sh > $BENCH_H_DIR/conf/hadoop-env.sh" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/core-site.xml > $BENCH_H_DIR/conf/core-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/hdfs-site.xml > $BENCH_H_DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $BENCH_H_DIR/conf_template/mapred-site.xml > $BENCH_H_DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH

  loggerb "Replacing per host config"

  for node in $node_names ; do
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $BENCH_H_DIR/conf/mapred-site.xml > $BENCH_H_DIR/conf/mapred-site.xml.tmp; rm $BENCH_H_DIR/conf/mapred-site.xml; mv $BENCH_H_DIR/conf/mapred-site.xml.tmp $BENCH_H_DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH &
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $BENCH_H_DIR/conf/hdfs-site.xml > $BENCH_H_DIR/conf/hdfs-site.xml.tmp; rm $BENCH_H_DIR/conf/hdfs-site.xml; mv $BENCH_H_DIR/conf/hdfs-site.xml.tmp $BENCH_H_DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH &
  done

  $DSH "echo -e \"$MASTER\" > $BENCH_H_DIR/conf/masters" 2>&1 |tee -a $LOG_PATH
  $DSH "echo -e \"$slaves\" > $BENCH_H_DIR/conf/slaves" 2>&1 |tee -a $LOG_PATH


  #save config
  loggerb "Saving config"
  create_conf_dirs=""
  for node in $node_names ; do
    create_conf_dirs="$create_conf_dirs mkdir -p $JOB_PATH/conf_$node ;"
  done

  $DSH "$create_conf_dirs" 2>&1 |tee -a $LOG_PATH

  for node in $node_names ; do
    ssh "$node" "cp $BENCH_H_DIR/conf/* $JOB_PATH/conf_$node" 2>&1 |tee -a $LOG_PATH &
  done
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
  $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH

  #delete previous run logs
  $DSH "rm -rf $HDD/logs; mkdir -p $HDD/logs" 2>&1 |tee -a $LOG_PATH

  if [ "$DELETE_HDFS" == "1" ] ; then
    loggerb "Deleting previous Hadoop HDFS"
#$DSH "rm -rf $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/*" 2>&1 |tee -a $LOG_PATH
#$DSH "mkdir -p $BENCH_DEFAULT_SCRATCH/scratch/attached/{1,2,3}/hadoop-hibench_$PORT_PREFIX/" 2>&1 |tee -a $LOG_PATH
    $DSH "rm -rf $HDD/{dfs,mapred,logs}; mkdir -p $HDD/logs" 2>&1 |tee -a $LOG_PATH
    #send multiple yes to format
    $DSH_MASTER "yes Y | $BENCH_H_DIR/bin/hadoop namenode -format" 2>&1 |tee -a $LOG_PATH
    $DSH_MASTER "yes Y | $BENCH_H_DIR/bin/hadoop datanode -format" 2>&1 |tee -a $LOG_PATH
  fi

  $DSH_MASTER $BENCH_H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH

  for i in {0..300} #3mins
  do
    local report=$($DSH_MASTER $BENCH_H_DIR/bin/hadoop dfsadmin -report 2> /dev/null)
    local num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
    local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    echo $report 2>&1 |tee -a $LOG_PATH

    if [ "$num" == "$NUMBER_OF_SLAVES" ] ; then
      if [[ -z $safe_mode ]] ; then
        #everything fine continue
        break
      elif [ "$i" == "30" ] ; then
        loggerb "Still in Safe mode, MANUALLY RESETTING SAFE MODE wating for $i seconds"
        $DSH_MASTER $BENCH_H_DIR/bin/hadoop dfsadmin -safemode leave 2>&1 |tee -a $LOG_PATH
      else
        loggerb "Still in Safe mode, wating for $i seconds"
      fi
    elif [ "$i" == "60" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
      $DSH_MASTER $BENCH_H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH
    elif [ "$i" == "180" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      loggerb "Reseting config to retry DELETE_HDFS WAS SET TO: $DELETE_HDFS"
      DELETE_HDFS="1"
      restart_hadoop no_retry
    elif [ "$i" == "120" ] ; then
      loggerb "$num/$NUMBER_OF_SLAVES Datanodes available, EXIT"
      exit 1
    else
      loggerb "$num/$NUMBER_OF_SLAVES Datanodes available, wating for $i seconds"
      sleep 1
    fi
  done

  set_omm_killer

  loggerb "Hadoop ready"
}

stop_hadoop(){
  loggerb "Stop Hadoop"
  $DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
  loggerb "Stop Hadoop ready"
}

execute_HiBench(){
  for bench in $(echo "$LIST_BENCHS") ; do
    restart_hadoop

    #Delete previous data
    #$DSH_MASTER "$BENCH_H_DIR/bin/hadoop fs -rmr /HiBench" 2>&1 |tee -a $LOG_PATH
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

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
          execute_hadoop $bench ${BENCH_HIB_DIR}$bench/bin/prepare.sh "prep_"
        elif [ "$bench" == "dfsioe" ] ; then
          execute_hadoop $bench ${BENCH_HIB_DIR}$bench/bin/prepare-read.sh "prep_"
        fi
      else
        loggerb  "Reusing previous RUN prepared $bench"
      fi


      #if [ "$bench" = "wordcounta" ] ; then
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
      execute_hadoop $bench ${BENCH_HIB_DIR}$bench/bin/run.sh
    elif [ "$bench" == "hivebench" ] ; then
      execute_hadoop hivebench_agregation ${BENCH_HIB_DIR}hivebench/bin/run-aggregation.sh
      execute_hadoop hivebench_join ${BENCH_HIB_DIR}hivebench/bin/run-join.sh
    elif [ "$bench" == "dfsioe" ] ; then
      execute_hadoop dfsioe_read ${BENCH_HIB_DIR}dfsioe/bin/run-read.sh
      execute_hadoop dfsioe_write ${BENCH_HIB_DIR}dfsioe/bin/run-write.sh
    fi

  done
}


execute_hadoop(){
  #clear buffer cache exept for prepare
#  if [[ -z $3 ]] ; then
#    loggerb "Clearing Buffer cache"
#    $DSH "sudo /usr/local/sbin/drop_caches" 2>&1 |tee -a $LOG_PATH
#  fi

  loggerb "# Checking disk space with df BEFORE"
  $DSH "df -h" 2>&1 |tee -a $LOG_PATH
  loggerb "# Checking hadoop folder space BEFORE"
  $DSH "du -sh $HDD/*" 2>&1 |tee -a $LOG_PATH

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=$(date '+%s')  && echo "start $start_exec end $end_exec" 2>&1 |tee -a $LOG_PATH
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S') && echo "end $start_date" 2>&1 |tee -a $LOG_PATH
  loggerb "# EXECUTING ${3}${1}"

  $DSH_SLAVE "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2" 2>&1 |tee -a $LOG_PATH

  local end_exec=$(date '+%s') && echo "start $start_exec end $end_exec" 2>&1 |tee -a $LOG_PATH

  loggerb "# DONE EXECUTING $1"

  local total_secs=$(expr $end_exec - $start_exec) &&  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s." 2>&1 |tee -a $LOG_PATH
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."


  stop_monit

  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    loggerb "Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER $BENCH_H_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

loggerb "# Checking disk space with df AFTER"
$DSH "df -h" 2>&1 |tee -a $LOG_PATH
loggerb "# Checking hadoop folder space AFTER"
$DSH "du -sh $HDD/*" 2>&1 |tee -a $LOG_PATH

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
  $DSH "cp -r $HDD/logs/* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $HDD/logs/job*.xml $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  cp "${BENCH_HIB_DIR}$bench/hibench.report" "$JOB_PATH/$1/"

  #loggerb "Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH" 2>&1 |tee -a $LOG_PATH
  #pending, delete

  loggerb "Compresing and deleting $1"

  $DSH_MASTER "cd $JOB_PATH; tar -cjf $JOB_PATH/$1.tar.bz2 $1;" 2>&1 |tee -a $LOG_PATH
  tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  $DSH_MASTER "rm -rf $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #$JOB_PATH/conf_* #TODO check

  #empy the contents from original disk  TODO check if still necessary
  $DSH "for i in $HDD/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH

  loggerb "Done saving benchmark $1"
}




