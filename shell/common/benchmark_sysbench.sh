# SYSBENCH benchmark wrapper
# info on commands: https://wiki.mikejung.biz/Sysbench

[ ! "$BENCH_LIST" ] && BENCH_LIST="cpu_single cpu_cores cpu_double_cores mem_single mem_core mem_double_cores seq_write random_write random_read"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES sysbench"

# Set bench global variables here (if any)
[ ! "$SYSBENCH_CPU_MAX_PRIME" ] && SYSBENCH_CPU_MAX_PRIME="20000"
[ ! "$SYSBENCH_MEM_MAX_TIME" ] && SYSBENCH_MEM_MAX_TIME="15"


# Some validations
[ "$noSudo" ] && { logger "WARNING: SUDO not available, some disk operations will not run."; return 0; }


benchmark_suite_config() {
  BENCH_DEVICE_MOUNT_DIRS="$(get_device_mounts)"

  [ ! "$BENCH_DEVICE_MOUNT_DIRS" ] && logger "ERROR: cannot get list of devices and mount points.";
}

# $1 max prime number
# $2 number of threads (concurrency)
sysbench_cpu() {
  local max_prime="$1"
  local num_threads="$2"
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name with max prime: $max_prime and $num_threads threads"

  execute_all "$bench_name" "sysbench --test=cpu --cpu-max-prime=$max_prime --num-threads=$num_threads run" "time"
}

benchmark_cpu_single(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_cpu "$SYSBENCH_CPU_MAX_PRIME" "1"
}

benchmark_cpu_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_cpu "$SYSBENCH_CPU_MAX_PRIME" "$vmCores"
}

benchmark_cpu_double_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_mem "$SYSBENCH_CPU_MAX_PRIME" "$(( vmCores * 2 ))"
}

# $1 max time
# $2 number of threads (concurrency)
sysbench_mem() {
  local max_time="$1"
  local num_threads="$2"
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name with max time: $max_time s. and $num_threads threads"

  execute_all "$bench_name" "sysbench --test=memory --max-time=$max_time --num-threads=$num_threads run" "time"
}

benchmark_mem_single(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_mem "$SYSBENCH_MEM_MAX_TIME" "1"
}

benchmark_mem_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_mem "$SYSBENCH_MEM_MAX_TIME" "$vmCores"
}

benchmark_mem_double_cores(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  sysbench_mem "$SYSBENCH_MEM_MAX_TIME" "$(( vmCores * 2 ))"
}


# Iterates the mount points and run the specified command
# replaces MOUNT_DIR with the current mount dir
# $1 bench_name
# $2 cmd to run
# $3 dont't time command
execute_fileio() {
  local bench_name"$1"
  local cmd="$2"
  local dont_time="$3"
  local time_cmd

  [ ! "$dont_time" ] && time_cmd="time"

  local search="MOUNT_DIR"

  local mounts="$(get_mounts)"
  [ ! "$mounts" ] && { logger "ERROR: cannot get list of mount points."; return 0; }

  local mount_dir
  for mount in $mounts ; do
    logger "INFO: Running $bench_name on mount: $mount file size: $BENCH_DATA_SIZE"
    [ "$mount" == "/" ] && mount_dir="${mount}aloja_sysbench" || mount_dir="$mount/aloja_sysbench"

    execute_all "$bench_name" "${cmd//$search/$mount_dir}" "$time_cmd"
  done
}

benchmark_prepare_random_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fileio "$bench_name" "sudo mkdir -p MOUNT_DIR && sudo chmod -R 777 MOUNT_DIR && cd MOUNT_DIR && \
sysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-num=64 prepare;" "time"

}

benchmark_random_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fileio "$bench_name" "sudo mkdir -p MOUNT_DIR && sudo chmod -R 777 MOUNT_DIR && cd MOUNT_DIR && \
sysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-test-mode=rndwr --max-time=3600 --max-requests=0 --file-block-size=4K --file-num=64 --num-threads=1 run;" "time"

}

benchmark_random_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fileio "$bench_name" "sudo mkdir -p MOUNT_DIR && sudo chmod -R 777 MOUNT_DIR && cd MOUNT_DIR && \
sysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-test-mode=rndrd --max-time=3600 --max-requests=0 --file-block-size=4K --file-num=64 --num-threads=1 run;" "time"

}

benchmark_suite_cleanup() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Cleaning up sysbench generated files"
  execute_fileio "$bench_name" "[ -d MOUNT_DIR ] && sudo rm -rf MOUNT_DIR" "dont_time"
}
