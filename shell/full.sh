#!/bin/bash
# SCRIPT TO STOP, SET CONFIG, AND START HADOOP

[ $# -lt 2 ] && { echo "Usage: $0 eth|ib ssd|hdd [_min|_10] [_m4|_m8|_m16|_m24]" ; exit 1; }


DIR="/scratch/ssd/npoggi/aplic/hadoop-1.0.3-scratch"

DATE='date +%Y%m%d_%H%M%S'
CONF="conf_$1_${2}${4}"
JOB_NAME="`$DATE`_$CONF"
JOB_PATH="/home/$USER/jobs/var/$JOB_NAME"
LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
LOG="2>&1 |tee -a $LOG_PATH"

#####
export HADOOP_HOME="$DIR"
export JAVA_HOME="/scratch/ssd/npoggi/aplic/jdk1.7.0_25"
HADOOP_DIR=$HADOOP_HOME
HIB_DIR="/scratch/ssd/npoggi/aplic/HiBench$3/"
#####

if [ "$1" == "ib" ] ; then
  host1="minerva-1001-ib0"
  host2="minerva-1002-ib0"
  host3="minerva-1003-ib0"
  host4="minerva-1004-ib0"
  IFACE="ib0"
else
  host1="minerva-1001"
  host2="minerva-1002"
  host3="minerva-1003"
  host4="minerva-1004"
  IFACE="bon0"
fi

DSH="dsh -m $host1,$host2,$host3,$host4"
DSH_MASTER="ssh $host1"
DSH_SLAVE="ssh $host4"


#create dir to save files in one host
$DSH_MASTER "mkdir -p $JOB_PATH" 
$DSH_MASTER "touch $LOG_PATH"

if [ "$2" == "ssd" ] ; then
  HDD="/scratch/ssd/npoggi/hadoop"
else
  HDD="/users/scratch/npoggi/hadoop"
fi

echo ": Job name: $JOB_NAME" 
echo ": Job path: $JOB_PATH" 2>&1 |tee -a $LOG_PATH
echo ": Log path: $LOG_PATH" 2>&1 |tee -a $LOG_PATH
echo ": Disk location: $HDD"  2>&1 |tee -a $LOG_PATH
echo ": Conf: $CONF" 2>&1 |tee -a $LOG_PATH
echo ": HiBench: $HIB_DIR" 2>&1 |tee -a $LOG_PATH
echo ": DSH: $DSH" 2>&1 |tee -a $LOG_PATH
echo ": " 2>&1 |tee -a $LOG_PATH

#stop running instances with the previous conf
$DSH_MASTER $DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH

#prepare selected conf
#$DSH "rm -rf $DIR/conf/*" 2>&1 |tee -a $LOG_PATH
#$DSH "cp -r $DIR/$CONF/* $DIR/conf/" 2>&1 |tee -a $LOG_PATH

prepare_config(){

  echo ": Preparing config"

  $DSH "rm -rf $DIR/conf/*" 2>&1 |tee -a $LOG_PATH

  if [ ! -z "$4" ] ; then
    max_maps="$4"
  else
    max_maps="24"
  fi

  MASTER="$host1"
  IO_FACTOR="10"
  IO_MB="100"

subs=$(cat <<EOF
s,##JAVA_HOME##,$JAVA_HOME,g;
s,##LOG_DIR##,$HDD,g;
s,##REPLICATION##,1,g;
s,##MASTER##,$MASTER,g;
s,##NAMENODE##,$MASTER,g;
s,##TMP_DIR##,$HDD,g;
s,##MAX_MAPS##,$max_maps,g;
s,##MAX_REDS##,$max_maps,g;
s,##IFACE##,$IFACE,g;
s,##IO_FACTOR##,$IO_FACTOR,g;
s,##IO_MB##,$IO_MB,g;
EOF
)

slaves=$(cat <<EOF
$host2
$host3
$host4
EOF
)


  #to avoid perl warnings
  export LC_CTYPE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  $DSH "/usr/bin/perl -pe \"$subs\" $DIR/conf_template/hadoop-env.sh > $DIR/conf/hadoop-env.sh" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $DIR/conf_template/core-site.xml > $DIR/conf/core-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $DIR/conf_template/hdfs-site.xml > $DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  $DSH "/usr/bin/perl -pe \"$subs\" $DIR/conf_template/mapred-site.xml > $DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH

  ssh $host1 "/usr/bin/perl -pe \"s,##HOST##,$host1,g;\" $DIR/conf/mapred-site.xml > $DIR/conf/mapred-site.xml.tmp; rm $DIR/conf/mapred-site.xml; mv $DIR/conf/mapred-site.xml.tmp $DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host2 "/usr/bin/perl -pe \"s,##HOST##,$host2,g;\" $DIR/conf/mapred-site.xml > $DIR/conf/mapred-site.xml.tmp; rm $DIR/conf/mapred-site.xml; mv $DIR/conf/mapred-site.xml.tmp $DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host3 "/usr/bin/perl -pe \"s,##HOST##,$host3,g;\" $DIR/conf/mapred-site.xml > $DIR/conf/mapred-site.xml.tmp; rm $DIR/conf/mapred-site.xml; mv $DIR/conf/mapred-site.xml.tmp $DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host4 "/usr/bin/perl -pe \"s,##HOST##,$host4,g;\" $DIR/conf/mapred-site.xml > $DIR/conf/mapred-site.xml.tmp; rm $DIR/conf/mapred-site.xml; mv $DIR/conf/mapred-site.xml.tmp $DIR/conf/mapred-site.xml" 2>&1 |tee -a $LOG_PATH

  ssh $host1 "/usr/bin/perl -pe \"s,##HOST##,$host1,g;\" $DIR/conf/hdfs-site.xml > $DIR/conf/hdfs-site.xml.tmp; rm $DIR/conf/hdfs-site.xml; mv $DIR/conf/hdfs-site.xml.tmp $DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host2 "/usr/bin/perl -pe \"s,##HOST##,$host2,g;\" $DIR/conf/hdfs-site.xml > $DIR/conf/hdfs-site.xml.tmp; rm $DIR/conf/hdfs-site.xml; mv $DIR/conf/hdfs-site.xml.tmp $DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host3 "/usr/bin/perl -pe \"s,##HOST##,$host3,g;\" $DIR/conf/hdfs-site.xml > $DIR/conf/hdfs-site.xml.tmp; rm $DIR/conf/hdfs-site.xml; mv $DIR/conf/hdfs-site.xml.tmp $DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH
  ssh $host4 "/usr/bin/perl -pe \"s,##HOST##,$host4,g;\" $DIR/conf/hdfs-site.xml > $DIR/conf/hdfs-site.xml.tmp; rm $DIR/conf/hdfs-site.xml; mv $DIR/conf/hdfs-site.xml.tmp $DIR/conf/hdfs-site.xml" 2>&1 |tee -a $LOG_PATH


  $DSH "echo -e \"$MASTER\" > $DIR/conf/masters" 2>&1 |tee -a $LOG_PATH
  $DSH "echo -e \"$slaves\" > $DIR/conf/slaves" 2>&1 |tee -a $LOG_PATH
}

prepare_config $1 $2 $3

#save config
$DSH_MASTER "mkdir -p $JOB_PATH/conf_$host1 $JOB_PATH/conf_$host2 $JOB_PATH/conf_$host3 $JOB_PATH/conf_$host4" 2>&1 |tee -a $LOG_PATH
ssh $host1 "cp $DIR/conf/* $JOB_PATH/conf_$host1" 2>&1 |tee -a $LOG_PATH
ssh $host2 "cp $DIR/conf/* $JOB_PATH/conf_$host2" 2>&1 |tee -a $LOG_PATH
ssh $host3 "cp $DIR/conf/* $JOB_PATH/conf_$host3" 2>&1 |tee -a $LOG_PATH
ssh $host4 "cp $DIR/conf/* $JOB_PATH/conf_$host4" 2>&1 |tee -a $LOG_PATH


restart_hadoop(){
  echo ": Restart Hadoop" 2>&1 |tee -a $LOG_PATH
  $DSH_MASTER $DIR/bin/stop-all.sh 2>&1 >> $LOG_PATH
  $DSH "rm -rf $HDD" 2>&1 |tee -a $LOG_PATH
  $DSH "mkdir -p $HDD" 2>&1 |tee -a $LOG_PATH
  $DSH_MASTER "echo \"Y\" |$DIR/bin/hadoop namenode -format" 2>&1 |tee -a $LOG_PATH
  $DSH_MASTER $DIR/bin/start-all.sh 2>&1 |tee -a $LOG_PATH

  for i in {0..180} #3mins
  do
    report=$($DSH_MASTER $DIR/bin/hadoop dfsadmin -report 2> /dev/null)    
    num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
    echo $report 2>&1 |tee -a $LOG_PATH     
    
    #TODO make number of nodes aware
    if [ "$num" == "3" ] ; then
      break
    elif [ "$i" == "180" ] ; then
      echo ": $num/3 Datanodes available, EXIT" 2>&1 |tee -a $LOG_PATH
      exit 1     
    else
      echo ": $num/3 Datanodes available, wating for $i seconds" 2>&1 |tee -a $LOG_PATH
      sleep 1
    fi  
  done

  echo ": Hadoop Ready" 2>&1 |tee -a $LOG_PATH  
}

restart_monit(){
  echo ": Restart Monit" 2>&1 |tee -a $LOG_PATH
  bwm="/scratch/ssd/npoggi/aplic/sge-hadoop-jobs/bin/bwm-ng"
  $DSH "killall -9 vmstat" 2>&1 >> $LOG_PATH
  $DSH "killall -9 $bwm" 2>&1 >> $LOG_PATH
  $DSH "/usr/bin/vmstat -n 1 >> $HDD/vmstat-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  $DSH "$bwm -o csv -I bond0,eth0,eth1,eth2,eth3,ib0,ib1 -u bytes -t 1000 >> $HDD/bwm-\$(hostname).log &" 2>&1 |tee -a $LOG_PATH
  echo ": Monit ready" 2>&1 |tee -a $LOG_PATH
}

stop_hadoop(){
  echo ": Stop Hadoop" 2>&1 |tee -a $LOG_PATH
  $DSH_MASTER $DIR/bin/stop-all.sh 2>&1 |tee -a $LOG_PATH
  echo ": Stop Hadoop reay" 2>&1 |tee -a $LOG_PATH
}

stop_monit(){
  echo ": Stop monit" 2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 vmstat" 2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 $bwm" 2>&1 |tee -a $LOG_PATH
  echo ": Stop monit ready" 2>&1 |tee -a $LOG_PATH
}

save_bench() {
  echo ": Saving benchmark $1" 2>&1 |tee -a $LOG_PATH
  $DSH_MASTER "mkdir -p $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  $DSH "mv $HDD/{bwm,vmstat}*.log $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  $DSH "cp $HDD/hadoop-*.{log,out}* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $DIR/conf/* $JOB_PATH/$1" 2>&1 |tee -a $LOG_PATH

  #empy the contents then
  $DSH "for i in $HDD/hadoop-*.{log,out}; do echo "" > $i; done;" 2>&1 |tee -a $LOG_PATH
  cp "${HIB_DIR}$bench/hibench.report" "$JOB_PATH/$1/"  
  echo ": Done saving benchmark $1" 2>&1 |tee -a $LOG_PATH
}


start_time=$(date +%s)


EXP="export JAVA_HOME=$JAVA_HOME &&  export HADOOP_HOME=$DIR && "

########################################################
echo "Starting execution of HiBench" 2>&1 |tee -a $LOG_PATH


##PREPARED="/scratch/ssd/npoggi/prepared"
#"wordcount" "sort" "terasort" "kmeans" "pagerank" "bayes" "nutchindexing" "hivebench" "dfsioe"
#  "nutchindexing" 
for bench in "kmeans" "bayes"
do
  restart_hadoop

  #Delete previous data
  $DSH_MASTER "${HADOOP_DIR}/bin/hadoop fs -rmr /HiBench" 2>&1 |tee -a $LOG_PATH
  echo "" > "${HIB_DIR}$bench/hibench.report"
  
  echo "# $(date +"%H:%M:%S") STARTING $bench" 2>&1 |tee -a $LOG_PATH
  ##mkdir -p "$PREPARED/$bench"

  #if [ ! -f "$PREPARED/${i}.tbza" ] ; then  
  
    #hive leaves tmp config files
    if [ "$bench" != "hivebench" ] ; then 
      $DSH_MASTER "rm /tmp/hive* /tmp/npoggi/hive*" 2>&1 |tee -a $LOG_PATH      
    fi  
    
    echo "# $(date +"%H:%M:%S") PREPARING $bench" 2>&1 |tee -a $LOG_PATH    
    restart_monit
    
    if [ "$bench" != "dfsioe" ] ; then 
      $DSH_SLAVE "$EXP /usr/bin/time -f 'Time prep $bench %e' ${HIB_DIR}$bench/bin/prepare.sh" 2>&1 |tee -a $LOG_PATH
    elif [ "$bench" == "dfsioe" ] ; then    
      $DSH_SLAVE "$EXP /usr/bin/time -f 'Time prep $bench %e' ${HIB_DIR}$bench/bin/prepare-read.sh" 2>&1 |tee -a $LOG_PATH
    fi
    
    stop_monit
    save_bench "prep_$bench"    
  
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
  
  echo "# $(date +"%H:%M:%S") RUNNING $bench" 2>&1 |tee -a $LOG_PATH

  if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then 
     restart_monit
     $DSH_SLAVE "$EXP /usr/bin/time -f 'Time run $bench %e'  ${HIB_DIR}$bench/bin/run.sh" 2>&1 |tee -a $LOG_PATH     
     stop_monit
     save_bench "run_$bench"
  elif [ "$bench" == "hivebench" ] ; then
    restart_monit
    $DSH_SLAVE "$EXP /usr/bin/time -f 'Time run hivebench_agregation %e'  ${HIB_DIR}hivebench/bin/run-aggregation.sh" 2>&1 |tee -a $LOG_PATH     
    stop_monit
    save_bench "run_${bench}_agregation"
    restart_monit
    $DSH_SLAVE "$EXP /usr/bin/time -f 'Time run hivebench_join %e'  ${HIB_DIR}hivebench/bin/run-join.sh" 2>&1 |tee -a $LOG_PATH     
    stop_monit
    save_bench "run_${bench}_join"
  elif [ "$bench" == "dfsioe" ] ; then
    restart_monit
    $DSH_SLAVE "$EXP /usr/bin/time -f 'Time run dfsioe_read %e'  ${HIB_DIR}dfsioe/bin/run-read.sh" 2>&1 |tee -a $LOG_PATH     
    stop_monit
    save_bench "run_${bench}_read"
    restart_monit
    $DSH_SLAVE "$EXP /usr/bin/time -f 'Time run dfsioe_write %e'  ${HIB_DIR}dfsioe/bin/run-write.sh" 2>&1 |tee -a $LOG_PATH     
    stop_monit
    save_bench "run_${benchi}_write"
  fi

done
echo "# $(date +"%H:%M:%S") DONE $bench"

#clean data
$DSH_MASTER ${HADOOP_DIR}/bin/hadoop fs -rmr /HiBench


########################################################
end_time=$(date +%s)

#clean up
stop_hadoop
stop_monit


#copy
$DSH "cp $HDD/* $JOB_PATH/"


#report
finish_date=`$DATE`
total_time=`expr $(date +%s) - $(date +%s)`
$(touch ${JOB_PATH}/finish_${finish_date})
$(touch ${JOB_PATH}/total_${total_time})
du -h $JOB_PATH|tail -n 1
echo "DONE, total time $total_time seconds. Path $JOB_PATH"	

