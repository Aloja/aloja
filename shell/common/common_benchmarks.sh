loggerb(){
  stamp=$(date '+%s')
  echo "${stamp} : $1" 2>&1 |tee -a $LOG_PATH
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}

zabbix_sender(){
  :
  #echo "al-1001 $1" | /home/pristine/share/aplic/zabbix/bin/zabbix_sender -c /home/pristine/share/aplic/zabbix/conf/zabbix_agentd_az.conf -T -i - 2>&1 > /dev/null
  #>> $LOG_PATH
}

restart_monit(){
  loggerb "Restarting Monit"

  stop_monit

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

execute_bench(){
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


  #save the prepare
  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
    loggerb "Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER $BENCH_H_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION 2>&1 |tee -a $LOG_PATH
  fi

  stop_monit

  loggerb "# Checking disk space with df AFTER"
  $DSH "df -h" 2>&1 |tee -a $LOG_PATH
  loggerb "# Checking hadoop folder space AFTER"
  $DSH "du -sh $HDD/*" 2>&1 |tee -a $LOG_PATH

  save_bench "${3}${1}"
}

execute_sleep() {
  loggerb "Executing sleep in all nodes"

  restart_monit

  for sleep_iterator in {1..20} ; do
    loggerb "Sleeping zzZZZzzz $sleep_iterator"
    $DSH "sleep 1"
  done
  loggerb "DONE executing sleep"

  stop_monit
}
