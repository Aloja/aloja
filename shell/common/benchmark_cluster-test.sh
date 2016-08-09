# Sample, simple, benchmark of sleep for a number of seconds
# in this case the benchmark suite has only one benchmark

[ ! "$BENCH_LIST" ] && BENCH_LIST="hdparm dd"

BENCH_REQUIRED_PACKAGES="hdparm dd"

# Set bench global variables here (if any)

# Some validations
[ "$noSudo" ] && { logger "ERROR: SUDO not available, not running $bench_name."; return 0; }

# Gets a list of the different devices and mount points in the cluster
# returns /dev/sda1 /
get_device_mounts(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  local device_mounts
  device_mounts="$($DSH "lsblk| awk '{if (\$7 ~ /\//) print \"/dev/\"substr(\$1, 3) \" \" \$7}'")" # single quotes need to be double spaced
  device_mounts="$(echo -e "$device_mounts"|cut -d' ' -f2-|uniq)" #removes the hostname:

  echo -e "$device_mounts"
}

# Prints the list of mounted devices
get_devices() {
  if [ ! "$BENCH_DEVICE_MOUNTS" ] ; then
    BENCH_DEVICE_MOUNTS="$(get_device_mounts)"
  fi
  echo -e "$(echo -e "$BENCH_DEVICE_MOUNTS"|cut -d' ' -f1)"
}

# Prints the list of mounted filesystem points
get_mounts() {
  if [ ! "$BENCH_DEVICE_MOUNTS" ] ; then
    BENCH_DEVICE_MOUNTS="$(get_device_mounts)"
  fi
  echo -e "$(echo -e "$BENCH_DEVICE_MOUNTS"|cut -d' ' -f2)"
}

benchmark_suite_config() {
  BENCH_DEVICE_MOUNTS="$(get_device_mounts)"

  [ ! "$BENCH_DEVICE_MOUNTS" ] && logger "ERROR: cannot get list of devices and mount points.";
}

benchmark_hdparm(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local devices="$(get_devices)"
  [ ! "$devices" ] && { logger "ERROR: cannot get list of devices"; return 0; }

  for device in $devices ; do
    logger "INFO: Running $bench_name on device: $mount"
    execute_cmd "$bench_name" "sudo hdparm -tT $device" "time"
  done
}


benchmark_dd(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  local mounts="$(get_mounts)"
  [ ! "$mounts" ] && { logger "ERROR: cannot get list of mount points."; return 0; }

  local parts="$(( BENCH_DATA_SIZE / 1000000 ))"
  local tmp_file

  for mount in $mounts ; do
    logger "INFO: Running $bench_name on mount: $mount file size: $BENCH_DATA_SIZE parts: $parts"
    [ "$mount" == "/" ] && tmp_file="${mount}dd_test.tmp" || tmp_file="$mount/dd_test.tmp"

    execute_cmd "$bench_name" "sudo dd if=/dev/zero of=$tmp_file bs=1M count=$parts conv=fdatasync,notrunc && sudo rm -f $tmp_file" "time"
  done
}