CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load hadoop defaults
source "$CONF_DIR/common_hadoop.sh"


benchmark_config() {
  prepare_hadoop_config ${NET} ${DISK} ${BENCH}
  export HIVE_PATH="$BENCH_SOURCE_DIR/apache-hive-0.13.1-bin"
  export MAHOUT_PATH="$BENCH_SOURCE_DIR/mahout-distribution-0.9"
}

benchmark_run() {
  restart_hadoop

  restart_monit

  local start_exec=`timestamp`
  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
  loggerb "# EXECUTING ${BENCH}"

  #need to send all the environment variables over SSH
  EXP="export BIG_BENCH_JAVA=$JAVA_HOME/bin/java && \
export BIG_BENCH_HADOOP_CONF=$BENCH_H_DIR/etc/hadoop && \
export BIG_BENCH_HADOOP_LIBS_NATIVE=$BENCH_H_DIR/lib/native && \
export BIG_BENCH_LOGS_DIR=$HDD/logs && \
export JAVA_HOME=$JAVA_HOME && \
export PATH=\"$BENCH_H_DIR/bin:$MAHOUT_PATH/bin:$PATH\" && \
export HIVE_BINARY=\"$HIVE_PATH/bin/hive\" && \
"

  $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${BENCH} %e' $BENCH_HIB_DIR/bin/bigBench runBenchmark -m 2 -f 1 -s 2" 2>&1 |tee -a $LOG_PATH

  # $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${BENCH} %e' $BENCH_HIB_DIR/bin/bigBench dataGen -m 2 -f 1 -b" 2>&1 |tee -a $LOG_PATH
  # $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${BENCH} %e' $BENCH_HIB_DIR/bin/bigBench populateMetastore -b" 2>&1 |tee -a $LOG_PATH
  # $DSH_MASTER "$EXP /usr/bin/time -f 'Time ${BENCH} %e' $BENCH_HIB_DIR/bin/bigBench runQuery -q 5 -b" 2>&1 |tee -a $LOG_PATH

  local end_exec=`timestamp`

  loggerb "# DONE EXECUTING ${BENCH}"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  echo "end total sec $total_secs" 2>&1 |tee -a $LOG_PATH

  # Save execution information in an array to allow import later
  EXEC_TIME[${BENCH}]="$total_secs"
  EXEC_START[${BENCH}]="$start_exec"
  EXEC_END[${BENCH}]="$end_exec"

  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  echo "SENDING: hibench.runs $end_exec <a href='$url'>${BENCH} $CONF</a> <strong>Time:</strong> $total_secs s." 2>&1 |tee -a $LOG_PATH
  zabbix_sender "hibench.runs $end_exec <a href='$url'>${BENCH} $CONF</a> <strong>Time:</strong> $total_secs s."

  stop_monit

  save_hadoop "${BENCH}"
}

benchmark_teardown() {
  : # Empty
}

benchmark_save() {
  : # Empty
}

benchmark_cleanup() {
  stop_hadoop
}