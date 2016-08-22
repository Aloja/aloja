# Benchmark to gather cluster basics

[ ! "$BENCH_LIST" ] && BENCH_LIST="iperf_single iperf_single_cores iperf_single_double_cores" # iperf_cluster iperf_cluster_cores iperf_cluster_double_cores

IPERF_VERSION="iperf3"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES $IPERF_VERSION"

# Set bench global variables here (if any)
IPERF_MASTER_NODE=
IPERF_NODES=
IPERF_PORT="5201"
IPERF_PATH=

# Some validations
#[ "$noSudo" ] && { logger "ERROR: SUDO not available, not running $bench_name."; return 0; }

benchmark_suite_config() {
  IPERF_MASTER_NODE="$(get_master_name)"
  IPERF_NODES="$(get_node_names)"
  IPERF_PATH="$(get_local_bench_path)/${IPERF_VERSION}_aloja"

  iperf_start_server
}

# Starts master in background
iperf_start_server() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"
  # copy and rename the binary for easy killing
  execute_master "$bench_name" "which $IPERF_VERSION && cp \$(which $IPERF_VERSION) $IPERF_PATH && $IPERF_PATH --server --daemon -p $IPERF_PORT"
}

# Kill running masters
iperf_stop_server() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"
  # copy and rename the binary for easy killing
  execute_master "$bench_name" "pkill -9 -f '$IPERF_PATH'"
}

# $1 bench_name
# $1 Num threads
# $2 Num hosts
run_iperf(){
  local bench_name="$1"
  local num_threads="$2"
  local num_hosts="$3"

  # Get the internal host name, external IPs don't work in certain clusters ie., Dataproc
  local master_internal="$(ssh $IPERF_MASTER_NODE 'hostname')" # Get the internal host name, external IPs don't work in certain clusters ie., Dataproc

  local iperf_cmd="$IPERF_VERSION -c $master_internal -p $IPERF_PORT --bytes $BENCH_DATA_SIZE --format g --parallel $num_threads --get-server-output"

  if [ "$num_hosts" == "1" ] ; then
    local one_slave="${DSH_SLAVES%%,*}"
#    one_slave="$($one_slave 'hostname')"
#    one_slave="ssh $one_slave"
    logger "INFO: Running $IPERF_VERSION with $num_threads threads from $num_hosts client(s) $one_slave"
    execute_all "$bench_name" "$iperf_cmd" "time" "$one_slave"
  elif [ ! "$num_hosts" ] ; then
    logger "INFO: Running $IPERF_VERSION with $num_threads threads from all SLAVES client(s)"
    execute_slaves "$bench_name" "$iperf_cmd" "time"
  else
    logger "ERROR: cannot run $IPERF_VERSION in $num_hosts nodes."
  fi
}

benchmark_iperf_single(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "1" "1"
}

benchmark_iperf_single_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "$vmCores" "1"
}

benchmark_iperf_single_double_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "$(( vmCores * 2 ))" "1"
}

benchmark_iperf_cluster(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "1" ""
}

benchmark_iperf_cluster_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "$vmCores" ""
}

benchmark_iperf_cluster_double_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf "$bench_name" "$(( vmCores * 2 ))" ""
}

benchmark_suite_cleanup() {
  iperf_stop_server
}
