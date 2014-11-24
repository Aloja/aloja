#!/bin/bash
# SCRIPT TO STOP, SET CONFIG, AND START HADOOP and run HiBench in AZURE

usage() {
  echo -e "Usage:
$0 -C clusterName
`#[-n net <IB|ETH>] `
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

example: $0 -C al-04 -n IB -d HDD -r 1 -m 12 -i 10 -p 3 -b _min -I 4096 -l wordcount -c 1
" 1>&2;

  exit 1;
}

OPTIND=1 #A POSIX variable, reset in case getopts has been used previously in the shell.

# Default values
VERBOSE=0
NET="ETH"
DISK="HDD"
BENCH=""
REPLICATION=1
MAX_MAPS=8
IO_FACTOR=10
PORT_PREFIX=3
IO_FILE=65536
LIST_BENCHS="wordcount sort terasort kmeans pagerank bayes dfsioe" #nutchindexing hivebench

COMPRESS_GLOBAL=0
COMPRESS_TYPE=0

#COMPRESS_GLOBAL=1
#COMPRESS_TYPE=1
#COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
#COMPRESS_CODEC_GLOBAL=com.hadoop.compression.lzo.LzoCodec
#COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.SnappyCodec
SAVE_BENCH=""

BLOCK_SIZE=67108864

DELETE_HDFS=1

while getopts ":h:?:C:v:b:r:n:d:m:i:p:l:I:c:z:sN:S" opt; do
    case "$opt" in
    h|\?)
      usage
      ;;
    v)
      VERBOSE=1
      ;;
    C)
      clusterName=$OPTARG
      [ ! -z "$clusterName" ] || usage
      ;;
    n)
      NET=$OPTARG
      [ "$NET" == "IB" ] || [ "$NET" == "ETH" ] || usage
      ;;
    d)
      DISK=$OPTARG
      [ "$DISK" == "SSD" ] || [ "$DISK" == "HDD" ] || [ "$DISK" == "RR1" ] || [ "$DISK" == "RR2" ] || [ "$DISK" == "RR3" ] || [ "$DISK" == "RL1" ] || [ "$DISK" == "RL2" ] || [ "$DISK" == "RL3" ] || usage
      ;;
    b)
      BENCH=$OPTARG
      [ "$BENCH" == "-10" ] || [ "$BENCH" == "-min" ] || [ "$BENCH" == "sleep" ]  || usage
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
        COMPRESS_TYPE=1
        COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
      elif [ "$OPTARG" == "2" ] ; then
        COMPRESS_TYPE=2
        COMPRESS_CODEC_GLOBAL=com.hadoop.compression.lzo.LzoCodec
      elif [ "$OPTARG" == "3" ] ; then
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
    N)
      DELETE_HDFS=0
      ;;
    S)
      LIMIT_SLAVE_NODES=$OPTARG
      echo "LIMIT_SLAVE_NODES $LIMIT_SLAVE_NODES"
      ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

[ -z "$clusterName" ] && usage

#####
#load cluster config and common functions
#clusterConfigFile="cluster_${clusterName}.conf"

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR_TMP/common/include_benchmarks.sh"

loggerb  "INFO: includes loaded"

#####


NUMBER_OF_SLAVES="$numberOfNodes"
userAloja="pristine"

DSH="dsh -M -c -m "

#DEPRECATED for infiniband tests
#if [ "${NET}" == "IB" ] ; then
#  host1="al-1001-ib0"
#  host2="al-1002-ib0"
#  host3="al-1003-ib0"
#  host4="al-1004-ib0"
#  IFACE="ib0"

IFACE="eth0"

node_names="$(get_node_names)"

if [ ! -z "$LIMIT_SLAVE_NODES" ] ; then

  node_iteration=0
  for node in $node_names ; do
    if [ ! -z "$nodes_tmp" ] ; then
      node_tmp="$node_tmp\n$node"
    else
      node_tmp="$node"
    fi
    [[ $node_iteration -ge $LIMIT_SLAVE_NODES ]]  && break;
    node_iteration=$((node_iteration+1))
  done

  node_name=$(echo -e "$nodes_tmp")
  NUMBER_OF_SLAVES="$LIMIT_SLAVE_NODES"
fi

DSH="$DSH $(nl2char "$node_names" ",")"

#nodes="$(nl2char "$node_names" " ")"

master_name="$(get_master_name)"
DSH_MASTER="ssh $master_name"
DSH_SLAVE="ssh $master_name" #TODO check if OK

DSH_C="$DSH -c " #concurrent

[ -z "BENCH_HDD" ] || [ -z "BENCH_SOURCE_DIR" ] || [ -z "BENCH_HADOOP_VERSION" ] && {
  loggerb  "ERROR: Init variables not set"
  exit 1
}

#loggerb  "DEBUG: BENCH_BASE_DIR=$BENCH_BASE_DIR
#BENCH_DEFAULT_SCRATCH=$BENCH_DEFAULT_SCRATCH
#BENCH_SOURCE_DIR=$BENCH_SOURCE_DIR
#BENCH_SAVE_PREPARE_LOCATION=$BENCH_SAVE_PREPARE_LOCATION
#BENCH_HADOOP_VERSION=$BENCH_HADOOP_VERSION
#Master node: $master_name Nodes:
#$node_names"


#TODO fix for non HDD
if [ "$DISK" == "SSD" ] ; then
  HDD="/scratch/local/hadoop-hibench_$PORT_PREFIX"
elif [ "$DISK" == "HDD" ] || [ "$DISK" == "RL1" ] || [ "$DISK" == "RL2" ] || [ "$DISK" == "RL3" ] ; then
  HDD="$BENCH_DEFAULT_SCRATCH/hadoop-hibench_$PORT_PREFIX"
elif [ "$DISK" == "RR1" ] || [ "$DISK" == "RR2" ] || [ "$DISK" == "RR3" ]; then
  HDD="/scratch/attached/1/hadoop-hibench_$PORT_PREFIX"
else
  echo "Incorrect disk specified: $DISK"
  exit 1
fi

#BENCH_BASE_DIR="/home/$userAloja/share"
#BENCH_SOURCE_DIR="/scratch/local/aplic"

#BENCH_HADOOP_VERSION="hadoop-1.0.3"

BENCH_H_DIR="$HDD/aplic/$BENCH_HADOOP_VERSION" #execution dir

if [ -z "$BENCH" ] || [ "$BENCH" == "-min" ] || [ "$BENCH" == "-10" ]; then
  BENCH="HiBench$BENCH"
  EXECUTE_HIBENCH="true"
fi

BENCH_HIB_DIR="$BENCH_SOURCE_DIR/${BENCH}/"

#make sure all spawned background jobs are killed when done (ssh ie ssh port forwarding)
#trap "kill 0" SIGINT SIGTERM EXIT
if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  trap 'echo "RUNNING TRAP!"; stop_hadoop; stop_monit; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM EXIT
else
  trap 'echo "RUNNING TRAP!"; stop_monit; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM EXIT
fi



DATE='date +%Y%m%d_%H%M%S'

if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  CONF="conf_${NET}_${DISK}_b${BENCH}_m${MAX_MAPS}_i${IO_FACTOR}_r${REPLICATION}_I${IO_FILE}_c${COMPRESS_TYPE}_z$((BLOCK_SIZE / 1048576 ))_S${NUMBER_OF_SLAVES}_${clusterName}"
else
  CONF="conf_${NET}_${DISK}_b${BENCH}_S${NUMBER_OF_SLAVES}_${clusterName}"
fi

JOB_NAME="`$DATE`_$CONF"

JOB_PATH="$BENCH_BASE_DIR/jobs_$clusterName/$JOB_NAME"
LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
LOG="2>&1 |tee -a $LOG_PATH"


#export HADOOP_HOME="$HADOOP_DIR"
export JAVA_HOME="$BENCH_SOURCE_DIR/jdk1.7.0_25"

bwm_source="$BENCH_SOURCE_DIR/bin/bwm-ng"
vmstat="$HDD/aplic/vmstat_$PORT_PREFIX"
bwm="$HDD/aplic/bwm-ng_$PORT_PREFIX"
sar="$HDD/aplic/sar_$PORT_PREFIX"

echo "$(date '+%s') : STARTING EXECUTION of $JOB_NAME"


if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  #temporary OS config
  if [ -z "$noSudo" ] ; then
    $DSH "sudo sysctl -w vm.swappiness=0;sudo sysctl -w fs.file-max=65536; sudo service ufw stop;"

    #temporary to avoid read-only file system errors
    echo "Re-mounting attached disks"
    $DSH "sudo umount /home/$userAloja/share /scratch/attached/1 /scratch/attached/2 /scratch/attached/3; sudo mount -a"

    correctly_mounted_nodes=$($DSH "ls ~/share/safe_store 2> /dev/null" |wc -l)

    if [ "$correctly_mounted_nodes" != "$(( NUMBER_OF_SLAVES + 1 ))" ] ; then
      echo "ERROR, share directory is not mounted correctly.  Only $correctly_mounted_nodes OK. Exiting..."
      echo "DEBUG: Correct $correctly_mounted_nodes NUMBER_OF_SLAVES $NUMBER_OF_SLAVES + 1"
      exit 1
    fi
  fi
fi

#create dir to save files in one host
$DSH_MASTER "mkdir -p $JOB_PATH"
$DSH_MASTER "touch $LOG_PATH"


if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  if [ -z "$noSudo" ] ; then
    loggerb  "Setting scratch permissions"
    $DSH "sudo chown -R $userAloja: /scratch"
  fi
fi

#only copy files if version has changed (to save time in azure)
loggerb  "Checking if to generate source dirs"
for node in $node_names ; do
  loggerb  " for host $node"
  if [ "$(ssh "$node" "[ "\$\(cat $BENCH_BASE_DIR/aplic/aplic_version\)" == "\$\(cat $BENCH_SOURCE_DIR/aplic_version 2\> /dev/null \)" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
    loggerb  "At least host $node did not have source dirs. Generating source dirs for ALL hosts"
    $DSH_C "mkdir -p $BENCH_SOURCE_DIR; cp -ru $BENCH_BASE_DIR/aplic/* $BENCH_SOURCE_DIR/"
    break #dont need to check after one is missing
  else
    loggerb  " Host $node up to date"
  fi
done



#if [ "$(cat $BENCH_BASE_DIR/aplic/aplic_version)" != "$(cat $BENCH_SOURCE_DIR/aplic_version)" ] ; then
#  loggerb  "Generating source dirs"
#  $DSH "mkdir -p $BENCH_SOURCE_DIR; cp -ru $BENCH_BASE_DIR/aplic/* $BENCH_SOURCE_DIR/"
#  #$DSH "cp -ru $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}-home $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}-scratch" #rm -rf $BENCH_SOURCE_DIR/${BENCH_HADOOP_VERSION}-scratch;
#else
#  loggerb  "Source dirs up to date"
#fi


loggerb  "Job name: $JOB_NAME"
loggerb  "Job path: $JOB_PATH"
loggerb  "Log path: $LOG_PATH"
loggerb  "Disk location: $HDD"
loggerb  "Conf: $CONF"
loggerb  "Benchmark: $BENCH_HIB_DIR"
loggerb  "Benchs to execute: $LIST_BENCHS"
loggerb  "DSH: $DSH"
loggerb  ""

##For zabbix monitoring make sure IB ports are available
#ssh_tunnel="ssh -N -L al-1001:30070:al-1001-ib0:30070 -L al-1001:30030:al-1001-ib0:30030 al-1001"
##first make sure we kill any previous, even if we don't need it
#pkill -f "ssh -N -L"
##"$ssh_tunnel"
#
#if [ "${NET}" == "IB" ] ; then
#  $ssh_tunnel 2>&1 |tee -a $LOG_PATH &
#fi

#stop running instances with the previous conf
#$DSH_MASTER $BENCH_H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH

#prepare selected conf
#$DSH "rm -rf $DIR/conf/*" 2>&1 |tee -a $LOG_PATH
#$DSH "cp -r $DIR/$CONF/* $DIR/conf/" 2>&1 |tee -a $LOG_PATH


if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  prepare_hadoop_config ${NET} ${DISK} ${BENCH}
else
  prepare_config
fi

start_time=$(date '+%s')

########################################################
loggerb  "Starting execution of $BENCH"


##PREPARED="/scratch/local/ssd/pristine/prepared"
#"wordcount" "sort" "terasort" "kmeans" "pagerank" "bayes" "nutchindexing" "hivebench" "dfsioe"
#  "nutchindexing"

if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  execute_HiBench
elif [ "$BENCH" == "sleep" ] ; then
  execute_sleep
else
  loggerb "ERROR: $BENCH is not definied.  Exiting..."
  exit 1
fi

if [ ! "$EXECUTE_HIBENCH" ] ; then
  stop_monit
  save_bench "$BENCH"
fi


loggerb  "$(date +"%H:%M:%S") DONE $bench"


########################################################
end_time=$(date '+%s')

#clean up
if [ ! -z "$EXECUTE_HIBENCH" ] ; then
  stop_hadoop
fi

stop_monit


#copy
loggerb "INFO: Copying resulting files From: $HDD/* To: $JOB_PATH/"
$DSH "cp $HDD/* $JOB_PATH/"


#report
#finish_date=`$DATE`
#total_time=`expr $(date '+%s') - $(date '+%s')`
#$(touch ${JOB_PATH}/finish_${finish_date})
#$(touch ${JOB_PATH}/total_${total_time})
du -h $JOB_PATH|tail -n 1
loggerb  "DONE, total time $total_time seconds. Path $JOB_PATH"