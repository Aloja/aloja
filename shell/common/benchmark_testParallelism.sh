

benchmark_suite_run() {

  local bench_name="BB__${FUNCNAME[0]#benchmark_}-$1"
  local cmd=""

  thread="1"
  for stream in $(seq -f "%g" -s " "  1 1) ; do #Useful to go from 1 to n...

      for query in $(seq -f "%g" -s " "  1 5) ; do #Useful to go from 1 to n...
          cmd+="wait &
          "
          for scale_factor in $(seq -f "%g" -s " "  1 2) ; do #Useful to go from 1 to n...
            local thread="$(printf %.$2f $(echo "$thread" | bc))"
            cmd+="echo I am stream $stream running query $query, with scale factor $scale_factor, STARTING now...
            sleep 10  && echo I am scale factor $thread1 in stream $thread2, starting query $thread3, STOPPING now... &
            "
            ((thread++))
          done
      done

  done

  cmd+="wait"
  execute_master "$bench_name" "$cmd" "time" "dont_save"
}
