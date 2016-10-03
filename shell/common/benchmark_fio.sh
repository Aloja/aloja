# FIO benchmark wrapper
# info on commands: https://wiki.mikejung.biz/Sysbench

#[ ! "$BENCH_LIST" ] && BENCH_LIST="seq_read seq_write random_read random_write"
[ ! "$BENCH_LIST" ] && BENCH_LIST="seq_read"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES fio"

# Set bench global variables here (if any)
#[ ! "$SYSBENCH_CPU_MAX_PRIME" ] && SYSBENCH_CPU_MAX_PRIME="20000"
#[ ! "$SYSBENCH_MEM_MAX_TIME" ] && SYSBENCH_MEM_MAX_TIME="15"


# Some validations
[ "$noSudo" ] && { logger "WARNING: SUDO not available, some disk operations will not run."; return 0; }

# overridden
#benchmark_suite_config() {
#
#  # get list of devices on which to run fio
#  # we assume it's the same on all nodes
#
#  # if user specified a list, use that; otherwise, try to automagically detect it
#
#  BENCH_DEVICES="$(get_device_mounts)"
#
#  [ ! "$BENCH_DEVICE_MOUNT_DIRS" ] && logger "ERROR: cannot get list of devices and mount points.";
#}

# $1 bench_name
# $2 rw type
execute_fio() {
  local bench_name"$1"
  local rwpat=$2

  for fio_dir in $FIO_DIRS; do
    logger "INFO: Running $bench_name on dir ${fio_dir} size: $BENCH_DATA_SIZE"

    execute_all "$bench_name" "sudo fio --name=\"${bench_name}\" --directory=${fio_dir} --ioengine=libaio --direct=1 --bs=4k --rw=${rwpat} --iodepth=32 --numjobs=$(( $vmCores )) --buffered=0 --size=${BENCH_DATA_SIZE} --runtime=60 --time_based --randrepeat=0 --norandommap --refill_buffers --output-format=json" "time"

  done

}

benchmark_seq_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fio "Sequential_Read" read
}

benchmark_random_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fio "Random_Read" randread
}

benchmark_seq_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fio "Sequential_Write" write
}

benchmark_random_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  execute_fio "Random_Write" randwrite
}

benchmark_suite_cleanup() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Cleaning up fio-generated files"

  for fio_dir in $FIO_DIRS; do
    logger "INFO: Cleaning up fio-generated files in $fio_dir"
    execute_all "$bench_name" "sudo rm -f ${fio_dir}/{seq,random}_{read,write}.*" "dont_time"
  done
}

