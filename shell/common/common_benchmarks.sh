# Helper functions for running benchmarks

# Outputs a list of defined benchmark suites separated by spaces
get_bench_suites() {
  local defined_benchs=""
  # Search for benchmark suite definition files
  for bench_file in $ALOJA_REPO_PATH/shell/common/benchmark_*.sh ; do
    local base_name="${bench_file##*/benchmark_}"
    defined_benchs+="${base_name:0:(-3)} "
  done

  #echo -e "sleep HiBench2 HiBench2-min HiBench2-1TB Hecuba-WordCount HiBench3 HiBench3-min"
  echo -e "${defined_benchs:0:(-1)}" #remove trailing space
}

# Enabled benchmarks
[ ! "$BENCH_SUITES" ] && BENCH_SUITES="$(get_bench_suites)"

# prints usage and exits
usage() {

  # Colorize when interactive
  if [ -t 1 ] ; then
    local reset="$(tput sgr0)"
    local red="$(tput setaf 1)"
    local green="$(tput setaf 2)"
    local yellow="$(tput setaf 3)"
    local cyan="$(tput setaf 6)"
    local white="$(tput setaf 7)"
  fi

  echo -e "${yellow}\nALOJA-BENCH, script to run benchmarks and collect results
${white}Usage:
$0 [-C clusterName <uses aloja_cluster.conf if present or not specified>]
[-n net <IB|ETH>]
[-d disk <SSD|HDD|RL{1,2,3}|R{1,2,3}>]
[-b \"benchmark suite\" <$BENCH_SUITES>]
[-r replicaton <positive int>]
[-m max mappers and reducers <positive int>]
[-i io factor <positive int>] [-p port prefix <3|4|5>]
[-I io.file <positive int>]
[-l list of benchmarks <space separated string>]
[-c compression <0 (dissabled)|1|2|3>]
[-z <block size in bytes>]
[-s (save prepare)]
[-N (don't delete files)]
[-t execution type (e.g: default, experimental)]
[-e extrae (instrument execution)]

${cyan}example: $0 -C vagrant-99 -n ETH -d HDD -r 1 -m 12 -i 10 -p 3 -b HiBench2-min -I 4096 -l wordcount -c 1
$reset"
  exit 1;
}

# parses command line options
get_options() {

  OPTIND=1 #A POSIX variable, reset in case getopts has been used previously in the shell.

  while getopts "h?:C:b:r:n:d:m:i:p:l:I:c:z:sN:D:t" opt; do
      case "$opt" in
      h|\?)
        usage
        ;;
      C)
        clusterName=$OPTARG
        ;;
      n)
        NET=$OPTARG
        [ "$NET" == "IB" ] || [ "$NET" == "ETH" ] || usage
        ;;
      d)
        DISK=$OPTARG
        defaultDisk=0
        ;;
      b)
        BENCH_SUITE=$OPTARG
        #[ "$BENCH_SUITE" == "HiBench2" ] || [ "$BENCH_SUITE" == "HiBench2-min" ] || [ "$BENCH_SUITE" == "HiBench2-1TB" ] || [ "$BENCH_SUITE" == "HiBench3" ] || [ "$BENCH_SUITE" == "HiBench3HDI" ] || [ "$BENCH_SUITE" == "HiBench3-min" ] || [ "$BENCH_SUITE" == "sleep" ] || [ "$BENCH_SUITE" == "Big-Bench" ] || [ "$BENCH_SUITE" == "TPCH" ] || usage
        if ! inList "$BENCH_SUITES" "$BENCH_SUITE" ; then
          logger "ERROR: supplied benchmark $BENCH_SUITE not enabled in list: $BENCH_SUITE_SUITES"
          usage
        fi
        ;;
      r)
        REPLICATION=$OPTARG
        ((REPLICATION > 0)) || usage
        ;;
      m)
        MAX_MAPS=$OPTARG
        ((MAX_MAPS > 0 && MAX_MAPS < 33)) || usage
        ;;
      i)
        IO_FACTOR=$OPTARG
        ((IO_FACTOR > 0)) || usage
        ;;
      I)
        IO_FILE=$OPTARG
        ((IO_FILE > 0)) || usage
        ;;
      p)
        PORT_PREFIX=$OPTARG
        ((PORT_PREFIX > 0 && PORT_PREFIX < 6)) || usage
        ;;
      c)
        if [ "$OPTARG" == "0" ] ; then
          COMPRESS_GLOBAL=0
          COMPRESS_TYPE=0
        elif [ "$OPTARG" == "1" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=1
          COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.DefaultCodec
        elif [ "$OPTARG" == "2" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=2
          COMPRESS_CODEC_GLOBAL=com.hadoop.compression.lzo.LzoCodec
        elif [ "$OPTARG" == "3" ] ; then
          COMPRESS_GLOBAL=1
          COMPRESS_TYPE=3
          COMPRESS_CODEC_GLOBAL=org.apache.hadoop.io.compress.SnappyCodec
        fi
        ;;
      l)
        BENCH_LIST=$OPTARG
        ;;
      z)
        BLOCK_SIZE=$OPTARG
        ;;
      s)
        SAVE_BENCH=1
        ;;
      t)
        EXEC_TYPE=$OPTARG
        ;;
      N)
        DELETE_HDFS=0
        ;;
      D)
        LIMIT_DATA_NODES=$OPTARG
        echo "LIMIT_DATA_NODES $LIMIT_DATA_NODES"
        ;;
      e)
          INSTRUMENTATION=1
        ;;
      esac
  done

  shift $((OPTIND-1))

  [ "$1" = "--" ] && shift

}

loggerb(){
  stamp=$(date '+%s')
  echo "${stamp} : $1"
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}

get_date_folder(){
  echo "$(date +%Y%m%d_%H%M%S)"
}

# Tests if the supplied hostname can coincides with any node in the cluster
# NOTE: if you cluster doesnt pass this function you should overwrite it with and specific implementation in your benchark defs
# $1 hostname to check
test_in_cluster() {
  local hostname="$1"
  local coincides=1 #return code when not found

  local node_names="$(get_node_names)"

  if [ "$node_names" ] ; then
    for node in $node_names ; do #pad the sequence with 0s
      [[ "$hostname" == "$node"* ]] && coincides=0
    done
  else
    die "Cannot determine nodeNames for cluster $clusterName"
  fi

  return $coincides
}

#$1 port prefix (optional)
get_aloja_dir() {
 if [ "$1" ] ; then
  echo "${BENCH_FOLDER}_$PORT_PREFIX"
 else
  echo "${BENCH_FOLDER}"
 fi
}

# Return a list of
# $1 disk type
get_specified_disks() {
  local disk="$1"
  local dir

  if [ "$disk" == "SSD" ] || [ "$disk" == "HDD" ] ; then
    dir="${BENCH_DISKS["$disk"]}"
  elif [[ "$disk" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"
    for disk_number in $(seq 1 $disks) ; do
      dir+="${BENCH_DISKS["${disks_type}${disk_number}"]}\n"
    done
    dir="${dir:0:(-2)}" #remove trailing \n
  else
    die "Incorrect disk specified: $disk"
  fi

  echo -e "$dir"
}

# Returns the tmp disk in cases when mixing local and remote disks (eg. RL1)
#$1 disk type
get_tmp_disk() {
  local dir

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    if [ "$disks_type" == "RL" ] ; then
      dir="${BENCH_DISKS["HDD"]}"
    elif [ "$disks_type" == "HS" ] ; then
      dir="${BENCH_DISKS["SSD"]}"
    else
      dir="${BENCH_DISKS["${disks_type}1"]}"
    fi
  fi

  if [ "$dir" ] ; then
    echo -e "$dir"
  else
    die "Cannot determine tmp disk"
  fi
}

# Simple helper to append the tmp disk path
get_all_disks() {
  local all_disks="$(get_specified_disks "$disk")
$(get_tmp_disk "$disk")"

  #remove duplicate lines
  all_disks="$(remove_duplicate_lines "$all_disks")"

  echo -e "$all_disks"
}

# Retuns the main benchmkar path (useful for multidisk setups)
# $1 disk type
get_initial_disk() {
  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] ; then
    local dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[1-9] ]] ; then #if last char is a number
    local disks="${1:(-1)}"
    local disks_type="${1:0:(-1)}"

    #set the first dir
    local dir="${BENCH_DISKS["${disks_type}1"]}"
  fi
  echo -e "$dir"
}

# Check if the supplied list of variables are not null
# $1 variable or list of vars
test_variable_set() {
  local variables="$1"
  for variable in $variables ; do
    if [ ! "${!variable}" ] ; then
      die "Required variable $variable is null, please check the config"
    fi
  done
}

# Performs some basic validations
# $1 DISK
validate() {
  local disk="$1"

  # First check if some required variables are set
  test_variable_set "BENCH_LOCAL_DIR BENCH_SHARE_DIR"

  if [ "$clusterType" != "PaaS" ]; then
    # Check whether we are in the right cluster
    if ! test_in_cluster "$(hostname)" ; then
      die "host $(hostname) does not belong to specified cluster $clusterName\nMake sure you run this script from within a cluster"
    fi

    if ! inList "$CLUSTER_NETS" "$NET" ; then
      die "Disk type $NET not supported for $clusterName\nSupported: $NET"
    fi

    # Disk validations
    if ! inList "$CLUSTER_DISKS" "$DISK" ; then
      die "Disk type $DISK not supported for $clusterName\nSupported: $CLUSTER_DISKS"
    fi

    # Check that we got the dynamic disk location correctly
    if [ ! "$(get_initial_disk "$disk")" ] ; then
      die "cannot determine $DISK path"
    fi

    # Iterate all defined and tmp disks to see if we can write to them
    local disks="$(get_all_disks)"
    for disk_tmp in $disks ; do
      logger "DEBUG: testing write permissions in $disk_tmp"
      local touch_file="$disk_tmp/aloja.touch"
      #if file exists test if we can delete it
      if [ -f "$touch_file" ] ; then
        rm "$touch_file" || die "Cannot delete files in $disk_tmp"
      fi
      touch "$touch_file" || die "Cannot write files in $disk_tmp"
      rm "$touch_file" || die "Cannot delete files in $disk_tmp"
    done
  else
    logger "INFO: Skipping validations"
  fi
}

# Groups initialization phases
initialize() {

  # initialize cluster node names and connect string
  initialize_node_names
  # set the name for the job run
  set_job_config
  # check if all nodes are up
  test_nodes_connection
  # check if ~/share is correctly mounted
  test_share_dir
}

#old code moved here
# TODO cleanup
initialize_node_names() {
  #For infiniband tests
  if [ "$NET" == "IB" ] ; then
    [ ! "$defaultProvider" == "vagrant" ] && IFACE="ib0" #vagrant we use for testing IB config
    master_name="$(get_master_name_IB)"
    node_names="$(get_node_names_IB)"
  else
    #IFACE should be already setup
    master_name="$(get_master_name)"
    node_names="$(get_node_names)"
  fi

  NUMBER_OF_DATA_NODES="$numberOfNodes"

  if [ ! -z "$LIMIT_DATA_NODES" ] ; then
    node_iteration=0
    for node in $node_names ; do
      if [ ! -z "$nodes_tmp" ] ; then
        node_tmp="$node_tmp\n$node"
      else
        node_tmp="$node"
      fi
      [[ $node_iteration -ge $LIMIT_DATA_NODES ]]  && break;
      node_iteration=$((node_iteration+1))
    done

    node_name=$(echo -e "$nodes_tmp")
    NUMBER_OF_DATA_NODES="$LIMIT_DATA_NODES"
  fi

  DSH="dsh -M -c -m "
  DSH_MASTER="ssh $master_name"

  DSH="$DSH $(nl2char "$node_names" ",") "
  DSH_C="$DSH -c " #concurrent

  DSH_SLAVES="${DSH_C/"$master_name,"/}" #remove master name and trailling coma
}

# Tests cluster nodes for a defined condition
# $1 condition string
# $2 severity of error
test_nodes() {
  local condition="$1"
  local severity="$2"

  [ ! "$severity" ] && severity="ERROR"

  local node_output="$($DSH "$condition && echo '$testKey' 2>&1"|sort )"
  local num_OK="$(echo -e "$node_output"|grep "$testKey"|wc -l)"

  local KO_output="$(echo -e "$node_output"|grep -v "$testKey")"

  local num_nodes="$(get_num_nodes)"
  if (( num_OK != num_nodes )) ; then
    logger "${severity}: Cannot execute: $condition in all nodes. Num OK: $num_OK Num KO: $((num_nodes - num_OK))
DEBUG output:
$node_output"
    return 1
  else
    # all is good
    return 0
  fi
}

# Tests cluster nodes for NOT HAVING a defined condition
# $1 condition string
# $2 severity of error
test_nodes_inverse() {
  local condition="$1"
  local severity="$2"

  [ ! "$severity" ] && severity="ERROR"

  local node_output="$($DSH "$condition && echo '$testKey'"|sort 2>&1)"
  local num_OK="$(echo -e "$node_output"|grep "$testKey"|wc -l)"
  local num_nodes="$(get_num_nodes)"
  if (( num_OK > 0 )) ; then
    logger "${severity}: Found condition: $condition in nodes. Num OK: $num_OK Num KO: $((num_nodes - num_OK))
DEBUG Output:
$node_output"
    return 1
  else
    # all is good
    return 0
  fi
}

# Tests if defined nodes are accesible vis SSH
test_nodes_connection() {
  logger "INFO: INFO: Testing connectivity to nodes"
  if test_nodes "hostname" ; then
    logger "INFO: INFO: All $(get_num_nodes) nodes are accesible via SSH"
  else
    die "Cannot connect via SSH to all nodes"
  fi
}

# Sends kill signal to processes listening in a particular port for the whole cluster
# $1 TCP port
kill_on_port() {
 local port="$1"
 test_nodes "fuser -k -n tcp $port"
}

# Tries to mount shared folder
# $1 shared folder
mount_share() {
  shared_folder="$1"

  if [ ! "$noSudo" ] ; then
    logger "WARNING: attempting to remount $shared_folder"
    $DSH "
if [ ! -f '$shared_folder/safe_store' ] ; then
  sudo umount -f '$shared_folder';
  sudo mount '$shared_folder';
  sudo mount -a;
fi
"

  fi
}

# Tests if nodes have the shared dir correctly mounted
# $1 if to exit (for retries)
test_share_dir() {
  local no_retry="$1"
  local test_file="$homePrefixAloja/$userAloja/share/safe_store"

  logger "INFO: INFO: Testing if ~/share mounted correctly"
  if test_nodes "ls '$test_file'" ; then
    logger "INFO: INFO: All $(get_num_nodes) nodes have the ~/share dir correctly mounted"
  else
    if [ "$no_retry" ] ; then
      die "~/share dir not mounted correctly"
    else #try again
      mount_share "$homePrefixAloja/$userAloja/share/"
      test_share_dir "no_retry"
    fi
  fi
}

#old code moved here
# TODO cleanup
set_job_config() {
  # Output directory name
  CONF="${NET}_${DISK}_b${BENCH_SUITE}_D${NUMBER_OF_DATA_NODES}_${clusterName}"
  JOB_NAME="$(get_date_folder)_$CONF"

  JOB_PATH="$BENCH_SHARE_DIR/jobs_$clusterName/$JOB_NAME"
  #LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
  #LOG="2>&1 |tee -a $LOG_PATH"

  #create dir to save files in one host
  $DSH_MASTER "mkdir -p $JOB_PATH"

  # Automatically log all output to file
  log_all_output "$JOB_PATH/${0##*/}"

  logger "STARTING RUN $JOB_NAME"
  logger "INFO: Job path: $JOB_PATH"
  logger "INFO: Conf: $CONF"
  logger "INFO: Benchmark Suite: $BENCH_SUITE"
  logger "INFO: Benchmarks to execute: $BENCH_LIST"
  logger "DEBUG: DSH: $DSH\n"
  #logger "INFO: DSH_C: $DSH_C"
  #logger "INFO: DSH_SLAVES: $DSH_SLAVES"
}

# Set some OS requirements (e.g., to dissable swapping)
update_OS_config() {
  if [ ! "$noSudo" ] && [ "$EXECUTE_HIBENCH" ]; then
    $DSH "
sudo sysctl -w vm.swappiness=0 > /dev/null;
sudo sysctl vm.panic_on_oom=1 > /dev/null;
sudo sysctl -w fs.file-max=65536 > /dev/null;
sudo service ufw stop 2>&1 > /dev/null;
"
  fi
}

get_apps_path() {
  echo -e "aplic2/apps"
}

get_local_apps_path() {
  echo -e "$BENCH_LOCAL_DIR/$(get_apps_path)"
}

get_local_configs_path() {
  echo -e "$BENCH_LOCAL_DIR/aplic2/configs"
}

get_base_apps_path() {
  echo -e "$BENCH_SHARE_DIR/$(get_apps_path)"
}

get_base_tarballs_path() {
  echo -e "$BENCH_SHARE_DIR/aplic2/tarballs"
}

get_base_configs_path() {
  echo -e "$ALOJA_REPO_PATH/config/bench/config_files"
}

# Installs binaries and configs
# TODO needs improvement
install_requires() {
  if [ "${#BENCH_REQUIRED_FILES[@]}" ] ; then
    #logger "INFO: Checking if need to download/copy files to node local dirs at: $(get_local_apps_path)"
    for required_file in "${!BENCH_REQUIRED_FILES[@]}" ; do
      logger "INFO: Checking if to download/copy $required_file"
      local base_name="${BENCH_REQUIRED_FILES["$required_file"]##*/}"

      # test if we need to download first to share dir
      local test_action="$($DSH_MASTER "[ -f '$(get_base_tarballs_path)/$base_name' ] && echo '$testKey'")"
      if [[ ! "$test_action" == *"$testKey"* ]] ; then
        logger "INFO: Downloading $required_file"
        $DSH_MASTER "
mkdir -p '$(get_base_tarballs_path)' && wget --progress=dot -e dotbytes=10M '${BENCH_REQUIRED_FILES["$required_file"]}' -O '$(get_base_tarballs_path)/$base_name' || rm '$(get_base_tarballs_path)/$base_name'"

        # test if download was succesful
        local test_action="$($DSH_MASTER "[ -f '$(get_base_tarballs_path)/$base_name' ] && echo '$testKey'")"
        if [[ ! "$test_action" == *"$testKey"* ]] ; then
          die "Could not download $required_file from ${BENCH_REQUIRED_FILES["$required_file"]}"
        fi
      fi

      $DSH "
if [ ! -d '$(get_local_apps_path)/$required_file' ] ; then
  mkdir -p '$(get_local_apps_path)/';
  cd '$(get_local_apps_path)/';
  echo 'DEBUG: need to uncompress $(get_base_tarballs_path)/$base_name';
  if [[ '$base_name' == *'.tar.gz' ]] ; then
    tar -xzf '$(get_base_tarballs_path)/$base_name';
  elif [[ '$base_name' == *'.tar.bz2' ]] ; then
    tar -xjf '$(get_base_tarballs_path)/$base_name';
  else
    echo 'ERROR: unknown file extension for $base_name';
  fi
else
  : #echo 'INFO: local dir $(get_local_apps_path)/$required_file exists'
fi
"
    done
  else
    logger "INFO: No required files to download/copy specified"
  fi
}

# Rsyncs specified config folders in aplic2/configs/
install_configs() {
  if [ "$BENCH_CONFIG_FOLDERS" ] ; then
    for config_folder in $BENCH_CONFIG_FOLDERS ; do
      local full_config_folder_path="$(get_base_configs_path)/$config_folder"
      if [ -d "$full_config_folder_path" ] ; then
        logger "INFO: Synching configs from $config_folder"
        $DSH "rsync -aur '$full_config_folder_path' '$(get_local_configs_path)' "
      else
        die "Cannot find config folder in $full_config_folder_path"
      fi
    done
  else
    logger "DEBUG: No config folder specified to copy"
  fi
}

install_files() {
  install_requires
  install_configs
}

check_aplic_updates() {
  #only copy files if version has changed (to save time)
  logger "INFO: Checking if to generate source dirs $BENCH_SHARE_DIR/aplic/aplic_version == $BENCH_SOURCE_DIR/aplic_version"
  for node in $node_names ; do
    logger "INFO:  for host $node"
    if [ "$(ssh "$node" "[ "\$\(cat $BENCH_SHARE_DIR/aplic/aplic_version\)" == "\$\(cat $BENCH_SOURCE_DIR/aplic_version 2\> /dev/null \)" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
      logger "INFO: At least host $node did not have source dirs. Generating source dirs for ALL hosts"

      if [ ! "$(ssh "$node" "[ -d \"$BENCH_SHARE_DIR/aplic\" ] && echo 'OK' || echo 'KO'" )" != "OK" ] ; then
        #logger "Downloading initial aplic dir from dropbox"
        #$DSH "wget -nv https://www.dropbox.com/s/ywxqsfs784sk3e4/aplic.tar.bz2?dl=1 -O $BASE_DIR/aplic.tar.bz2"

        $DSH "rsync -aur --force $BENCH_SHARE_DIR/aplic.tar.bz2 /tmp/"

        logger "INFO: Uncompressing aplic"
        $DSH  "mkdir -p $BENCH_SOURCE_DIR/; cd $BENCH_SOURCE_DIR/../; tar -C $BENCH_SOURCE_DIR/../ -jxf /tmp/aplic.tar.bz2; "  #rm aplic.tar.bz2;
      fi

      logger "Rsynching files"
      $DSH "mkdir -p $BENCH_SOURCE_DIR; rsync -aur --force $BENCH_SHARE_DIR/aplic/* $BENCH_SOURCE_DIR/"
      break #dont need to check after one is missing
    else
      logger "INFO:  Host $node up to date"
    fi
  done

  #if [ "$(cat $BENCH_SHARE_DIR/aplic/aplic_version)" != "$(cat $BENCH_SOURCE_DIR/aplic_version)" ] ; then
  #  logger "INFO: Generating source dirs"
  #  $DSH "mkdir -p $BENCH_SOURCE_DIR; cp -ru $BENCH_SHARE_DIR/aplic/* $BENCH_SOURCE_DIR/"
  #  #$DSH "cp -ru $BENCH_SOURCE_DIR/${HADOOP_VERSION}-home $BENCH_SOURCE_DIR/${HADOOP_VERSION}" #rm -rf $BENCH_SOURCE_DIR/${HADOOP_VERSION};
  #elsefi
  #  logger "INFO: Source dirs up to date"
  #fi

}

# Exports a var and path to the cluster
# $1 varname
# $2 path
export_var_path() {
  : # WiP
}

zabbix_sender(){
  :
  #echo "al-1001 $1" | /home/pristine/share/aplic/zabbix/bin/zabbix_sender -c /home/pristine/share/aplic/zabbix/conf/zabbix_agentd_az.conf -T -i - 2>&1 > /dev/null
  #>> $LOG_PATH

##For zabbix monitoring make sure IB ports are available
#ssh_tunnel="ssh -N -L al-1001:30070:al-1001-ib0:30070 -L al-1001:30030:al-1001-ib0:30030 al-1001"
##first make sure we kill any previous, even if we don't need it
#pkill -f "ssh -N -L"
##"$ssh_tunnel"
#
#if [ "${NET}" == "IB" ] ; then
#  $ssh_tunnel &
#fi

}

# Copies specified perf mon binaries to bench path, so that they can be started
# and specially killed easily
set_monit_binaries() {
  if [ "$BENCH_PERF_MONITORS" ] ; then
    local perf_mon_bin_path
    local perf_mon_bench_path="$HDD/aplic"

    if [ "$vmType" != "windows" ]; then
      for perf_mon in $BENCH_PERF_MONITORS ; do
        logger "INFO: Setting up perfomance monitor: $perf_mon"
        perf_mon_bin_path="$($DSH_MASTER "which '$perf_mon'")"
        if [ "$perf_mon_bin_path" ] ; then
          logger "INFO: Copying $perf_mon binary to $perf_mon_bench_path"
          $DSH "mkdir -p '$perf_mon_bench_path'; cp '$perf_mon_bin_path' '$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX'"
        else
          die "Cannot find $perf_mon binary on the system"
        fi
      done
    else
      logger "WARNING: no extra perf monitors set for Windows"
    fi
  else
    logger "WARNING: No peformance monitors (e.g., vmstat) have been selected"
  fi
}

# Before starting monitors always check if they are already running
start_monit() {
  restart_monit
}

# Stops monitors (if any) and starts them
restart_monit(){
  if [ "$BENCH_PERF_MONITORS" ] ; then
    local perf_mon_bin_path
    local perf_mon_bench_path="$HDD/aplic"

    if [ "$vmType" != "windows" ]; then
      logger "INFO: Restarting perf monit"
      stop_monit #in case there is any running

      for perf_mon in $BENCH_PERF_MONITORS ; do
        run_monit "$perf_mon"
      done
      #logger "DEBUG: perf monitors ready"
    fi
  fi
}

# Starts the specified perf_mon
# They execute in background (&) to start them as close as possible in time
# $1 perf_mon
run_monit() {
  local perf_mon="$1"
  local perf_mon_bin="$HDD/aplic/${perf_mon}_$PORT_PREFIX"

  if [ "$perf_mon" == "sar" ] ; then
    $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -o $HDD/sar-\$(hostname).sar $BENCH_PERF_INTERVAL >/dev/null 2>&1 &" &
  elif [ "$perf_mon" == "vmstat" ] ; then
    $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -n $BENCH_PERF_INTERVAL >> $HDD/vmstat-\$(hostname).log &" &
  else
    die "Specified perf mon $perf_mon not implemented"
  fi

  wait #for the bg processes

  # BWM not used any more
  #$DSH_C "$bwm -o csv -I bond0,eth0,eth1,eth2,eth3,ib0,ib1 -u bytes -t 1000 >> $HDD/bwm-\$(hostname).log &"
}

# Kill possibly running perf mons
stop_monit(){
  if [ "$BENCH_PERF_MONITORS" ] ; then
    if [ "$vmType" != "windows" ]; then
      logger "INFO: Stoping monit (in case necesary)"
      for perf_mon in $BENCH_PERF_MONITORS ; do
        local perf_mon_bin="$HDD/aplic/${perf_mon}_$PORT_PREFIX"
        $DSH "killall -9 '$perf_mon_bin'"   2> /dev/null  &
      done
      #logger "DEBUG: perf monitors ready"
    fi
  fi

  wait #for the bg processes
}

save_bench() {
  logger "INFO: Saving benchmark $1"

  # TODO make sure the dir is created previously (sleep bench case)
  $DSH "mkdir -p $JOB_PATH/$1;"

  # Save the perf mon logs
  $DSH "mv $HDD/{bwm,vmstat}*.log $HDD/sar*.sar $JOB_PATH/$1/ 2> /dev/null"

  if [ "$clusterType" == "PaaS" ]; then
    hdfs dfs -copyToLocal "/mr-history" "$JOB_PATH/$1"
  fi
  #we cannot move hadoop files
  #take into account naming *.date when changing dates
  #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$1/"
  #$DSH "cp -r $HDD/logs/* $JOB_PATH/$1/"
  #$DSH "cp $HDD/logs/job*.xml $JOB_PATH/$1/"
  #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$1"
  #cp "${BENCH_HIB_DIR}$bench/hibench.report" "$JOB_PATH/$1/"

  #logger "INFO: Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH"
  #pending, delete

  logger "INFO: Compresing and deleting $1"

  $DSH_MASTER "cd $JOB_PATH; tar -cjf $JOB_PATH/$1.tar.bz2 $1;"
  #tar -cjf $JOB_PATH/host_conf.tar.bz2 conf_*;
  $DSH_MASTER "rm -rf $JOB_PATH/$1"
  #$JOB_PATH/conf_* #TODO check

  logger "INFO: Done saving benchmark $1"
}

# Return the total number of nodes starting at one (to include the master node)
get_num_nodes() {
  echo -e "$(( NUMBER_OF_DATA_NODES + 1 ))"
}

# Tests if a directory is present in the system
# $1 dir to test
test_directory_not_exists() {
  local dir="$1"
  if ! test_nodes "[ ! -d '$dir' ]" ; then
    die "Cannot delete folder $dir"
  fi
}

# Sets the aloja-bench folder ready for benchmarking
# $1 disk
prepare_folder(){
  local disk="$1"

  logger "INFO: INFO: Preparing benchmark run dirs"
  local disks="$(get_all_disks) "

  if [ "$DELETE_HDFS" == "1" ] ; then
    logger "INFO: INFO: Deleting previous run files of disk config: $disk in: $(get_aloja_dir "$PORT_PREFIX")"
    local all_disks_cmd
    for disk_tmp in $disks ; do
      local  disk_full_path="$disk_tmp/$(get_aloja_dir "$PORT_PREFIX")"
      $DSH "[ -d '$disk_full_path' ] && rm -rf $disk_full_path"

      #check if we had problems deleting a folder
      #test_directory_not_exists "$disk_full_path"
      all_disks_cmd+="[ ! -d '$disk_full_path' ] && "
    done

    if ! test_nodes "${all_disks_cmd:0:(-3)}" "ERROR" ; then
      die "Cannot delete directory(ies)"
    else
      logger "DEBUG: Previous files succesfully deleted"
    fi

  else
    logger "INFO: INFO: Deleting only the log dir"
    for disk_tmp in $disks ; do
      $DSH "rm -rf $disk_tmp/$(get_aloja_dir "$PORT_PREFIX")/logs/*"
    done
  fi

  #set the main path for the benchmark
  HDD="$(get_initial_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"
  #for hadoop tmp dir
  HDD_TMP="$(get_tmp_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"

  logger "INFO: Creating bench main dir at: $HDD (and tmp dir: $HDD_TMP)"

  # Creating the main dir
  $DSH "mkdir -p $HDD/logs $HDD_TMP"
  # Testing the main dir

  if ! test_nodes "[ -d '$HDD' ] && [ -d '$HDD_TMP' ] " "ERROR" ; then
    die "Cannot create base directories: $HDD $HDD_TMP
DEBUG: ls -lah $HDD $HDD_TMP
$($DSH "ls -lah '$HDD/../'; ls -lah '$HDD_TMP/../' " )
"
  else
    logger "DEBUG: Base dirs created successfully"
  fi

  # specify which binaries to use for monitoring
  set_monit_binaries
}

set_omm_killer() {
  logger "WARNING: OOM killer might not set for benchmark"
  #Example: echo 15 > proc/<pid>/oom_adj significantly increase the likelihood that process <pid> will be OOM killed.
  #pgrep apache2 |sudo xargs -I %PID sh -c 'echo 10 > /proc/%PID/oom_adj'
}

timestamp() {
  sec=`date +%s`
  nanosec=`date +%N`
  tmp=`expr $sec \* 1000 `
  msec=`expr $nanosec / 1000000 `
  echo `expr $tmp + $msec`
}

calc_exec_time() {
  awk "BEGIN {printf \"%.3f\n\", ($2-$1)/1000}"
}

# Starts the timer for measuring benchmark time
# $1 bench name
set_bench_start() {
  local bench_name="$1"

  BENCH_TIME="" #reset global variable

  if [ "$bench_name" ] ; then
    EXEC_START["$bench_name"]="$(timestamp)"
    EXEC_START_DATE["$bench_name"]="$(date --date='+1 hour' '+%Y%m%d%H%M%S')"
  else
    die "Empty benchmark name supplied"
  fi
}

# Starts the timer for measuring benchmark time
# $1 bench name
set_bench_end() {
  local end_exec="$(timestamp)"
  local bench_name="$1"

  if [ "$bench_name" ] && [ "${EXEC_START["$bench_name"]}" ] ; then
    # Test if we already have the accurate time calculated, if not calculate it
    if [ ! "$BENCH_TIME" ] ; then
      local start_exec="${EXEC_START["$bench_name"]}"
      local total_secs="$(calc_exec_time $start_exec $end_exec)"
      EXEC_TIME["$bench_name"]="$total_secs"
    else
      EXEC_TIME["$bench_name"]="$BENCH_TIME"
    fi

    EXEC_END["$bench_name"]="$end_exec"
  else
    die "Empty benchmark name supplied or empty EXEC_START[$bench_name]"
  fi
}

# Runs the given command wrapped "in time"
# Creates a file descriptor to return output in realtime as well as keeping it
# in a var to extract its time
# $1 the command
# $2 set bench time
time_cmd_master() {
  local cmd="$1"
  local set_bench_time="$2"

  exec 9>&2 # Create a new file descriptor
  local cmd_output="$($DSH_MASTER "/usr/bin/time -f 'Bench time ${bench} %e' bash -c '$cmd'" 2>&1 |tee >(cat - >&9))"
  9>&- # Close the file descriptor

  # Set the accurate time to the global var
  if [ "$set_bench_time" ] ; then
    BENCH_TIME="$(echo -e "$cmd_output"|awk 'END{print $NF}')"
    logger "DEBUG: BENCH_TIME=$BENCH_TIME"
  fi
}

save_disk_usage() {
  echo "# Checking disk space with df $1" >> $JOB_PATH/disk.log
  $DSH "df -h" 2>&1 >> $JOB_PATH/disk.log
  echo "# Checking hadoop folder space $1" >> $JOB_PATH/disk.log
  $DSH "du -sh $HDD/*" 2>&1 >> $JOB_PATH/disk.log
}