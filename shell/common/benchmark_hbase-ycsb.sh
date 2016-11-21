# Benchmark to test HBase installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_hbase.sh"
set_hbase_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_ycsb.sh"
set_ycsb_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
#[ ! "$BENCH_LIST" ] && BENCH_LIST="hbase_ycsb_a hbase_ycsb_b hbase_ycsb_c"
[ ! "$BENCH_LIST" ] && BENCH_LIST="hbase_ycsb_a"

# Implement only the different functionality

benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_hbase_vars
  prepare_hbase_config "$HBASE_SETTINGS_FILE" "$HBASE_SETTINGS_FILE_PATH"
  start_hbase

  initialize_ycsb_vars
  #prepare_ycsb_config
}

benchmark_suite_cleanup() {
  clean_hbase
  clean_hadoop
}

benchmark_prepare_hbase_ycsb_a(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  nsplits=$(( $numberOfNodes * 10 ))  # HBase recommends (10 * number of regionservers)

  execute_hbase "$bench_name" "hbase shell -n <<< \"n_splits = $nsplits; create \\\"usertable\\\", \\\"family\\\", {SPLITS => (1..n_splits).map {|i| \\\"user#{1000+i*(9999-1000)/n_splits}\\\"}};\""

  execute_ycsb "$bench_name" "ycsb load hbase098 -P workloads/workloada -cp ${HBASE_CONF_DIR} -p recordcount=${BENCH_DATA_SIZE} -p target=${YCSB_OPERATIONCOUNT} -p threadcount=1 -p table=usertable -p columnfamily=family -s"

}

benchmark_hbase_ycsb_a() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_ycsb "$bench_name" "ycsb run hbase098 -P workloads/workloada -cp ${HBASE_CONF_DIR} -p recordcount=${BENCH_DATA_SIZE} -p target=${YCSB_OPERATIONCOUNT} -p threadcount=1 -p table=usertable -p columnfamily=family -s"

}

benchmark_hbase_insert() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"put \\\"usertable\\\",\\\"row1\\\",\\\"family:testcol\\\",\\\"42\\\";\"" "time"
}

benchmark_hbase_drop() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"disable \\\"usertable\\\"; drop \\\"usertable\\\";\"" "time"
}

