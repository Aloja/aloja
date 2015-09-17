benchmark_requires() {
  : # Empty
}

benchmark_config() {
  : # Empty
}

benchmark_run() {
  logger "INFO: Executing $BENCH in all nodes"

  restart_monit
  set_bench_start "$BENCH"

  ################# START BENCHMARK CUSTOM CODE HERE ####################

  # Taking a nap for 5 seconds
  for sleep_iterator in {1..5} ; do
    logger "INFO: Sleeping zzZZZzzz $sleep_iterator"
    $DSH "sleep 1"
  done

  ################# END BENCHMARK CUSTOM CODE HERE   ####################

  set_bench_end "$BENCH"
  stop_monit

  logger "INFO: DONE executing $BENCH"
}

benchmark_teardown() {
  : # Empty
}

benchmark_save() {
  save_bench "$BENCH"
}

benchmark_cleanup() {
  : # Empty
}