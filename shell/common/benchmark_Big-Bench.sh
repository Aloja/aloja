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