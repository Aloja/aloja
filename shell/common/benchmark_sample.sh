# Sample, simple, benchmark of sleep for a number of seconds
# in this case the benchmark suite has only one benchmark

[ ! "$BENCH_LIST" ] && BENCH_LIST="uptime sleep"

# Set bench global variables here (if any)

benchmark_uptime(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_all "$bench_name" "uptime" "time"
}

benchmark_sleep(){
  local num_seconds="5" # Defaults 5 seconds if not overidden
  [ "$BENCH_EXTRA_CONFIG" ] && num_seconds="$BENCH_EXTRA_CONFIG"

  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_all "$bench_name" "sleep $num_seconds" "time"
}