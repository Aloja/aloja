#!/bin/bash
# SCRIPT TO STOP, SET CONFIG, AND START HADOOP and run HiBench in AZURE

usage() {
  echo -e "Usage:
$0 -C clusterName
`#[-n net <IB|ETH>] [-s \(save prepare\)] -N \(don\'t delete files\)`
[-d disk <SSD|HDD|RL{1,2,3}|R{1,2,3}>]
[-b benchmark <-min|-10>]
[-r replicaton <positive int>]
[-m max mappers and reducers <positive int>]
[-i io factor <positive int>] [-p port prefix <3|4|5>]
[-I io.file <positive int>]
[-l list of benchmarks <space separated string>]
[-c compression <0 (dissabled)|1|2|3>]
[-z <block size in bytes>] [-s (save prepare)] -N (don't delete files)

example: $0 -C al-04 -n IB -d HDD -r 1 -m 12 -i 10 -p 3 -b -min -I 4096 -l wordcount -c 1
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
      #[ "$NET" == "IB" ] || [ "$NET" == "ETH" ] || usage
      ;;
    d)
      DISK=$OPTARG
      #[ "$DISK" == "SSD" ] || [ "$DISK" == "HDD" ] || [ "$DISK" == "RR1" ] || [ "$DISK" == "RR2" ] || [ "$DISK" == "RR3" ]  || [ "$DISK" == "RR4" ]  || [ "$DISK" == "RR5" ]  || [ "$DISK" == "RR6" ] || [ "$DISK" == "RL1" ] || [ "$DISK" == "RL2" ] || [ "$DISK" == "RL3" ] || [ "$DISK" == "RL4" ] || [ "$DISK" == "RL5" ]  || [ "$DISK" == "RL6" ] || [ "$DISK" == "HD1" ] || [ "$DISK" == "HD2" ] || [ "$DISK" == "HD3" ] || [ "$DISK" == "HD4" ] || [ "$DISK" == "HD5" ] || [ "$DISK" == "HD6" ]  || [ "$DISK" == "HD7" ] || usage
      ;;
    b)
      BENCH=$OPTARG
      [ "$BENCH" == "-10" ] || [ "$BENCH" == "-min" ] || [ "$BENCH" == "-1TB" ] || usage
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
      LIMIT_DATA_NODES=$OPTARG
      echo "LIMIT_DATA_NODES $LIMIT_DATA_NODES"
      ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

[ -z "$clusterName" ] && usage

#make sure all spawned background jobs are killed when done (ssh ie ssh port forwarding)
#trap "kill 0" SIGINT SIGTERM EXIT
trap 'echo "RUNNING TRAP!"; stop_hadoop; stop_monit; kill $(jobs -p); exit;' SIGINT SIGTERM EXIT

#####
#load cluster config and common functions
clusterConfigFile="cluster_${clusterName}.conf"

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONF_DIR="$CUR_DIR_TMP/common/"
source "$CUR_DIR_TMP/common/include_benchmarks.sh"

#####

#some validations
if ! inList "$CLUSTER_DISKS" "$DISK" ; then
  logger "ERROR: Disk type $DISK not supported for $clusterName\nSupported: $CLUSTER_DISKS"
  usage
fi

if ! inList "$CLUSTER_NETS" "$NET" ; then
  logger "ERROR: Disk type $NET not supported for $clusterName\nSupported: $NET"
  usage
fi


NUMBER_OF_DATA_NODES="$numberOfNodes"
#userAloja="pristine"

DSH="dsh -M -c -m "

#For infiniband tests
if [ "${NET}" == "IB" ] ; then
  IFACE="ib0"
  master_name="$(get_master_name_IB)"
  node_names="$(get_node_names_IB)"
else
  IFACE="eth0"
  master_name="$(get_master_name)"
  node_names="$(get_node_names)"
fi

DSH_MASTER="ssh $master_name"


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

DSH="$DSH $(nl2char "$node_names" ",")"

DSH_SLAVES="${DSH/"$master_name,"/}" #remove master name and trailling coma


#check that we got the dynamic disk location correctly
if [ -z "$(get_initial_disk "$DISK")" ] ; then
  loggerb "ERROR: cannot determint $DISK path"
  exit 1
fi

#set the main path for the benchmark
HDD="$(get_initial_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"
HDD_TMP="$(get_tmp_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")" #for hadoop tmp dir

BASE_DIR="$homePrefixAloja/$userAloja/share"
SOURCE_DIR="/scratch/local/aplic"
HADOOP_VERSION="hadoop-1.0.3"
H_DIR="$HDD/aplic/$HADOOP_VERSION" #execution dir
HIB_DIR="$SOURCE_DIR/HiBench${BENCH}"

#Location of prepared inputs
SAVE_LOCATION="/scratch/local/HiBench_prepare"


DATE='date +%Y%m%d_%H%M%S'
CONF="conf_${NET}_${DISK}_b${BENCH}_m${MAX_MAPS}_i${IO_FACTOR}_r${REPLICATION}_I${IO_FILE}_c${COMPRESS_TYPE}_z$((BLOCK_SIZE / 1048576 ))_S${NUMBER_OF_DATA_NODES}_${clusterName}"
JOB_NAME="`$DATE`_$CONF"

JOB_PATH="$homePrefixAloja/$userAloja/share/jobs_$clusterName/$JOB_NAME"
LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
LOG="2>&1 |tee -a $LOG_PATH"


#export HADOOP_HOME="$HADOOP_DIR"
export JAVA_HOME="$SOURCE_DIR/jdk1.7.0_25"

[ ! "$JAVA_XMS" ] && JAVA_XMS="-Xms256m"
[ ! "$JAVA_XMX" ] && JAVA_XMX="-Xmx512m"

bwm_source="$SOURCE_DIR/bin/bwm-ng"

echo "$(date '+%s') : STARTING EXECUTION of $JOB_NAME"
#
##temporary OS config
#$DSH "sudo sysctl -w vm.swappiness=0;sudo sysctl -w fs.file-max=65536; sudo service ufw stop;"
#
#  #temporary to avoid read-only file system errors
#  echo "Checking if to remount $homePrefixAloja/$userAloja/share"
#  $DSH_SLAVES "[ ! \"\$(ls $homePrefixAloja/$userAloja/share/safe_store )\" ] && { echo 'ERROR: share not mounted correctly'; sudo umount -f $homePrefixAloja/$userAloja/share; sudo fusermount -uz $homePrefixAloja/$userAloja/share;  sudo mount $homePrefixAloja/$userAloja/share; sudo mount -a; }"
#
#  for mount_point in "$homePrefixAloja/$userAloja/share" "/scratch/attached/1" "/scratch/attached/2" "/scratch/attached/3" ; do
#    echo "Checking if to remount $mount_point"
#    $DSH "[[ ! \"\$(mount |grep '$mount_point'| grep 'rw,' )\" || \"\$(touch $mount_point/touch )\" ]] && { echo 'ERROR: $mount_point not mounted correctly'; sudo umount -f $mount_point; sudo mount $mount_point; }"
#  done
#
#correctly_mounted_nodes=$($DSH "ls ~/share/safe_store 2> /dev/null" |wc -l)
#
#if [ "$correctly_mounted_nodes" != "$(( NUMBER_OF_DATA_NODES + 1 ))" ] ; then
#  echo "ERROR, share directory is not mounted correctly.  Only $correctly_mounted_nodes OK. Remounting..."
#
#  #temporary to avoid read-only file system errors
#  echo "Checking if to remount $homePrefixAloja/$userAloja/share"
#  $DSH_SLAVES "[ ! \"\$(ls $homePrefixAloja/$userAloja/share/safe_store )\" ] && { echo 'ERROR: share not mounted correctly'; sudo umount -f $homePrefixAloja/$userAloja/share; sudo fusermount -uz $homePrefixAloja/$userAloja/share; sudo pkill -9 -f 'sshfs $userAloja@'; sudo mount $homePrefixAloja/$userAloja/share; sudo mount -a; }"
#
#  for mount_point in "$homePrefixAloja/$userAloja/share" "/scratch/attached/1" "/scratch/attached/2" "/scratch/attached/3" ; do
#    echo "Checking if to remount $mount_point"
#    $DSH "[[ ! \"\$(mount |grep '$mount_point'| grep 'rw,' )\" || \"\$(touch $mount_point/touch )\" ]] && { echo 'ERROR: $mount_point not mounted correctly'; sudo umount -f $mount_point; sudo mount $mount_point; }"
#  done
#
#  correctly_mounted_nodes=$($DSH "ls ~/share/safe_store 2> /dev/null" |wc -l)
#
#  if [ "$correctly_mounted_nodes" != "$(( NUMBER_OF_DATA_NODES + 1 ))" ] ; then
#    echo "ERROR, share directory is not mounted correctly.  Only $correctly_mounted_nodes OK. Rebooting servers and sleeping 90s ..."
#    exit 1
#    #$DSH_SLAVES "sudo reboot" 2>&1 |tee -a $LOG_PATH
#    #sleep 90 2>&1 |tee -a $LOG_PATH
#  fi
#
#  if [ "$correctly_mounted_nodes" != "$(( NUMBER_OF_DATA_NODES + 1 ))" ] ; then
#    echo "ERROR, share directory is not mounted correctly.  Only $correctly_mounted_nodes OK. Exiting..."
#    echo "DEBUG: Correct $correctly_mounted_nodes NUMBER_OF_DATA_NODES $NUMBER_OF_DATA_NODES + 1"
#    exit 1
#  fi
#fi

#create dir to save files in one host
$DSH_MASTER "mkdir -p $JOB_PATH"
$DSH_MASTER "touch $LOG_PATH"

logger(){
  stamp=$(date '+%s')
  echo -e "${stamp} : $1" 2>&1 |tee -a $LOG_PATH
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}


logger "Setting scratch permissions"
$DSH "sudo chown -R $userAloja: /scratch"

#only copy files if version has changed (to save time in azure)
logger "Checking if to generate source dirs"
for node in $node_names ; do
  logger " for host $node"
  if [ "$(ssh "$node" "[ "\$\(cat $BASE_DIR/aplic/aplic_version\)" == "\$\(cat $SOURCE_DIR/aplic_version 2\> /dev/null \)" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
    logger "At least host $node did not have source dirs. Generating source dirs for ALL hosts"
    $DSH "mkdir -p $SOURCE_DIR; rsync -aur --force $BASE_DIR/aplic/* $SOURCE_DIR/"
    break #dont need to check after one is missing
  else
    logger " Host $node up to date"
  fi
done


#if [ "$(cat $BASE_DIR/aplic/aplic_version)" != "$(cat $SOURCE_DIR/aplic_version)" ] ; then
#  logger "Generating source dirs"
#  $DSH "mkdir -p $SOURCE_DIR; cp -ru $BASE_DIR/aplic/* $SOURCE_DIR/"
#  #$DSH "cp -ru $SOURCE_DIR/${HADOOP_VERSION}-home $SOURCE_DIR/${HADOOP_VERSION}" #rm -rf $SOURCE_DIR/${HADOOP_VERSION};
#else
#  logger "Source dirs up to date"
#fi

zabbix_sender(){
  :
  #echo "al-1001 $1" | $homePrefixAloja/pristine/share/aplic/zabbix/bin/zabbix_sender -c $homePrefixAloja/pristine/share/aplic/zabbix/conf/zabbix_agentd_az.conf -T -i - 2>&1 > /dev/null
  #>> $LOG_PATH
}

logger "Job name: $JOB_NAME"
logger "Job path: $JOB_PATH"
logger "Log path: $LOG_PATH"
logger "Disk location: $HDD"
logger "TMP Disk location: $HDD_TMP"
logger "Conf: $CONF"
logger "HiBench: $HIB_DIR"
logger "Benchs to execute: $LIST_BENCHS"
logger "DSH: $DSH"
logger ""

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
#$DSH_MASTER $H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH

#prepare selected conf
#$DSH "rm -rf $DIR/conf/*" 2>&1 |tee -a $LOG_PATH
#$DSH "cp -r $DIR/$CONF/* $DIR/conf/" 2>&1 |tee -a $LOG_PATH


prepare_config(){

  logger "Preparing exe dir"

  if [ "$DELETE_HDFS" == "1" ] ; then
     logger "Deleting previous PORT files"
     $DSH "rm -rf $HDD/* $HDD_TMP/* " 2>&1 |tee -a $LOG_PATH
$DSH "rm -rf /scratch/attached/{1..8}/$(get_aloja_dir "$PORT_PREFIX")" 2>&1 |tee -a $LOG_PATH
  else
     $DSH "rm -rf $HDD/{aplic,logs} $HDD_TMP/{aplic,logs}" 2>&1 |tee -a $LOG_PATH
  fi

  logger "Creating source dir and Copying Hadoop"
#$DSH "mkdir -p /scratch/attached/{1,2,3}/$(get_aloja_dir "$PORT_PREFIX")/{aplic,hadoop,logs}" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $HDD/{aplic,hadoop,logs} $HDD_TMP/{aplic,hadoop,logs}" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $H_DIR" 2>&1 |tee -a $LOG_PATH

echo -e "HDD=$HDD\nHDD_TMP $HDD_TMP\nHDIR=${H_DIR}"

  $DSH "cp -ru $SOURCE_DIR/${HADOOP_VERSION}/* $H_DIR/" 2>&1 |tee -a $LOG_PATH

  vmstat="$HDD/aplic/vmstat_$PORT_PREFIX"
  bwm="$HDD/aplic/bwm-ng_$PORT_PREFIX"
  sar="$HDD/aplic/sar_$PORT_PREFIX"

  $DSH "cp /usr/bin/vmstat $vmstat" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $bwm_source $bwm" 2>&1 |tee -a $LOG_PATH
  $DSH "cp /usr/bin/sar $sar" 2>&1 |tee -a $LOG_PATH

  logger "Preparing config"

  $DSH "rm -rf $H_DIR/conf/*" 2>&1 |tee -a $LOG_PATH

  MASTER="$master_name"

  IO_MB="$((IO_FACTOR * 10))"

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

logger "DEBUG: HDFS_NDIR: $HDFS_NDIR\nHDFS_DDIR: $HDFS_DDIR"


MAX_REDS="$MAX_MAPS"

subs=$(cat <<EOF
s,##JAVA_HOME##,$JAVA_HOME,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
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
EOF
)

slaves="$(get_slaves_names)"


  #to avoid perl warnings
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  $DSH "cp $H_DIR/conf_template/* $H_DIR/conf/" 2>&1 |tee -a $LOG_PATH

  $DSH "/usr/bin/perl -pe \"$subs\" $H_DIR/conf_template/hadoop-env.sh > $H_DIR/conf/hadoop-env.sh" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $H_DIR/conf_template/core-site.xml > $H_DIR/conf/core-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $H_DIR/conf_template/hdfs-site.xml > $H_DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $H_DIR/conf_template/mapred-site.xml > $H_DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH

  logger "Replacing per host config"

  for node in $node_names ; do
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $H_DIR/conf/mapred-site.xml > $H_DIR/conf/mapred-site.xml.tmp; rm $H_DIR/conf/mapred-site.xml; mv $H_DIR/conf/mapred-site.xml.tmp $H_DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH &
    ssh "$node" "/usr/bin/perl -pe \"s,##HOST##,$node,g;\" $H_DIR/conf/hdfs-site.xml > $H_DIR/conf/hdfs-site.xml.tmp; rm $H_DIR/conf/hdfs-site.xml; mv $H_DIR/conf/hdfs-site.xml.tmp $H_DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH &
  done

  $DSH "echo -e \"$MASTER\" > $H_DIR/conf/masters" 2>&1 |tee -a $LOG_PATH
  $DSH "echo -e \"$slaves\" > $H_DIR/conf/slaves" 2>&1 |tee -a $LOG_PATH


  #save config
  logger "Saving config"
  create_conf_dirs=""
  for node in $node_names ; do
    create_conf_dirs="$create_conf_dirs mkdir -p $JOB_PATH/conf_$node ;"
  done

  $DSH "$create_conf_dirs" 2>&1 |tee -a $LOG_PATH

  for node in $node_names ; do
    ssh "$node" "cp $H_DIR/conf/* $JOB_PATH/conf_$node" 2>&1 |tee -a $LOG_PATH &
  done
}

prepare_config ${NET} ${DISK} ${BENCH}

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
  logger "Restart Hadoop"
  #just in case stop all first
  $DSH_MASTER $H_DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH

  #delete previous run logs
  $DSH "rm -rf $HDD/logs; mkdir -p $HDD/logs" 2>&1 |tee -a $LOG_PATH

  if [ "$DELETE_HDFS" == "1" ] ; then
    logger "Deleting previous Hadoop HDFS"

    $DSH "rm -rf $HDD/{dfs,mapred,logs} $HDD_TMP/{dfs,mapred,logs}; mkdir -p $HDD/logs $HDD_TMP/;" 2>&1 |tee -a $LOG_PATH
#TODO fix for variable paths
$DSH "rm -rf /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/{dfs,mapred,logs}" 2>&1 |tee -a $LOG_PATH
$DSH "mkdir -p /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/dfs/data; chmod 755 /scratch/attached/{1..$BENCH_MAX_DISKS}/$(get_aloja_dir "$PORT_PREFIX")/dfs/data;" 2>&1 |tee -a $LOG_PATH
$DSH "mkdir -p /scratch/local/$(get_aloja_dir "$PORT_PREFIX")/dfs/data; chmod 755 /scratch/local/$(get_aloja_dir "$PORT_PREFIX")/dfs/data" 2>&1 |tee -a $LOG_PATH

    #yes Y | send multiple yes to format
    logger "Formating datanodes"
    $DSH "yes Y | $H_DIR/bin/hadoop datanode -format" 2>&1 |tee -a $LOG_PATH

    logger "Formating namenode"
    $DSH_MASTER "yes Y | $H_DIR/bin/hadoop namenode -format" 2>&1 |tee -a $LOG_PATH

  fi

  $DSH_MASTER $H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH

  for i in {0..300}
  do
    local report=$($DSH_MASTER $H_DIR/bin/hadoop dfsadmin -report 2> /dev/null)
    local num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
    local safe_mode=$(echo "$report" | grep "Safe mode is ON")
    echo $report 2>&1 |tee -a $LOG_PATH

    if [ "$num" == "$NUMBER_OF_DATA_NODES" ] ; then
      if [[ -z $safe_mode ]] ; then
        #everything fine continue
        break
      elif [ "$i" == "30" ] ; then
        logger "Still in Safe mode, MANUALLY RESETTING SAFE MODE wating for $i seconds"
        $DSH_MASTER $H_DIR/bin/hadoop dfsadmin -safemode leave 2>&1 |tee -a $LOG_PATH
      else
        logger "Still in Safe mode, wating for $i seconds"
      fi
    elif [ "$i" == "60" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      $DSH_MASTER $H_DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
      $DSH_MASTER $H_DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH
    elif [ "$i" == "180" ] && [[ -z $1 ]] ; then
      #try to restart hadoop deleting files and prepare again files
      logger "Reseting config to retry DELETE_HDFS WAS SET TO: $DELETE_HDFS"
      DELETE_HDFS="1"
      restart_hadoop no_retry
    elif [ "$i" == "120" ] ; then
      logger "$num/$NUMBER_OF_DATA_NODES Datanodes available, EXIT"
      exit 1
    else
      logger "$num/$NUMBER_OF_DATA_NODES Datanodes available, wating for $i seconds"
      sleep 1
    fi
  done

  logger "Hadoop ready"
}

restart_monit(){
  logger "Restart Monit"

  stop_monit

  $DSH "$vmstat -n 1 >> $HDD/vmstat-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  $DSH "$bwm -o csv -I bond0,eth0,eth1,eth2,eth3,ib0,ib1 -u bytes -t 1000 >> $HDD/bwm-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  $DSH "$sar -o $HDD/sar-\$(hostname).sar 1 >/dev/null 2>&1 &" 2>&1 |tee -a $LOG_PATH

  logger "Monit ready"
}

stop_hadoop(){
  logger "Stop Hadoop"
  $DSH_MASTER $H_DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
  logger "Stop Hadoop ready"
}

stop_monit(){
  logger "Stop monit"
  $DSH "killall -9 $vmstat" #2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 $bwm" #2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 $sar" #2>&1 >> $LOG_PATH

  logger "Stop monit ready"
}

save_bench() {
  logger "Saving benchmark $1"
  $DSH "mkdir -p $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $HDD_TMP/{bwm,vmstat}*.log $HDD_TMP/sar*.sar $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  $DSH "cp -r $HDD/logs/* $HDD_TMP/logs/* $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $HDD/logs/job*.xml $HDD_TMP/logs/job*.xml $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
  #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  cp "$HIB_DIR/$bench/hibench.report" "$JOB_PATH/$1/"

  #logger "Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH" 2>&1 |tee -a $LOG_PATH
  #pending, delete

  logger "Compresing and deleting $1"

  $DSH_MASTER "cd $JOB_PATH; tar -cjf $JOB_PATH/$1.tar.bz2 $1;" 2>&1 |tee -a $LOG_PATH
  tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  $DSH_MASTER "rm -rf $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #$JOB_PATH/conf_* #TODO check

  #empy the contents from original disk  TODO check if still necessary
  $DSH "for i in $HDD/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH
  $DSH "for i in $HDD_TMP/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH

  logger "Done saving benchmark $1"
}

#before running hibench, set exports and vars
EXP="export JAVA_HOME=$JAVA_HOME && \
export HADOOP_HOME=$H_DIR && \
export COMPRESS_GLOBAL=$COMPRESS_GLOBAL && \
export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL && \
export NUM_MAPS=$MAX_MAPS && \
export NUM_REDS=$MAX_MAPS && \
"

execute_bench(){
  #clear buffer cache exept for prepare
#  if [[ -z $3 ]] ; then
#    logger "Clearing Buffer cache"
#    $DSH "sudo /usr/local/sbin/drop_caches" 2>&1 |tee -a $LOG_PATH
#  fi

  logger "# Checking disk space with df BEFORE"
  $DSH "df -h" 2>&1 |tee -a $LOG_PATH
  logger "# Checking hadoop folder space BEFORE"
  $DSH "du -sh $HDD/*" 2>&1 |tee -a $LOG_PATH

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec=$(date '+%s')  && echo "start $start_exec end $end_exec" 2>&1 |tee -a $LOG_PATH
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S') && echo "end $start_date" 2>&1 |tee -a $LOG_PATH
  logger "# EXECUTING ${3}${1}"

  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${3}${1} %e' $2" 2>&1 |tee -a $LOG_PATH

  local end_exec=$(date '+%s') && echo "start $start_exec end $end_exec" 2>&1 |tee -a $LOG_PATH

  logger "# DONE EXECUTING $1"

  local total_secs=$(expr $end_exec - $start_exec) &&  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s." 2>&1 |tee -a $LOG_PATH
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."


  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    logger "Saving $3 to disk"
    $DSH_MASTER $H_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $SAVE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

  stop_monit

  logger "# Checking disk space with df AFTER"
  $DSH "df -h" 2>&1 |tee -a $LOG_PATH
  logger "# Checking hadoop folder space AFTER"
  $DSH "du -sh $HDD/*" 2>&1 |tee -a $LOG_PATH

  save_bench "${3}${1}"
}


start_time=$(date '+%s')

########################################################
logger "Starting execution of HiBench"


##PREPARED="/scratch/local/ssd/pristine/prepared"
#"wordcount" "sort" "terasort" "kmeans" "pagerank" "bayes" "nutchindexing" "hivebench" "dfsioe"
#  "nutchindexing"


for bench in $(echo "$LIST_BENCHS")
do
  restart_hadoop

  #Delete previous data
  #$DSH_MASTER "${H_DIR}/bin/hadoop fs -rmr /HiBench" 2>&1 |tee -a $LOG_PATH
  echo "" > "$HIB_DIR/$bench/hibench.report"

  #just in case check if the input file exists in hadoop
  if [ "$DELETE_HDFS" == "0" ] ; then
    get_bench_name $bench
    input_exists=$($DSH_MASTER $H_DIR/bin/hadoop fs -ls "/HiBench/$full_name/Input" 2> /dev/null |grep "Found ")

    if [ "$input_exists" != "" ] ; then
      logger "Input folder seems OK"
    else
      logger "Input folder does not exist, RESET and RESTART"
      $DSH_MASTER $H_DIR/bin/hadoop fs -ls "/HiBench/$full_name/Input" 2>&1 |tee -a $LOG_PATH
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
        execute_bench $bench $HIB_DIR/$bench/bin/prepare.sh "prep_"
      elif [ "$bench" == "dfsioe" ] ; then
        execute_bench $bench $HIB_DIR/$bench/bin/prepare-read.sh "prep_"
      fi
    else
      logger "Reusing previous RUN prepared $bench"
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

  logger "$(date +"%H:%M:%S") RUNNING $bench"

  if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then
    execute_bench $bench $HIB_DIR/$bench/bin/run.sh
  elif [ "$bench" == "hivebench" ] ; then
    execute_bench hivebench_agregation $HIB_DIR/hivebench/bin/run-aggregation.sh
    execute_bench hivebench_join $HIB_DIR/hivebench/bin/run-join.sh
  elif [ "$bench" == "dfsioe" ] ; then
    execute_bench dfsioe_read $HIB_DIR/dfsioe/bin/run-read.sh
    execute_bench dfsioe_write $HIB_DIR/dfsioe/bin/run-write.sh
  fi

done
logger "$(date +"%H:%M:%S") DONE $bench"

#clean output data
get_bench_name $bench
$DSH_MASTER "${H_DIR}/bin/hadoop fs -rmr /HiBench/$full_name/Output"


########################################################
end_time=$(date '+%s')

#clean up
stop_hadoop
stop_monit


#copy
$DSH "cp $HDD/* $HDD_TMP/* $JOB_PATH/"


#report
#finish_date=`$DATE`
#total_time=`expr $(date '+%s') - $(date '+%s')`
#$(touch ${JOB_PATH}/finish_${finish_date})
#$(touch ${JOB_PATH}/total_${total_time})
du -h $JOB_PATH|tail -n 1
logger "DONE, total time $total_time seconds. Path $JOB_PATH"