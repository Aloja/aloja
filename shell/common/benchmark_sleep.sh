benchmark_config() {
  : # Empty
}

benchmark_run() {
  loggerb "Executing sleep in all nodes"

  restart_monit

  for sleep_iterator in {1..5} ; do
    loggerb "Sleeping zzZZZzzz $sleep_iterator"
    $DSH "sleep 1"
  done
  loggerb "DONE executing sleep"
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