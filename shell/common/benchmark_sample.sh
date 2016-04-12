# Sample, simple, benchmark of sleep for a number of seconds
# in this case the benchmark suite has only one benchmark

[ ! "$BENCH_LIST" ] && BENCH_LIST="uptime uptime"

# Set variables here
if [ "$BENCH_EXTRA_CONFIG" ] ; then
  num_seconds="$BENCH_EXTRA_CONFIG"
else
  num_seconds="5" # Defaults 5 seconds if not overidden
fi

benchmark_uptime(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_cmd "$bench_name" "uptime" "time"
die "here"
}

benchmark_sleep(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_cmd "$bench_name" "sleep $num_seconds" "time"
}