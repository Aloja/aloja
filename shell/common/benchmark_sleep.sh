benchmark_requires() {
  : # Empty
}

benchmark_config() {
  : # Empty
}

benchmark_run() {
  logger "INFO: Executing sleep in all nodes"

  restart_monit

  # Taking a nap for 5 seconds
  for sleep_iterator in {1..5} ; do
    logger "INFO: Sleeping zzZZZzzz $sleep_iterator"
    $DSH "sleep 1"
  done
  logger "INFO: DONE executing sleep"
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