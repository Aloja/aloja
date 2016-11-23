# Benchmark to test HBase installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_hbase.sh"
set_hbase_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_ycsb.sh"
set_ycsb_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="hbase_ycsb_a hbase_ycsb_b hbase_ycsb_c hbase_ycsb_f hbase_ycsb_d hbase_ycsb_e"

#Load the database, using workload A’s parameter file (workloads/workloada) and the "-load" switch to the client.
#Run workload A (using workloads/workloada and "-t") for a variety of throughputs.
#Run workload B (using workloads/workloadb and "-t") for a variety of throughputs.
#Run workload C (using workloads/workloadc and "-t") for a variety of throughputs.
#Run workload F (using workloads/workloadf and "-t") for a variety of throughputs.
#Run workload D (using workloads/workloadd and "-t") for a variety of throughputs. This workload inserts records, increasing the size of the database.
#Delete the data in the database.
#Reload the database, using workload E’s parameter file (workloads/workloade) and the "-load switch to the client.
#Run workload E (using workloads/workloade and "-t") for a variety of throughputs. This workload inserts records, increasing the size of the database.

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
  stop_hbase
  clean_hadoop
}

# $1 bench name
# $2 workload to run
# $3 time exec (optional)
benchmark_hbase_ycsb_x(){
  local bench_name=$1
  local workload=$2
  local time_exec=$3

  execute_ycsb "$bench_name" "ycsb run hbase098 -P workloads/workload${workload} -cp ${HBASE_CONF_DIR} -p recordcount=${BENCH_DATA_SIZE} -p target=${YCSB_OPERATIONCOUNT} -p threadcount=1 -p table=usertable -p columnfamily=family -s" "$time_exec"
}

benchmark_prepare_hbase_ycsb_a(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"disable \\\"usertable\\\"; drop \\\"usertable\\\";\""

  nsplits=$(( $numberOfNodes * 10 ))  # HBase recommends (10 * number of regionservers)

  execute_hbase "$bench_name" "hbase shell -n <<< \"n_splits = $nsplits; create \\\"usertable\\\", \\\"family\\\", {SPLITS => (1..n_splits).map {|i| \\\"user#{1000+i*(9999-1000)/n_splits}\\\"}};\""

  execute_ycsb "$bench_name" "ycsb load hbase098 -P workloads/workloada -cp ${HBASE_CONF_DIR} -p recordcount=${BENCH_DATA_SIZE} -p target=${YCSB_OPERATIONCOUNT} -p threadcount=1 -p table=usertable -p columnfamily=family -s"

}

benchmark_prepare_hbase_ycsb_e(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_hbase "$bench_name" "hbase shell -n <<< \"disable \\\"usertable\\\"; drop \\\"usertable\\\";\""

  nsplits=$(( $numberOfNodes * 10 ))  # HBase recommends (10 * number of regionservers)

  execute_hbase "$bench_name" "hbase shell -n <<< \"n_splits = $nsplits; create \\\"usertable\\\", \\\"family\\\", {SPLITS => (1..n_splits).map {|i| \\\"user#{1000+i*(9999-1000)/n_splits}\\\"}};\""

  execute_ycsb "$bench_name" "ycsb load hbase098 -P workloads/workloade -cp ${HBASE_CONF_DIR} -p recordcount=${BENCH_DATA_SIZE} -p target=${YCSB_OPERATIONCOUNT} -p threadcount=1 -p table=usertable -p columnfamily=family -s"

}

benchmark_hbase_ycsb_a() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" a "time"
}

benchmark_hbase_ycsb_b() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" b "time"
}

benchmark_hbase_ycsb_c() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" c "time"
}

benchmark_hbase_ycsb_d() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" d "time"
}

benchmark_hbase_ycsb_e() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" e "time"
}

benchmark_hbase_ycsb_f() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  benchmark_hbase_ycsb_x "$bench_name" f "time"
}

