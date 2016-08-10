# SYSBENCH benchmark wrapper
# info on commands: https://wiki.mikejung.biz/Sysbench

[ ! "$BENCH_LIST" ] && BENCH_LIST="cpu_single cpu_cores cpu_double_cores seq_write random_write random_read"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES sysbench"

# Set bench global variables here (if any)
SYSBENCH_CPU_MAX_PRIME="20000"
SYSBENCH_DATA_PREPARED="" # Set to true once the data has been prepared

# Some validations
[ "$noSudo" ] && { logger "ERROR: SUDO not available, not running $bench_name."; return 0; }


benchmark_suite_config() {
  BENCH_DEVICE_MOUNTS="$(get_device_mounts)"

  [ ! "$BENCH_DEVICE_MOUNTS" ] && logger "ERROR: cannot get list of devices and mount points.";
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

  sysbench_cpu "$SYSBENCH_CPU_MAX_PRIME" "$(( vmCores * 2 ))"
}

# $1 max prime number
# $2 number of threads (concurrency)
sysbench_cpu() {
  local max_prime="$1"
  local num_threads="$2"
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name with max prime: $max_prime and $num_threads threads"

  execute_cmd "$bench_name" "sysbench --test=cpu --cpu-max-prime=$max_prime --num-threads=$num_threads run" "time"
}

benchmark_seq_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local mounts="$(get_mounts)"
  [ ! "$mounts" ] && { logger "ERROR: cannot get list of mount points."; return 0; }

  local mount_dir
  for mount in $mounts ; do
    logger "INFO: Running $bench_name on mount: $mount file size: $BENCH_DATA_SIZE"
    [ "$mount" == "/" ] && mount_dir="${mount}aloja_sysbench" || mount_dir="$mount/aloja_sysbench"

    execute_cmd "$bench_name" "sudo mkdir -p $mount_dir && sudo ysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-num=64 prepare" "time"
  done
}

benchmark_random_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local mounts="$(get_mounts)"
  [ ! "$mounts" ] && { logger "ERROR: cannot get list of mount points."; return 0; }

  local mount_dir
  for mount in $mounts ; do
    logger "INFO: Running $bench_name on mount: $mount file size: $BENCH_DATA_SIZE"
    [ "$mount" == "/" ] && mount_dir="${mount}aloja_sysbench" || mount_dir="$mount/aloja_sysbench"

    execute_cmd "$bench_name" "sudo mkdir -p $mount_dir && sudo sysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-test-mode=rndwr --max-time=3600 --max-requests=0 --file-block-size=4K --file-num=64 --num-threads=1 run" "time"
  done
}

benchmark_random_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local mounts="$(get_mounts)"
  [ ! "$mounts" ] && { logger "ERROR: cannot get list of mount points."; return 0; }

  local mount_dir
  for mount in $mounts ; do
    logger "INFO: Running $bench_name on mount: $mount file size: $BENCH_DATA_SIZE"
    [ "$mount" == "/" ] && mount_dir="${mount}aloja_sysbench" || mount_dir="$mount/aloja_sysbench"

    execute_cmd "$bench_name" "sudo mkdir -p $mount_dir && sudo sysbench --test=fileio --file-total-size=$BENCH_DATA_SIZE --file-test-mode=rndrd --max-time=3600 --max-requests=0 --file-block-size=4K --file-num=64 --num-threads=1 run" "time"
  done
}