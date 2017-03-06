

benchmark_suite_run() {

  local bench_name="BB__${FUNCNAME[0]#benchmark_}-$1"
  local cmd=""

  for thread in $(seq -f "%g" -s " "  1 5) ; do #Useful to go from 1 to n...
      cmd+="echo I am thread $thread, STARTING now...
    sleep 10 && echo I am thread $thread, STOPPING now... &
    "
    echo "CMD:
    $cmd"
  done

  cmd+="wait"
  execute_master "$bench_name" "$cmd" "time" "dont_save"
}
