# Sample, simple, benchmark of sleep for a number of seconds
# in this case the benchmark suite has only one benchmark


benchmark_suite_config() {
  logger "DEBUG: No custom config needed for $BENCH_SUITE"
}

benchmark_suite_run() {
  # Set variables here
  if [ "$BENCH_EXTRA_CONFIG" ] ; then
    local num_seconds="$BENCH_EXTRA_CONFIG"
  else
    local num_seconds="5" # Defaults 5 seconds if not overidden
  fi

  logger "INFO: Executing $BENCH_SUITE in all nodes"

  # Start perf monitors and timers
  restart_monit
  set_bench_start "$BENCH_SUITE"

  ################# START BENCHMARK CUSTOM CODE HERE ####################

  # Taking a nap for 5 seconds
  for sleep_iterator in $(seq 1 "$num_seconds") ; do
    logger "INFO: Sleeping zzZZZzzz $sleep_iterator"
    # Execute a command in all of the nodes
    $DSH "sleep 1"
  done

  ################# END BENCHMARK CUSTOM CODE HERE   ####################

  # Stop perf monitors and timers
  set_bench_end "$BENCH_SUITE"
  stop_monit

  logger "INFO: DONE executing $BENCH_SUITE"
}

benchmark_suite_save() {
  save_bench "$BENCH_SUITE"
}

benchmark_suite_cleanup() {
  logger "DEBUG: No custom cleanup needed for $BENCH_SUITE"
}