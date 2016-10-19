# FIO benchmark wrapper
# info on commands: https://wiki.mikejung.biz/Sysbench

#[ ! "$BENCH_LIST" ] && BENCH_LIST="seq_read seq_write random_read random_write"
[ ! "$BENCH_LIST" ] && BENCH_LIST="seq_read read seq_write write"

BENCH_REQUIRED_PACKAGES="$BENCH_REQUIRED_PACKAGES fio"

# Set bench global variables here (if any)
[ ! "$FIO_IODEPTH" ] && FIO_IODEPTH=256
[ ! "$FIO_BLOCK_SIZES" ] && FIO_BLOCK_SIZES="512 4k 8k 16k 32k 64k 128k 256k"
[ ! "$FIO_JOBS" ] && FIO_JOBS="1 $(( vmCores )) $(( vmCores * 2 ))"    # by default 1, numcores, numcores * 2
[ ! "$FIO_DURATION" ] && FIO_DURATION=60

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

# run fio on directory (ie, creating a file)
execute_fio_dir() {
  local bench_name="$1"
  local rw=$2
  local numjobs=$3
  local dir=$4

  for bs in $FIO_BLOCK_SIZES; do
    logger "INFO: Running $bench_name ($rw) on dir ${dir}, request size: $bs, data size: $BENCH_DATA_SIZE"

    execute_slaves "$bench_name" "sudo fio --name=\"${bench_name}\" --directory=${dir} --ioengine=libaio --direct=1 --bs=${bs} --rw=${rw} --iodepth=${FIO_IODEPTH} --numjobs=${numjobs} --buffered=0 --size=${BENCH_DATA_SIZE} --runtime=${FIO_DURATION} --time_based --randrepeat=0 --norandommap --refill_buffers --output-format=json" "time"
  done

}

# run fio directly on device files (read-only)
execute_fio_dev() {
  local bench_name="$1"
  local rw=$2
  local numjobs=$3
  local dev=$4

  for bs in ${FIO_BLOCK_SIZES}; do
    logger "INFO: Running $bench_name ($rw) on device ${dev}, request size: $bs, data size: $BENCH_DATA_SIZE"

    execute_slaves "$bench_name" "sudo fio --name=\"${bench_name}\" --filename=${dev} --ioengine=libaio --direct=1 --bs=${bs} --rw=${rw} --iodepth=${FIO_IODEPTH} --numjobs=${numjobs} --buffered=0 --size=${BENCH_DATA_SIZE} --runtime=${FIO_DURATION} --time_based --randrepeat=0 --norandommap --refill_buffers --output-format=json --offset_increment=${BENCH_DATA_SIZE}" "time"
  done

}

cleanup_files(){

  local bench_name=$1

  # cleanup
  for dir in $FIO_DIRS; do
    logger "INFO: Cleaning up fio-generated files in $dir"
    execute_slaves "$bench_name" "sudo rm -f ${dir}/{seq,random}_{read,write}.*" ""
  done
}

benchmark_seq_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local dir dev njobs

  # seq_read on dirs, 1 job
  for dir in $FIO_DIRS; do
    execute_fio_dir "$bench_name" read 1 "$dir"
  done
 
  cleanup_files "$bench_name"

  # seq_read on devices, 1 job
  for dev in $FIO_DEVICES; do
    execute_fio_dev "$bench_name" read 1 "$dev"
  done
}

benchmark_random_read(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local dir dev njobs

  # rand_read on dirs, n jobs
  for njobs in ${FIO_JOBS}; do
    for dir in ${FIO_DIRS}; do
      execute_fio_dir "$bench_name" randread $njobs "$dir"
    done
  done

  cleanup_files "$bench_name"

  # rand_read on devices, n jobs
  for njobs in ${FIO_JOBS}; do
    for dev in ${FIO_DEVICES}; do
      execute_fio_dev "$bench_name" randread $njobs "$dev"
    done
  done
}

benchmark_seq_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local dir njobs

  # seq_write on dirs, 1 job
  for dir in $FIO_DIRS; do
    execute_fio_dir "$bench_name" write 1 "$dir"
  done

  cleanup_files "$bench_name"

}

benchmark_random_write(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local dir dev njobs

  # rand_write on dirs, n jobs
  for njobs in ${FIO_JOBS}; do
    for dir in ${FIO_DIRS}; do
      execute_fio_dir "$bench_name" randwrite $njobs "$dir"
    done
  done

  cleanup_files "$bench_name"

}

#benchmark_suite_cleanup() {
#  local bench_name="${FUNCNAME[0]##*benchmark_}"
#  logger "INFO: Cleaning up fio-generated files"
#
#  for dir in $FIO_DIRS; do
#    logger "INFO: Cleaning up fio-generated files in $fio_dir"
#    execute_all "$bench_name" "sudo rm -f ${dir}/{seq,random}_{read,write}.*" ""
#  done
#}

