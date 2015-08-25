# Helper functions for running benchmarks

# prints usage and exits
usage() {

  # Colorize when interactive
  if [ -t 1 ] ; then
    local reset="$(tput sgr0)"
    local red="$(tput setaf 1)"
    local green="$(tput setaf 2)"
    local yellow="$(tput setaf 3)"
    local cyan="$(tput setaf 6)"
    local white="$(tput setaf 7)"
  fi

  echo -e "${yellow}\nALOJA-BENCH, script to run benchmarks and collect results
${white}Usage:
$0 [-C clusterName <uses aloja_cluster.conf if present or not specified>]
[-n net <IB|ETH>]
[-d disk <SSD|HDD|RL{1,2,3}|R{1,2,3}>]
[-b benchmark <-min|-10>]
[-r replicaton <positive int>]
[-m max mappers and reducers <positive int>]
[-i io factor <positive int>] [-p port prefix <3|4|5>]
[-I io.file <positive int>]
[-l list of benchmarks <space separated string>]
[-c compression <0 (dissabled)|1|2|3>]
[-z <block size in bytes>]
[-s (save prepare)]
[-N (don't delete files)]
[-H hadoop version <hadoop1|hadoop2>]
[-t execution type (e.g: default, experimental)]
[-e extrae (instrument execution)]

${cyan}example: $0 -C vagrant-99 -n ETH -d HDD -r 1 -m 12 -i 10 -p 3 -b _min -I 4096 -l wordcount -c 1
$reset"
  exit 1;
}

# parses command line options
get_options() {

  OPTIND=1 #A POSIX variable, reset in case getopts has been used previously in the shell.

  while getopts "h?:C:b:r:n:d:m:i:p:l:I:c:z:H:sN:D:t" opt; do
      case "$opt" in
      h|\?)
        usage
        ;;
      C)
        clusterName=$OPTARG
        ;;
      n)
        NET=$OPTARG
        [ "$NET" == "IB" ] || [ "$NET" == "ETH" ] || usage
        ;;
      d)
        DISK=$OPTARG
        defaultDisk=0
        ;;
      b)
        BENCH=$OPTARG
        [ "$BENCH" == "HiBench" ] || [ "$BENCH" == "HiBench-10" ] || [ "$BENCH" == "HiBench-min" ] || [ "$BENCH" == "HiBench-1TB" ] || [ "$BENCH" == "HiBench3" ] || [ "$BENCH" == "HiBench3HDI" ] || [ "$BENCH" == "HiBench3-min" ] || [ "$BENCH" == "sleep" ] || [ "$BENCH" == "Big-Bench" ] || [ "$BENCH" == "TPCH" ] || usage
        ;;
      r)
        REPLICATION=$OPTARG
        ((REPLICATION > 0)) || usage
        ;;
      m)
        MAX_MAPS=$OPTARG
        ((MAX_MAPS > 0 && MAX_MAPS < 33)) || usage
        ;;
      i)
        IO_FACTOR=$OPTARG
        ((IO_FACTOR > 0)) || usage
        ;;
      I)
        IO_FILE=$OPTARG
        ((IO_FILE > 0)) || usage
        ;;
      p)
        PORT_PREFIX=$OPTARG
        ((PORT_PREFIX > 0 && PORT_PREFIX < 6)) || usage
        ;;
      c)
        if [ "$OPTARG" == "0" ] ; then
          COMPRESS_GLOBAL=0
          COMPRESS_TYPE=0
        elif [ "$OPTARG" == "1" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=1
          COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
        elif [ "$OPTARG" == "2" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=2
          COMPRESS_CODEC_GLOBAL=com.hadoop.compression.lzo.LzoCodec
        elif [ "$OPTARG" == "3" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=3
          COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.SnappyCodec
        fi
        ;;
      l)
        LIST_BENCHS=$OPTARG
        ;;
      z)
        BLOCK_SIZE=$OPTARG
        ;;
      s)
        SAVE_BENCH=1
        ;;
      t)
        EXEC_TYPE=$OPTARG
        ;;
      N)
        DELETE_HDFS=0
        ;;
      D)
        LIMIT_DATA_NODES=$OPTARG
        echo "LIMIT_DATA_NODES $LIMIT_DATA_NODES"
        ;;
      H)
        HADOOP_VERSION=$OPTARG
        [ "$HADOOP_VERSION" == "hadoop1" ] || [ "$HADOOP_VERSION" == "hadoop2" ] || usage
        ;;
      e)
          INSTRUMENTATION=1
        ;;
      esac
  done

  shift $((OPTIND-1))

  [ "$1" = "--" ] && shift

}

loggerb(){
  stamp=$(date '+%s')
  echo "${stamp} : $1" 2>&1 |tee -a $LOG_PATH
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}

get_date_folder(){
  echo "$(date +%Y%m%d_%H%M%S)"
}

# Tests if the supplied hostname can coincides with any node in the cluster
# NOTE: if you cluster doesnt pass this function you should overwrite it with and specific implementation in your benchark defs
# $1 hostname to check
test_in_cluster() {
  local hostname="$1"
  local coincides=1 #return code when not found

  if [ "$nodeNames" ] ; then
    for node in $nodeNames ; do #pad the sequence with 0s
      [[ "$hostname" == "$node"* ]] && coincides=0
    done
  else
    die "\$nodeNames var is not defined for cluster $clusterName"
  fi

  return $coincides
}

#$1 port prefix (optional)
get_aloja_dir() {
 if [ "$1" ] ; then
  echo "${BENCH_FOLDER}_$PORT_PREFIX"
 else
  echo "${BENCH_FOLDER}"
 fi
}

# Return a list of
# $1 disk type
get_specified_disks() {
  local disk="$1"
  local dir

  if [ "$disk" == "SSD" ] || [ "$disk" == "HDD" ] ; then
    dir="${BENCH_DISKS["$disk"]}"
  elif [[ "$disk" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"
    for disk_number in $(seq 1 $disks) ; do
      dir+="${BENCH_DISKS["${disks_type}${disk_number}"]}\n"
    done
    dir="${dir:0:(-2)}" #remove trailing \n
  else
    die "Incorrect disk specified: $disk"
  fi

  echo -e "$dir"
}

# Returns the tmp disk in cases when mixing local and remote disks (eg. RL1)
#$1 disk type
get_tmp_disk() {
  local dir

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    if [ "$disks_type" == "RL" ] ; then
      dir="${BENCH_DISKS["HDD"]}"
    elif [ "$disks_type" == "HS" ] ; then
      dir="${BENCH_DISKS["SSD"]}"
    else
      dir="${BENCH_DISKS["${disks_type}1"]}"
    fi
  fi

  if [ "$dir" ] ; then
    echo -e "$dir"
  else
    die "Cannot determine tmp disk"
  fi
}

# Simple helper to append the tmp disk path
get_all_disks() {
  echo -e "$(get_specified_disks "$disk")
$(get_tmp_disk "$disk")"
}


# Performs some basic validations
# $1 DISK
validate() {
  local disk="$1"

  # Check whethear we are in the right cluster
  if ! test_in_cluster "$(hostname)" ; then
    die "host $(hostname) does not belong to specified cluster $clusterName\nMake sure you run this script from within a cluster"
  fi

  if ! inList "$CLUSTER_NETS" "$NET" ; then
    die "Disk type $NET not supported for $clusterName\nSupported: $NET"
  fi

  # Disk validations
  if ! inList "$CLUSTER_DISKS" "$DISK" ; then
    die "Disk type $DISK not supported for $clusterName\nSupported: $CLUSTER_DISKS"
  fi

  # Check that we got the dynamic disk location correctly
  if [ ! "$(get_initial_disk "$disk")" ] ; then
    die "cannot determine $DISK path"
  fi

  # Iterate all defined and tmp disks to see if we can write to them
  local disks="$(get_all_disks)"
  for disk_tmp in $disks ; do
    logger "DEBUG: testing write permissions in $disk_tmp"
    local touch_file="$disk_tmp/aloja.touch"
    #if file exists test if we can delete it
    if [ -f "$touch_file" ] ; then
      rm "$touch_file" || die "Cannot delete files in $disk_tmp"
    fi
    touch "$touch_file" || die "Cannot write files in $disk_tmp"
    rm "$touch_file" || die "Cannot delete files in $disk_tmp"
  done
}

# Groups initialization phases
initialize() {
  # initialize cluster node names and connect string
  initialize_node_names
  # set the name for the job run
  set_job_config
  # check if all nodes are up
  test_nodes_connection
  # check if ~/share is correctly mounted
  test_share_dir
}

#old code moved here
# TODO cleanup
initialize_node_names() {
  #For infiniband tests
  if [ "${NET}" == "IB" ] ; then
    IFACE="ib0"
    master_name="$(get_master_name_IB)"
    node_names="$(get_node_names_IB)"
  else
    #IFACE should be already setup
    master_name="$(get_master_name)"
    node_names="$(get_node_names)"
  fi

  NUMBER_OF_DATA_NODES="$numberOfNodes"

  if [ ! -z "$LIMIT_DATA_NODES" ] ; then
    node_iteration=0
    for node in $node_names ; do
      if [ ! -z "$nodes_tmp" ] ; then
        node_tmp="$node_tmp\n$node"
      else
        node_tmp="$node"
      fi
      [[ $node_iteration -ge $LIMIT_DATA_NODES ]]  && break;
      node_iteration=$((node_iteration+1))
    done

    node_name=$(echo -e "$nodes_tmp")
    NUMBER_OF_DATA_NODES="$LIMIT_DATA_NODES"
  fi

  DSH="dsh -M -c -m "
  DSH_MASTER="ssh $master_name"

  DSH="$DSH $(nl2char "$node_names" ",") "
  DSH_C="$DSH -c " #concurrent

  DSH_SLAVES="${DSH_C/"$master_name,"/}" #remove master name and trailling coma
}

# Tests if defined nodes are accesible vis SSH
test_nodes_connection() {
  loggerb "INFO: Testing connectivity to nodes"
  local node_output="$($DSH "echo '$testKey' 2>&1")"
  local num_OK="$(echo -e "$node_output"|grep "$testKey"|wc -l)"
  local num_nodes="$(( NUMBER_OF_DATA_NODES + 1 ))"
  if (( num_OK != num_nodes )) ; then
    die "cannot connect via SSH to all nodes. Num OK: $num_OK Out of: $num_nodes
Output:
$node_output"

  else
    loggerb "INFO: All $num_nodes nodes are accesible via SSH"
  fi
}

# Tries to mount shared folder
# $1 shared folder
mount_share() {
  shared_folder="$1"

  if [ ! "$noSudo" ] ; then
    logger "WARNING: attempting to remount $shared_folder"
    $DSH "
if [ ! -d '$shared_folder' ] ; then
  sudo umount '$shared_folder';
  sudo mount '$shared_folder';
  sudo mount -a;
fi
"

  fi
}

# Tests if nodes have the shared dir correctly mounted
# $1 if to exit (for retries)
test_share_dir() {
  local no_retry="$1"
  local test_file="$homePrefixAloja/$userAloja/share/safe_store"

  loggerb "INFO: Testing is ~/share mounted correctly"
  local node_output="$($DSH "ls '$test_file' && echo '$testKey' 2>&1")"
  local num_OK="$(echo -e "$node_output"|grep "$testKey"|wc -l)"
  local num_nodes="$(( NUMBER_OF_DATA_NODES + 1 ))"
  if (( num_OK != num_nodes )) ; then
    if [ "$no_retry" ] ; then
      die "~/share dir not mounted correctly  Num OK: $num_OK Out of: $num_nodes
Output:
$node_output"
    else #try again
      mount_share "$homePrefixAloja/$userAloja/share/"
      test_share_dir "no_retry"
    fi
  else
    loggerb "INFO: All $num_nodes nodes have the ~/share dir correctly mounted"
  fi
}

#old code moved here
# TODO cleanup
set_job_config() {
  # Output directory name
  CONF="${NET}_${DISK}_b${BENCH}_D${NUMBER_OF_DATA_NODES}_${clusterName}"
  JOB_NAME="$(get_date_folder)_$CONF"

  JOB_PATH="$BENCH_BASE_DIR/jobs_$clusterName/$JOB_NAME"
  LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
  LOG="2>&1 |tee -a $LOG_PATH"

  #create dir to save files in one host
  $DSH_MASTER "mkdir -p $JOB_PATH"
  $DSH_MASTER "touch $LOG_PATH"

  loggerb "STARTING EXECUTION of $JOB_NAME"
  loggerb  "Job path: $JOB_PATH"
  loggerb  "Log path: $LOG_PATH"
  loggerb  "Conf: $CONF"
  loggerb  "Benchmark: $BENCH_HIB_DIR"
  loggerb  "Benchs to execute: $LIST_BENCHS"
  loggerb  "DSH: $DSH"
  #loggerb  "DSH_C: $DSH_C"
  #loggerb  "DSH_SLAVES: $DSH_SLAVES"
  loggerb  ""

}


#old code moved here
# TODO cleanup
initialize_hadoop_vars() {

  [ ! "$HDD" ] && die "HDD var not set!"

  BENCH_H_DIR="$HDD/aplic/$BENCH_HADOOP_VERSION" #execution dir

  if [[ "$BENCH" == HiBench* ]]; then
    EXECUTE_HIBENCH="true"
  fi

  BENCH_HIB_DIR="$BENCH_SOURCE_DIR/$BENCH"
  if [[ "$BENCH" == HiBench* ]]; then
    BENCH_HIB_DIR="$BENCH_SOURCE_DIR/HiBench2"
  fi
  if [[ "$BENCH" == HiBench3* ]]; then
    BENCH_HIB_DIR="$BENCH_SOURCE_DIR/HiBench3"
  fi

  if [ "$clusterType" == "PaaS" ]; then
    HADOOP_VERSION="hadoop2"
  fi

  if [ ! "$BENCH_HADOOP_VERSION" ] ; then
    if [ "$HADOOP_VERSION" == "hadoop1" ]; then
      BENCH_HADOOP_VERSION="hadoop-1.0.3"
    elif [ "$HADOOP_VERSION" == "hadoop2" ] ; then
      BENCH_HADOOP_VERSION="hadoop-2.6.0"
    fi
  fi

  ##FOR TPCH ONLY, default 1TB
  [ ! "$TPCH_SCALE_FACTOR" ] && TPCH_SCALE_FACTOR=1000

  # Use instrumented version of Hadoop
  if [ "$INSTRUMENTATION" == "1" ] ; then
    BENCH_HADOOP_VERSION="${BENCH_HADOOP_VERSION}-instr"
  fi

  #make sure all spawned background jobs and services are stoped or killed when done
  if [ ! -z "$EXECUTE_HIBENCH" ] || [ "$BENCH" == "TPCH" ]; then
    trap 'echo "RUNNING TRAP!"; stop_hadoop; stop_monit; stop_sniffer; [ $(jobs -p) ] && kill $(jobs -p); exit 1;' SIGINT SIGTERM
  fi

  #export HADOOP_HOME="$HADOOP_DIR"
  [ ! $JAVA_HOME ] && export JAVA_HOME="$BENCH_SOURCE_DIR/jdk1.7.0_25"

#loggerb  "DEBUG: userAloja=$userAloja
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

# old code from cleanup
# TODO improve
set_monit_binaries() {
  if [ "$clusterType" != "PaaS" ]; then
    bwm_source="$BENCH_SOURCE_DIR/bin/bwm-ng"
    vmstat="$HDD/aplic/vmstat_$PORT_PREFIX"
    bwm="$HDD/aplic/bwm-ng_$PORT_PREFIX"
    sar="$HDD/aplic/sar_$PORT_PREFIX"
  else
    bwm_source="bwm-ng"
    vmstat="vmstat"
    bwm="bwm-ng"
    sar="sar"
  fi
}


update_OS_config() {
  if [ ! "$noSudo" ] && [ "$EXECUTE_HIBENCH" ]; then

    $DSH "
sudo sysctl -w vm.swappiness=0 > /dev/null;
sudo sysctl vm.panic_on_oom=1 > /dev/null;
sudo sysctl -w fs.file-max=65536 > /dev/null;
sudo service ufw stop 2>&1 > /dev/null;
"

  fi
}

check_aplic_updates() {
  #only copy files if version has changed (to save time)
  loggerb  "Checking if to generate source dirs $BENCH_BASE_DIR/aplic/aplic_version == $BENCH_SOURCE_DIR/aplic_version"
  for node in $node_names ; do
    loggerb  " for host $node"
    if [ "$(ssh "$node" "[ "\$\(cat $BENCH_BASE_DIR/aplic/aplic_version\)" == "\$\(cat $BENCH_SOURCE_DIR/aplic_version 2\> /dev/null \)" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
      loggerb  "At least host $node did not have source dirs. Generating source dirs for ALL hosts"

      if [ ! "$(ssh "$node" "[ -d \"$BENCH_BASE_DIR/aplic\" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
        #logger "Downloading initial aplic dir from dropbox"
        #$DSH "wget -nv https://www.dropbox.com/s/ywxqsfs784sk3e4/aplic.tar.bz2?dl=1 -O $BASE_DIR/aplic.tar.bz2"

        $DSH "rsync -aur --force $BENCH_BASE_DIR/aplic.tar.bz2 /tmp/"

        loggerb  "Uncompressing aplic"
        $DSH  "mkdir -p $BENCH_SOURCE_DIR/; cd $BENCH_SOURCE_DIR/../; tar -C $BENCH_SOURCE_DIR/../ -jxf /tmp/aplic.tar.bz2; "  #rm aplic.tar.bz2;
      fi

      logger "Rsynching files"
      $DSH "mkdir -p $BENCH_SOURCE_DIR; rsync -aur --force $BENCH_BASE_DIR/aplic/* $BENCH_SOURCE_DIR/"
      break #dont need to check after one is missing
    else
      loggerb  " Host $node up to date"
    fi
  done

  #if [ "$(cat $BENCH_BASE_DIR/aplic/aplic_version)" != "$(cat $BENCH_SOURCE_DIR/aplic_version)" ] ; then
  #  loggerb  "Generating source dirs"
  #  $DSH "mkdir -p $BENCH_SOURCE_DIR; cp -ru $BENCH_BASE_DIR/aplic/* $BENCH_SOURCE_DIR/"
  #  #$DSH "cp -ru $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}-home $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}" #rm -rf $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION};
  #elsefi
  #  loggerb  "Source dirs up to date"
  #fi

}

zabbix_sender(){
  :
  #echo "al-1001 $1" | /home/pristine/share/aplic/zabbix/bin/zabbix_sender -c /home/pristine/share/aplic/zabbix/conf/zabbix_agentd_az.conf -T -i - 2>&1 > /dev/null
  #>> $LOG_PATH

##For zabbix monitoring make sure IB ports are available
#ssh_tunnel="ssh -N -L al-1001:30070:al-1001-ib0:30070 -L al-1001:30030:al-1001-ib0:30030 al-1001"
##first make sure we kill any previous, even if we don't need it
#pkill -f "ssh -N -L"
##"$ssh_tunnel"
#
#if [ "${NET}" == "IB" ] ; then
#  $ssh_tunnel 2>&1 |tee -a $LOG_PATH &
#fi

}

restart_monit(){
  loggerb "Restarting Monit"

  stop_monit

  $DSH_C "mkdir -p $HDD" 2>&1 |tee -a $LOG_PATH
  $DSH_C "$vmstat -n 1 >> $HDD/vmstat-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  $DSH_C "$bwm -o csv -I bond0,eth0,eth1,eth2,eth3,ib0,ib1 -u bytes -t 1000 >> $HDD/bwm-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  $DSH_C "$sar -o $HDD/sar-\$(hostname).sar 1 >/dev/null 2>&1 &" 2>&1 |tee -a $LOG_PATH

  loggerb "Monit ready"
}

stop_monit(){
  loggerb "Stoping monit"
  $DSH_C "killall -9 $vmstat"   2> /dev/null |tee -a $LOG_PATH
  $DSH_C "killall -9 $bwm"      2> /dev/null |tee -a $LOG_PATH
  $DSH_C "killall -9 $sar"      2> /dev/null >> $LOG_PATH

  loggerb "Stop monit ready"
}

save_bench() {
  loggerb "Saving benchmark $1"
  $DSH "mkdir -p $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $HDD_TMP/{bwm,vmstat}*.log $HDD_TMP/sar*.sar $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
 if [ "$clusterType" == "PaaS" ]; then
	hdfs dfs -copyToLocal /mr-history $JOB_PATH/$1
 fi
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #$DSH "cp -r $HDD/logs/* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #$DSH "cp $HDD/logs/job*.xml $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #cp "${BENCH_HIB_DIR}$bench/hibench.report" "$JOB_PATH/$1/"

  #loggerb "Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH" 2>&1 |tee -a $LOG_PATH
  #pending, delete

  loggerb "Compresing and deleting $1"

  $DSH_MASTER "cd $JOB_PATH; tar -cjf $JOB_PATH/$1.tar.bz2 $1;" 2>&1 |tee -a $LOG_PATH
  #tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  $DSH_MASTER "rm -rf $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #$JOB_PATH/conf_* #TODO check

  #empy the contents from original disk  TODO check if still necessary
  #$DSH "for i in $HDD/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH

  loggerb "Done saving benchmark $1"
}

# Tests if a directory is present in the system
# $1 dir to test
test_directory_not_exists() {
  local dir="$1"
  local node_output="$($DSH "[ ! -d '$dir' ] && echo '$testKey' 2>&1")"
  local num_OK="$(echo -e "$node_output"|grep "$testKey"|wc -l)"
  local num_nodes="$(( NUMBER_OF_DATA_NODES + 1 ))"
  if (( num_OK != num_nodes )) ; then
    die "Cannot delete folder $dir. Num nodes OK: $num_OK Out of: $num_nodes
Output:
$node_output"
  fi
}


# Sets the aloja-bench folder ready for benchmarking
# $1 disk
prepare_folder(){
  local disk="$1"

  loggerb "INFO: Preparing benchmark run dirs"
  local disks="$(get_all_disks) "

  if [ "$DELETE_HDFS" == "1" ] ; then
    loggerb "INFO: Deleting previous run files of disk config: $disk in: $(get_aloja_dir "$PORT_PREFIX")"
    for disk_tmp in $disks ; do
      local  disk_full_path="$disk_tmp/$(get_aloja_dir "$PORT_PREFIX")"
      $DSH "[ -d '$disk_full_path' ] && rm -rf $disk_full_path" 2>&1 |tee -a $LOG_PATH
      #check if we had problems deleting a folder
      test_directory_not_exists "$disk_full_path"
    done
  else
    loggerb "INFO: Deleting only the log dir"
    for disk_tmp in $disks ; do
      $DSH "rm -rf $disk_tmp/$(get_aloja_dir "$PORT_PREFIX")/logs/*" 2>&1 |tee -a $LOG_PATH
    done
  fi

  #set the main path for the benchmark
  HDD="$(get_initial_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"
  #for hadoop tmp dir
  HDD_TMP="$(get_tmp_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"

  loggerb "Creating bench main dir at: $HDD/aplic"

  $DSH "mkdir -p $HDD/aplic $HDD_TMP" 2>&1 |tee -a $LOG_PATH

  # specify which binaries to use for monitoring
  set_monit_binaries

  $DSH "cp /usr/bin/vmstat $vmstat" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $bwm_source $bwm" 2>&1 |tee -a $LOG_PATH
  $DSH "cp /usr/bin/sar $sar" 2>&1 |tee -a $LOG_PATH
}

set_omm_killer() {
  loggerb "WARNING: OOM killer not set for benchmark"
  #Example: echo 15 > proc/<pid>/oom_adj significantly increase the likelihood that process <pid> will be OOM killed.
  #pgrep apache2 |sudo xargs -I %PID sh -c 'echo 10 > /proc/%PID/oom_adj'
}

function timestamp() {
  sec=`date +%s`
  nanosec=`date +%N`
  tmp=`expr $sec \* 1000 `
  msec=`expr $nanosec / 1000000 `
  echo `expr $tmp + $msec`
}

function calc_exec_time() {
  awk "BEGIN {printf \"%.3f\n\", ($2-$1)/1000}"
}

save_disk_usage() {
  echo "# Checking disk space with df $1" >> $JOB_PATH/disk.log
  $DSH "df -h" 2>&1 >> $JOB_PATH/disk.log
  echo "# Checking hadoop folder space $1" >> $JOB_PATH/disk.log
  $DSH "du -sh $HDD/*" 2>&1 >> $JOB_PATH/disk.log
}
