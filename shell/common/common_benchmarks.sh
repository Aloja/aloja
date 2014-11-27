loggerb(){
  stamp=$(date '+%s')
  echo "${stamp} : $1" 2>&1 |tee -a $LOG_PATH
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}

get_date_folder(){
  echo date +%Y%m%d_%H%M%S
}

zabbix_sender(){
  :
  #echo "al-1001 $1" | /home/pristine/share/aplic/zabbix/bin/zabbix_sender -c /home/pristine/share/aplic/zabbix/conf/zabbix_agentd_az.conf -T -i - 2>&1 > /dev/null
  #>> $LOG_PATH
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
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $JOB_PATH/$1/" 2>&1 |tee -a $LOG_PATH
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

prepare_config(){

  loggerb "Preparing exe dir"
     loggerb "Deleting previous PORT files"
     $DSH "rm -rf $HDD/*" 2>&1 |tee -a $LOG_PATH


  loggerb "Creating source dir"

  $DSH "mkdir -p $HDD/aplic" 2>&1 |tee -a $LOG_PATH

  $DSH "cp /usr/bin/vmstat $vmstat" 2>&1 |tee -a $LOG_PATH
  $DSH "cp $bwm_source $bwm" 2>&1 |tee -a $LOG_PATH
  $DSH "cp /usr/bin/sar $sar" 2>&1 |tee -a $LOG_PATH
}

execute_sleep() {
  loggerb "Executing sleep in all nodes"

  restart_monit

  for sleep_iterator in {1..5} ; do
    loggerb "Sleeping zzZZZzzz $sleep_iterator"
    $DSH "sleep 1"
  done
  loggerb "DONE executing sleep"

  stop_monit
}