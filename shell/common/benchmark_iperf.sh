# Benchmark to gather cluster basics

[ ! "$BENCH_LIST" ] && BENCH_LIST="iperf_single iperf_single_cores iperf_single_double_cores iperf_cluster iperf_cluster_cores iperf_cluster_double_cores"

IPERF_VERSION="iperf3"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES $IPERF_VERSION"

# Set bench global variables here (if any)
IPERF_MASTER_NODE=
IPERF_NODES=
IPERF_PORT="5201"
IPERF_PATH=

declare -g -A IPERF_NODES_INTERNAL
declare -g -A IPERF_NODES_CMD

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
  logger "INFO: Starting $numberOfNodes iperf servers in ports $IPERF_PORT - $((IPERF_PORT+numberOfNodes))"
  # copy and rename the binary for easy killing
  execute_all "$bench_name" "which $IPERF_VERSION && cp \$(which $IPERF_VERSION) $IPERF_PATH && \
  for (( i=0; i<=$numberOfNodes; i++ )); do
    echo \"Starting \$(hostname) \$(( $IPERF_PORT+i ))\";
    $IPERF_PATH --server --daemon -p \$(($IPERF_PORT+i));
  done"
}

# Kill running masters
iperf_stop_server() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Stopping all running iperf servers"
  # copy and rename the binary for easy killing
  execute_all "$bench_name" "pkill -9 -f '[${IPERF_PATH:0:1}]${IPERF_PATH:1}'" # [ -f '$IPERF_PATH' ] &&
}

# $1 bench_name
# $1 num threads
# $2 num hosts
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

# Fixes long names as longer break the key ie. wn4-hdil7.ab4b111i1p2u5icbpevyfwuync.cx.internal.cloudapp.net
# $1 hostname
fix_name() {
  local hostname="$1"
  if (( ${#hostname} > 25 )); then
    echo "${hostname%%.*}"
  else
    echo -e "$hostname"
  fi
}

# $1 bench_name
# $1 num threads
run_iperf_multi(){
  local bench_name="$1"
  local num_threads="$2"
  local num_hosts="$3"

  # Get the internal host name, external IPs don't work in certain clusters ie., Dataproc
  for node1 in  $IPERF_NODES; do
    IPERF_NODES_INTERNAL["$(fix_name "$node1")"]="$(ssh $node1 'hostname')"
  done

  local current_port="$IPERF_PORT"
  for node1 in  $IPERF_NODES; do
    IPERF_NODES_CMD["${node1%%.*}"]=""
    for node2 in $IPERF_NODES; do
      if [[ "$node1" != "$node2" ]] ; then
        IPERF_NODES_CMD["$(fix_name "$node1")"]+="$IPERF_VERSION -c ${IPERF_NODES_INTERNAL["$(fix_name "$node2")"]} -p $current_port --bytes $BENCH_DATA_SIZE --format g --parallel $num_threads --get-server-output &
"
      fi
    done
    ((current_port++))
  done

  #log_DEBUG "IN $IPERF_NODES\nINI ${IPERF_NODES_INTERNAL[*]}\nINC ${!IPERF_NODES_CMD[*]}\nINC ${IPERF_NODES_CMD[*]}"

  log_INFO "Executing cluster commands"

  # Start metrics monitor
  restart_monit
  set_bench_start "$bench"

  # Send the commands in background
  for node in "${!IPERF_NODES_CMD[@]}"; do
    #execute_cmd "${bench_name}_${node}" "${IPERF_NODES_CMD[$node]:0:(-1)}" "" "ssh $node" &
    #log_DEBUG "(ssh $node ${IPERF_NODES_CMD[$node]}) &"
    (ssh $node "${IPERF_NODES_CMD[$node]}") &
  done
  log_INFO "Waiting for the background processes"
  wait

  # Stop metrics and save
  set_bench_end "$bench"
  stop_monit
  save_bench "$bench"
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

  run_iperf_multi "$bench_name" "1" ""
}

benchmark_iperf_cluster_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf_multi "$bench_name" "$vmCores" ""
}

benchmark_iperf_cluster_double_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  run_iperf_multi "$bench_name" "$(( vmCores * 2 ))" ""
}

benchmark_suite_cleanup() {
  iperf_stop_server
}
