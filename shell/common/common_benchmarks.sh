# Helper functions for running benchmarks

#globals
BENCH_CURRENT_NUM_RUN="0"
BENCH_BIN_PATH="\$HOME/share/sw/bin"

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
    local reset="\033[0m" #"$(tput sgr0)"
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
[-s save prepare]
[-N don't delete files]
[-S leave services running (implies -N)]
[-t execution type (e.g: default, experimental)]
[-e extrae (instrument execution)]

${cyan}example: $0 -C vagrant-99 -n ETH -d HDD -r 1 -m 12 -i 10 -p 3 -b HiBench2-min -I 4096 -l wordcount -c 1
$reset"
  exit 1;
}

# parses command line options
get_options() {

  OPTIND=1 #A POSIX variable, reset in case getopts has been used previously in the shell.

  while getopts "h?:C:b:r:n:d:m:i:p:l:I:c:z:s:D:tNS" opt; do
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
        ((MAX_MAPS > 0)) || usage
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
        BENCH_KEEP_FILES="1"
        DELETE_HDFS=""
        ;;
      S)
        BENCH_LEAVE_SERVICES="1"
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


# Temple functions, re implement in benchmark if needed

benchmark_suite_config() {
  logger "DEBUG: No specific ${FUNCNAME[0]} defined for $BENCH_SUITE"
}

# Iterate the specified benchmarks in the suite
benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  for bench in $BENCH_LIST ; do

    bench_input_dir="$BENCH_SUITE/$bench/input"
    bench_output_dir="$BENCH_SUITE/$bench/output"

    # Prepare run (in case defined)
    function_call "benchmark_prepare_$bench"

    BENCH_CURRENT_NUM_RUN="1" #reset the global counter

    # Iterate at least one time
    while true; do
      [ "$BENCH_NUM_RUNS" ] && logger "INFO: Starting iteration $BENCH_CURRENT_NUM_RUN of $BENCH_NUM_RUNS"
      # Bench Run
      function_call "benchmark_$bench"

      # Validate (eg. teravalidate)
      function_call "benchmark_validate_$bench"

      # Clean-up HDFS space (in case necessary)
      #clean_HDFS "$bench_name" "$BENCH_SUITE"

      # Check if requested to iterate multiple times
      if [ ! "$BENCH_NUM_RUNS" ] || [[ "$BENCH_CURRENT_NUM_RUN" -ge "$BENCH_NUM_RUNS" ]] ; then
        break
      else
        BENCH_CURRENT_NUM_RUN="$((BENCH_CURRENT_NUM_RUN + 1))"
      fi
    done

  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

benchmark_suite_save() {
  logger "DEBUG: No specific ${FUNCNAME[0]} defined for $BENCH_SUITE"
}

benchmark_suite_cleanup() {
  logger "DEBUG: No specific ${FUNCNAME[0]} defined for $BENCH_SUITE"
}

########## END TEMPLATE FUNCTIONS

loggerb(){
  stamp=$(date '+%s')
  echo "${stamp} : $1"
  #log to zabbix
  #zabbix_sender "hadoop.status $stamp $1"
}

get_date_folder(){
  echo "$(date +%Y%m%d_%H%M%S)"
}

get_user_bin_path() {
  echo -e "export PATH=$BENCH_BIN_PATH:\$PATH;"
}

# Wraps supplied command with DSH interactive options
# $1 DSH connection string
# $1 cmd
execute_interactive() {
 local DSH_string="$1"
 local cmd="$2"
 $DSH_string -o -t -o -t -- "stty -echo -onlcr; bash -i -c '$cmd'"
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

  if [ "$disk" == "SSD" ] || [ "$disk" == "HDD" ] || [ "$disk" == "RAM" ] || [ "$disk" == "NFS" ] || [ "$disk" == "NVE" ]; then
    dir="${BENCH_DISKS["$disk"]}"
  elif [[ "$disk" =~ .+[0-9] ]] ; then #if last char is a number

    if [[ "$1" =~ [a-zA-Z]+[0-9][0-9] ]] ; then #if last 2 chars are a numbers
      local disks="${1:(-2)}"
      local disks_type="${1:0:(-2)}"
    elif [[ "$1" =~ .+[0-9] ]] ; then
      local disks="${1:(-1)}"
      local disks_type="${1:0:(-1)}"
    fi

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

  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] || [ "$1" == "RAM" ]  || [ "$1" == "NFS" ] || [ "$disk" == "NVE" ]; then
    dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ .+[0-9] ]] ; then #if last char is a number

    if [[ "$1" =~ [a-zA-Z]+[0-9][0-9] ]] ; then #if last 2 chars are a numbers
      local disks="${1:(-2)}"
      local disks_type="${1:0:(-2)}"
    elif [[ "$1" =~ .+[0-9] ]] ; then
      local disks="${1:(-1)}"
      local disks_type="${1:0:(-1)}"
    fi

    if [ "$disks_type" == "RL" ] ; then
      dir="${BENCH_DISKS["HDD"]}"
    elif [ "$disks_type" == "HS" ] ; then
      dir="${BENCH_DISKS["SSD"]}"
    elif [ "$disks_type" == "ST" ] ; then
      dir="${BENCH_DISKS["TMP"]}"
    elif [ "$disks_type" == "SR" ] ; then
      dir="${BENCH_DISKS["TMP_RAM"]}"
    elif [ "$disks_type" == "NFS" ] ; then # on NFS use local as /tmp
      dir="${BENCH_DISKS["HDD"]}"
    elif [ "$disks_type" == "NVE" ] ; then
      dir="${BENCH_DISKS["NVE"]}"
    elif [ "$disks_type" == "HN" ] ; then # HDD + NVE cache
      dir="${BENCH_DISKS["NVE"]}"
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
# $1 disk name
get_all_disks() {
  local disk_name="$1"
  [ ! "$disk_name" ] && die "No disk specified to get_all_disks(). Cannot continue."

  local all_disks="$(get_specified_disks "$disk_name")
$(get_tmp_disk "$disk_name")"

  #remove duplicate lines
  all_disks="$(remove_duplicate_lines "$all_disks")"

  echo -e "$all_disks"
}

# Returns the main benchmark path (useful for multidisk setups)
# $1 disk type
get_initial_disk() {
  if [ "$1" == "SSD" ] || [ "$1" == "HDD" ] || [ "$1" == "RAM" ] || [ "$1" == "NFS" ] || [ "$1" == "NVE" ] ; then
    local dir="${BENCH_DISKS["$DISK"]}"
  elif [[ "$1" =~ [a-zA-Z]+[0-9][0-9] ]] ; then #if last 2 chars are a numbers
    local disks="${1:(-2)}"
    local disks_type="${1:0:(-2)}"
    #set the first dir
    local dir="${BENCH_DISKS["${disks_type}1"]}"
  elif [[ "$1" =~ .+[0-9] ]] ; then #if last char is a number
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
    if [ "${checkClusterMembership}" = "1" ] && ! test_in_cluster "$(hostname)" ; then
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
      die "cannot determine $DISK path.  Output: $(get_initial_disk "$disk")"
    fi

    # Iterate all defined and tmp disks to see if we can write to them
    local disks="$(get_all_disks "$disk" )"
    logger "DEBUG: testing write permissions for mount(s) for config $disk: $(nl2char "$disks" " ")"

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
  fi

  if [ "$clusterType" != "PaaS" ]; then
    # Check whether we are in the right cluster
    if [ "${checkClusterMembership}" = "1" ] && ! test_in_cluster "$(hostname)" ; then
      die "host $(hostname) does not belong to specified cluster $clusterName\nMake sure you run this script from within a cluster"
    fi
  else
    logger "INFO: Skipping some validations in PaaS"
  fi
}

# Groups initialization phases
initialize() {
  # initialize cluster node names and connect string
  initialize_node_names
  # set the name for the job run
  set_job_config
  # check if all nodes are up

  local severity #="ERROR"
  [ "$clusterType" == "SaaS" ] && severity="WARNING" # Continue on SaaS mode

  test_nodes_connection "$severity"

  # check if ~/share is correctly mounted
  test_share_dir
}

#old code moved here
# TODO cleanup
initialize_node_names() {
  local extra_node_names

  #For infiniband tests
  if [ "$NET" == "IB" ] ; then
    [ ! "$defaultProvider" == "vagrant" ] && IFACE="ib0" #vagrant we use for testing IB config
    master_name="$(get_master_name_IB)"
    node_names="$(get_node_names_IB)"
    extra_node_names="$(get_extra_node_names)"
  else
    #IFACE should be already setup
    master_name="$(get_master_name)"
    node_names="$(get_node_names)"
    extra_node_names="$(get_extra_node_names)"
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

#  if (( numberOfNodes > 0 )) ; then
    DSH="dsh -M -c -m "
    DSH_EXTRA="$DSH"
    DSH_MASTER="dsh -H -m $master_name"
    DSH="$DSH $(nl2char "$node_names" ",") "
#  else
#    DSH="ssh $master_name "
#    DSH_MASTER="ssh $master_name "
#  fi

  # TODO deprecate this var
  DSH_C="$DSH -c " #concurrent

  DSH_SLAVES="${DSH_C/"$master_name,"/}" #remove master name and trailing coma

  # Instrument additional nodes
  DSH_ALL="$DSH"

  if [ "$extra_node_names" ] ; then
    logger "WARNING: extra nodes requested for instrumentation"
    DSH_EXTRA+=" $(nl2char "$extra_node_names" ",") "
    # TODO temporary to test
    DSH_ALL="${DSH:0:(-1)},$(nl2char "$extra_node_names" ",")"
  fi
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

# Tests if defined nodes are accessible vis SSH
# $1 error severity ERROR (default) WARNING INFO
test_nodes_connection() {
  local severity="${1:-ERROR}"
  logger "INFO: Testing connectivity to nodes"
  if test_nodes "hostname" ; then
    logger "INFO: All $(get_num_nodes) nodes are accessible via SSH"
  else
    local err_message="Cannot connect via SSH to all nodes"
    if [ "$severity" == "ERROR" ] ; then
      die "$err_message"
    else
      logger "$severity $err_message"
    fi
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
  local test_file="$BENCH_SHARE_DIR/safe_store"

  logger "INFO: Testing if ~/share mounted correctly"
  if test_nodes "ls '$test_file'" ; then
    logger "INFO: All $(get_num_nodes) nodes have the $BENCH_SHARE_DIR dir correctly mounted"
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
  CONF="${NET}_${DISK}_b${BENCH_SUITE}_S${BENCH_SCALE_FACTOR}_D${NUMBER_OF_DATA_NODES}_${clusterName}"

  JOB_NAME="$(get_date_folder)_$CONF"

  JOB_PATH="$BENCH_SHARE_DIR/jobs_$clusterName/$JOB_NAME"
  #LOG_PATH="$JOB_PATH/log_${JOB_NAME}.log"
  #LOG="2>&1 |tee -a $LOG_PATH"

  #create dir to save files in one host
  $DSH_MASTER "mkdir -p $JOB_PATH;"

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

# Get the main path for the benchmark
get_local_bench_path() {
  echo -e "$(get_initial_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"
}

get_local_tmp_path() {
  echo -e "$(get_tmp_disk "$DISK")/$(get_aloja_dir "$PORT_PREFIX")"
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

      # For github repos, add other exceptions to file names that might repeat here
      if [[ "$base_name" =~ "master."* ]] ; then
        # Use the array key index name
        base_name="${required_file}.${base_name#*.}"
      fi

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
  echo 'DEBUG: need to uncompress $(get_base_tarballs_path)/$base_name to $(get_local_apps_path)/$required_file';
  if [[ '$base_name' == *'.tar.gz' || '$base_name' == *'.tgz' ]] ; then
    tar -xzf '$(get_base_tarballs_path)/$base_name' || rm '$(get_base_tarballs_path)/$base_name';
  elif [[ '$base_name' == *'.tar.bz2' ]] ; then
    tar -xjf '$(get_base_tarballs_path)/$base_name' || rm '$(get_base_tarballs_path)/$base_name';
  elif [[ '$base_name' == *'.zip' ]] ; then
    unzip -q -o '$(get_base_tarballs_path)/$base_name' || rm '$(get_base_tarballs_path)/$base_name';
  else
    echo 'ERROR: unknown file extension for $base_name';
  fi
else
  echo 'DEBUG: local dir $(get_local_apps_path)/$required_file exists'
fi
"
    done
  else
    logger "INFO: No required files to download/copy specified"
  fi
}

# Installs binaries and configs
# TODO needs merging with install packages
install_bench_packages() {
  if [ "$BENCH_REQUIRED_PACKAGES" ] ; then
    if [[ "$vmOSType" == "Ubuntu" || "$vmOSType" == "Debian" ]] ; then
      logger "INFO: Testing to see if packages: $BENCH_REQUIRED_PACKAGES are installed"
      if ! test_nodes "dpkg -s $BENCH_REQUIRED_PACKAGES" ; then
        if [ ! "$noSudo" ] ; then
          logger "INFO: Attempting to install: $BENCH_REQUIRED_PACKAGES"
          if ! test_nodes "dpkg -s $BENCH_REQUIRED_PACKAGES 2> /dev/null" ; then
            $DSH "sudo apt-get update;
export DEBIAN_FRONTEND=noninteractive;
sudo apt-get -o Dpkg::Options::='--force-confold' install -y --force-yes $BENCH_REQUIRED_PACKAGES"

            logger "WARNING: failed to install one or more packages: $BENCH_REQUIRED_PACKAGES"
          fi
        else
          logger "WARNING: no sudo selected, cannot install needed packages in: $BENCH_REQUIRED_PACKAGES"
        fi
      else
        logger "INFO: Required packages bench: $BENCH_REQUIRED_PACKAGES are correctly installed"
      fi
    elif [[ "$vmOSType" == "Fedora" || "$vmOSType" == "RHEL" || "$vmOSType" == "CentOS" ]] ; then
      for package in $BENCH_REQUIRED_PACKAGES ; do
        if [ ! "$($DSH "which $package; 2> /dev/null")" ] ; then
          logger "INFO: Attempting to install: $BENCH_REQUIRED_PACKAGES"
          $DSH "sudo yum install --enablerepo=epel -y $BENCH_REQUIRED_PACKAGES"
          break
        fi
      done
    else
      logger "WARNING: not a Debian or Fedora based system, not checking if to install packages: $BENCH_REQUIRED_PACKAGES"
    fi
  fi
}


# Rsyncs specified config folders in aplic2/configs/
install_configs() {
  if [ "$BENCH_CONFIG_FOLDERS" ] ; then
    for config_folder in $BENCH_CONFIG_FOLDERS ; do
      local full_config_folder_path="$(get_base_configs_path)/$config_folder"
      if [ -d "$full_config_folder_path" ] ; then
        logger "INFO: Synching configs from $config_folder"

        $DSH "rsync -ar --delete '$full_config_folder_path' '$(get_local_configs_path)' "
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
  install_bench_packages
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
    local perf_mon_bench_path="$(get_local_bench_path)/aplic"

    if [ "$vmType" != "windows" ] ; then
      for perf_mon in $BENCH_PERF_MONITORS ; do

        if ! inList "$BENCH_PERF_NON_BINARY" "$perf_mon" ; then
          logger "INFO: Setting up performance monitor: $perf_mon"

          # Get the path of file from the aloja repo
          if [[ "$perf_mon" == "cachestat" || "$perf_mon" == "drop_cache" ]] ; then
            perf_mon_bin_path="$ALOJA_REPO_PATH/aloja-tools/src/${perf_mon}.sh"

            if [ "$noSudo" ] ; then
              logger "WARNING: $perf_mon requires sudo, skipping setting it up."
              continue
            fi
          # JavaStat actually uses pidstat
          elif [ "$perf_mon" == "JavaStat" ] ; then
            perf_mon_bin_path="$($DSH_MASTER "$(get_user_bin_path) which 'pidstat'")"
          # Get it from the user path (normal case)
          else
            # we need to include our custom bin path as SSH is not interactive
            perf_mon_bin_path="$($DSH_MASTER "$(get_user_bin_path) which '$perf_mon'")"
          fi

          if [ -f "$perf_mon_bin_path" ] ; then
            log_DEBUG "Copying $perf_mon binary from: $perf_mon_bin_path to $perf_mon_bench_path"
            $DSH "mkdir -p '$perf_mon_bench_path'; cp '$perf_mon_bin_path' '$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX';"

            if [ "$(get_extra_node_names)" ] ; then
              $DSH_EXTRA "mkdir -p '$(get_extra_node_folder)/aplic'; cp '$perf_mon_bin_path' '$(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX'"
            fi
          else
            log_ERR "Cannot find $perf_mon binary on the system at: $perf_mon_bin_path"
            log_DEBUG "Perf monitor bin path: $($DSH_MASTER 'ls "$perf_mon_bin_path" 2>&1')"
          fi
        else
          logger "INFO: Setting up script-style perfomance monitor: $perf_mon"
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
    local perf_mon_bench_path="$(get_local_bench_path)/aplic"

    if [ "$vmType" != "windows" ] ; then
      logger "INFO: Restarting perf monit"
      stop_monit #in case there is any running

      # Make sure we clean monits on abnormal exit
      if [ "$BENCH_PERF_MONITORS" ] ; then
        update_traps "stop_monit;" "update_logger"
      fi

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
  local perf_mon_bin="$(get_local_bench_path)/aplic/${perf_mon}_$PORT_PREFIX"

  if [ "$perf_mon" == "sar" ] ; then
    if [ "$clusterType" != "PaaS" ]; then
      $DSH "$(get_user_bin_path) $perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -o $(get_local_bench_path)/sar-\$(hostname).sar $BENCH_PERF_INTERVAL >/dev/null &" & #2>&1

      if [ "$(get_extra_node_names)" ] ; then
        $DSH_EXTRA "$(get_user_bin_path) $(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX -o $(get_extra_node_folder)/sar-\$(hostname).sar $BENCH_PERF_INTERVAL >/dev/null &" & #2>&1
      fi
    else
      $DSH "$(get_user_bin_path) sar -o $(get_local_bench_path)/sar-\$(hostname).sar $BENCH_PERF_INTERVAL >/dev/null &" & # 2>&1
    fi
  elif [ "$perf_mon" == "vmstat" ] ; then
    if [ "$clusterType" != "PaaS" ]; then
      $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -n $BENCH_PERF_INTERVAL >> $(get_local_bench_path)/vmstat-\$(hostname).log &" &

      if [ "$(get_extra_node_names)" ] ; then
        $DSH_EXTRA "$(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX -n $BENCH_PERF_INTERVAL >> $(get_extra_node_folder)/vmstat-\$(hostname).log &" &
      fi
    else
      $DSH "vmstat -n $BENCH_PERF_INTERVAL >> $(get_local_bench_path)/vmstat-\$(hostname).log &" &
    fi
  # For iostat use PAT's syntax
  elif [ "$perf_mon" == "iostat" ] ; then
    if [ "$clusterType" != "PaaS" ]; then
      $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -x -k -y -d $BENCH_PERF_INTERVAL | awk -v host=\$(hostname) '(!/^$/){now=strftime(\"%s \");if(/Device:/){print \"HostName\",\"TimeStamp\", \$0} else{ if(\$0 && !/Linux/) print host, now \$0}}; fflush()' >> $(get_local_bench_path)/iostat-\$(hostname).log &" &

      if [ "$(get_extra_node_names)" ] ; then
        $DSH_EXTRA "$(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX -x -k -y -d $BENCH_PERF_INTERVAL | awk -v host=\$(hostname) '(!/^$/){now=strftime(\"%s \");if(/Device:/){print \"HostName\",\"TimeStamp\", \$0} else{ if(\$0 && !/Linux/) print host, now \$0}}; fflush()' >> $(get_extra_node_folder)/iostat-\$(hostname).log &"  &
      fi
    else
      $DSH "iostat -x -k -y -d $BENCH_PERF_INTERVAL | awk -v host=\$(hostname) '(!/^$/){now=strftime(\"%s \");if(/Device:/){print \"HostName\",\"TimeStamp\", \$0} else{ if(\$0 && !/Linux/) print host, now \$0}}; fflush()' >> $(get_local_bench_path)/iostat-\$(hostname).log &" &
      #iostat -x -k -d $SAMPLING_INTERVAL
    fi
  # To count Java processes (for PAT export)
  elif [ "$perf_mon" == "MapRed" ] ; then
    $DSH "
(
echo MapCount ReduceCount ContainerCount TezCount JavaCount ProcCount
while :
do
  processes=\"\$(ps fauxwww)\";
  echo \"\$(echo -e \"\$processes\"|grep [j]ava|grep _m_ |wc -l ) \$(echo -e \"\$processes\"|grep [j]ava| grep _r_ |wc -l ) \$(echo -e \"\$processes\"|grep [j]ava| grep container_ |wc -l ) \$(echo -e \"\$processes\"|grep [j]ava| grep container_|grep tez |wc -l ) \$(echo -e \"\$processes\"|grep [j]ava|wc -l ) \$(echo -e \"\$processes\" |wc -l )\"
  sleep $BENCH_PERF_INTERVAL
done
) | awk -v host=\$(hostname) '(!/^\$/){now=strftime(\"%s \");if(\$0 && !/Linux/) if (/MapCount/){print \"HostName\",\"TimeStamp\",\$0} else {print host,now \$0}}; fflush()' > $(get_local_bench_path)/MapRed-\$(hostname).log &" &

  # To count Java processes (for PAT export)
  elif [ "$perf_mon" == "JavaStat" ] ; then
    local pidstat_cmd="java"
    $DSH "
$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -rudh -p ALL -C init | awk -v host=\$(hostname) '(/Time/){\$1=\$2=\"\"; print \"HostName\",\"TimeStamp\", \$0}; fflush()' > $(get_local_bench_path)/JavaStat-\$(hostname).log
$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -rudh -p ALL -C $pidstat_cmd $(( $BENCH_PERF_INTERVAL + 4 )) | awk -v cmd='$pidstat_cmd' -v host=\$(hostname) '(!/^\$/ && !/Time/ && !/CPU/){if (\$NF == cmd){now=strftime(\"%s\"); \$1=\"\"; print host, now, \$0}; fflush()}' >> $(get_local_bench_path)/JavaStat-\$(hostname).log &
" &

  # iotop, requires sudo and interval only 1 sec supported
  elif [ "$perf_mon" == "iotop" ] ; then
    if [ -z "$noSudo" ] || [ "$BENCH_PERF_INTERVAL" == "1" ]; then
      if [ "$clusterType" != "PaaS" ]; then
        local iotop_log="$(get_local_bench_path)/iotop-\$(hostname).log"
        $DSH "touch $iotop_log; sudo $perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -btoqqk >> $iotop_log &" &

        if [ "$(get_extra_node_names)" ] ; then
          $DSH_EXTRA "touch $(get_extra_node_folder)/iotop-\$(hostname).log; sudo $(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX -btoqqk >> $iotop_log &" &
        fi
      else
        $DSH "touch $iotop_log; sudo iotop  >> $iotop_log &" &
      fi
    else
      logger "WARNING: iotop requires root and sudo is disabled for cluster OR BENCH_PERF_INTERVAL != 1 (set to: $BENCH_PERF_INTERVAL), skipping..."
    fi
  # dstat
  elif [ "$perf_mon" == "dstat" ] ; then
     # Removed for ubuntu
     # -T --cpu-adv --top-cpu-adv -l -d --aio --disk-avgqu --disk-avgrq --disk-svctm --disk-tps --disk-util --disk-wait --top-bio-adv --top-io-adv --md-status -n --net-packets  -gimprsy --cpu-use --fs --top-int --top-latency -ipc -lock --mem-adv --top-mem --raw --unix --vm-adv --bits --nocolor --noheader --profile --power --proc-count --thermal --noheaders
     #--cpu-adv --disk-avgqu --disk-avgrq --disk-svctm --disk-wait --md-status  --cpu-use --mem-adv --vm-adv --bits --thermal --top-io-adv --top-int

    if [ "$clusterType" != "PaaS" ]; then
      local dstat_log="$(get_local_bench_path)/dstat-\$(hostname).log"
      $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -T --cpu --top-cpu-adv -l -d --aio --disk-tps --disk-util --top-bio-adv --top-io-adv -n --net-packets  -gimprsy --fs --top-int --top-latency -ipc -lock --top-mem --raw --unix --nocolor --noheader --profile --power --proc-count --noheaders  $BENCH_PERF_INTERVAL >> $dstat_log &" &
    else
      $DSH "dstat -T --cpu --top-cpu-adv -l -d --aio --disk-tps --disk-util --top-bio-adv -n --net-packets  -gimprsy --fs --top-latency -ipc -lock --top-mem --raw --unix --nocolor --noheader --profile --power --proc-count --noheaders  $BENCH_PERF_INTERVAL >> $dstat_log &" &
    fi
  # perf
  elif [ "$perf_mon" == "perf" ] ; then

    # Enable CPU trace data (if we have root)
    if [ -z "$noSudo" ] ; then
      $DSH "sudo echo '0' > /proc/sys/kernel/perf_event_paranoid"
    fi
    # TODO: https://github.com/intel-hadoop/PAT/blob/master/PAT/WORKER_scripts/instruments/perf

  # cachestat
  elif [ "$perf_mon" == "cachestat" ] ; then
      $DSH "sudo $perf_mon_bench_path/${perf_mon}_$PORT_PREFIX -n -t $BENCH_PERF_INTERVAL > $(get_local_bench_path)/cachestat-\$(hostname).log &" & #2>&1

      if [ "$(get_extra_node_names)" ] ; then
        $DSH_EXTRA "sudo $(get_extra_node_folder)/aplic/${perf_mon}_$PORT_PREFIX -n -t $BENCH_PERF_INTERVAL > $(get_extra_node_folder)/cachestat-\$(hostname).log &" & #2>&1
      fi
  # drop_cache
  elif [ "$perf_mon" == "drop_cache" ] ; then
      $DSH "$perf_mon_bench_path/${perf_mon}_$PORT_PREFIX $(( $BENCH_PERF_INTERVAL + 9 )) 3 1 > $(get_local_bench_path)/drop_cache-\$(hostname).log &" & #2>&1

      if [ "$(get_extra_node_names)" ] ; then
        : # do nothing
      fi
  else
    die "Specified perf mon $perf_mon not implemented"
  fi


  wait #for the bg processes

  # BWM not used any more
  #$DSH_C "$bwm -o csv -I bond0,eth0,eth1,eth2,eth3,ib0,ib1 -u bytes -t 1000 >> $(get_local_bench_path)/bwm-\$(hostname).log &"
}

# Kill possibly running perf mons
stop_monit(){
  if [ "$BENCH_PERF_MONITORS" ] ; then
    if [ "$vmType" != "windows" ]; then
      logger "INFO: Stoping monit (in case necessary). Monitors: $BENCH_PERF_MONITORS"
      for perf_mon in $BENCH_PERF_MONITORS ; do

        local requires_sudo=""
        if [[ "$perf_mon" == "iotop" || "$perf_mon" == "cachestat" || "$perf_mon" == "drop_cache" ]] ; then
          requires_sudo="sudo"
        fi

        local perf_mon_bin="$(get_local_bench_path)/aplic/${perf_mon}_$PORT_PREFIX"

        if ! inList "$BENCH_PERF_NON_BINARY" "$perf_mon" ; then
          $DSH "$requires_sudo pkill -9 -f '[${perf_mon_bin:0:1}]${perf_mon_bin:1}' 2> /dev/null" #& # [] for it not to match itself in ssh
        elif [ "$perf_mon" == "MapRed" ] ; then
          $DSH "$requires_sudo pkill -9 -f [M]apCount" # [] for it not to match itself in ssh
        elif [ "$perf_mon" == "JavaStat" ] ; then
          $DSH "$requires_sudo pkill -9 pidstat" # TODO improve to use custom naming
        fi

        if [ "$(get_extra_node_names)" ] ; then
          $DSH_EXTRA "$requires_sudo pkill -9 -f '[${perf_mon_bin:0:1}]${perf_mon_bin:1}' 2> /dev/null" #&
        fi

        # TODO this is something temporal for PaaS clusters
        if [ "$clusterType" == "PaaS" ]; then
          $DSH "killall -9 sadc; killall -9 vmstat; killall -9 iostat; killall -9 pidstat; pkill -9 -f [M]apCount; pgrep -f '[M]apCount'|xargs kill -9; $requires_sudo kill -9 iotop 2> /dev/null"  2> /dev/null
        fi
      done
      #logger "DEBUG: perf monitors ready"
    fi
  fi

  #wait #for the bg processes
}

# Return the bench name with the run number on the name
# and the concurrency number if applicable
# $1 bench_name
get_bench_name_with_num() {
  local bench_name="$1"
  local new_bench_name="$bench_name" #return same if not modified

  if (( "$BENCH_CONCURRENCY" > 1 )) ; then
    new_bench_name="${bench_name}_c$BENCH_CONCURRENCY"
  fi

  if (( "$BENCH_CURRENT_NUM_RUN" > 1 )) ; then
    new_bench_name="${new_bench_name}__$BENCH_CURRENT_NUM_RUN"
  fi

  echo -e "$new_bench_name"
}

# Returns the iteration number (if any)
# $1 bench_name
get_bench_iteration() {
  local bench_name="$1"

  if [[ "$bench_name" = *'__'* ]] ; then
    local bench_postfix="${bench_name##*__}"
    local bench_number="$(only_numbers "$bench_postfix")"

    if [ "$bench_postfix" ] && [ "$bench_number" ] ; then
      echo -e "$bench_number"
    fi
  fi
}

# Strips the run number ie __3 from the bench name
# $1 bench_name
get_bench_name() {
  local bench_name="$1"
  echo -e "${bench_name%%__*}"
}

# Saves information about the system if the tool is installed for the whole cluster
# $1 path where to save files
save_hardinfo() {
  local path="$1"
  local output="$($DSH "which hardinfo && hardinfo -r -f text -m computer.so -m devices.so -m network.so > $path/hardinfo-\$(hostname).txt || echo 'WARNING: hardinfo tool not installed'" 2>&1 /dev/null)"
}

# $1 bench name
save_bench() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  logger "INFO: Saving benchmark $bench_name_num"

  # TODO make sure the dir is created previously (sleep bench case)
  $DSH "mkdir -p $JOB_PATH/$bench_name_num;"

  # Save the perf mon logs
  #$DSH "mv $(get_local_bench_path)/{bwm,vmstat}*.log $(get_local_bench_path)/sar*.sar $JOB_PATH/$bench_name_num/ 2> /dev/null"

  # Move all files, but not dirs in case we are not leaving services on and it is not the last benchmark

  if [[ ! "$BENCH_LEAVE_SERVICES" || "$BENCH_LIST" != *"$bench"  ]] ; then
    $DSH "find $(get_local_bench_path)/ -maxdepth 1 -type f -exec mv {} $JOB_PATH/$bench_name_num/ \; 2> /dev/null"

    if [ "$(get_extra_node_names)" ] ; then
      $DSH_EXTRA "find $(get_extra_node_folder)/ -maxdepth 1 -type f -exec mv {} $JOB_PATH/$bench_name_num/ \; " #2> /dev/null
    fi
  else
    logger "WARNING: Requested to leave services running, leaving local bench files too"
    $DSH "find $(get_local_bench_path)/ -maxdepth 1 -type f -exec cp -r {} $JOB_PATH/$bench_name_num/ \;"

    if [ "$(get_extra_node_names)" ] ; then
      $DSH_EXTRA "find $(get_extra_node_folder)/ -maxdepth 1 -type f -exec cp {} $JOB_PATH/$bench_name_num/ \; 2> /dev/null"
    fi
  fi

  # Save globals during current bench for the benchmark and the main dir
  save_env "$JOB_PATH/$bench_name_num/config_$bench_name_num.sh"
  cp "$JOB_PATH/$bench_name_num/config_$bench_name_num.sh" "$JOB_PATH/config.sh"

  # save system info
  save_hardinfo "$JOB_PATH/$bench_name_num"

  logger "INFO: Compressing and deleting $bench_name_num"

  # try to compress with pbzip2 if available
  $DSH_MASTER "cd $JOB_PATH;
if hash pbzip2 2> /dev/null ; then
  tar -cf  $JOB_PATH/$bench_name_num.tar.bz2 $bench_name_num --use-compress-prog=pbzip2 --totals --checkpoint=1000 --checkpoint-action=ttyout='%{%Y-%m-%d %H:%M:%S}t (%d sec): #%u, %T%*\r';
else
  tar -cjf $JOB_PATH/$bench_name_num.tar.bz2 $bench_name_num                            --totals --checkpoint=1000 --checkpoint-action=ttyout='%{%Y-%m-%d %H:%M:%S}t (%d sec): #%u, %T%*\r';
fi
"
  $DSH_MASTER "rm -rf $JOB_PATH/$bench_name_num"

  logger "INFO: Done saving benchmark $bench_name_num"
}

# Return the total number of nodes starting at one (to include the master node)
get_num_nodes() {
  local num_nodes="$(( NUMBER_OF_DATA_NODES + 1 ))"
  local extra_name_nodes="$(get_extra_node_names)"

#  if [ "$extra_name_nodes" ] ; then
#    local num_extra_nodes="$(echo -e "$extra_name_nodes"|wc -l)"
#    num_nodes="$(( num_nodes + num_extra_nodes))"
#  fi

  echo -e "$num_nodes"
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

  logger "INFO: Preparing benchmark run dirs"

  delete_bench_local_folder "$disk"

  #set the main path for the benchmark
  HDD="$(get_local_bench_path)"
  #for hadoop tmp dir
  HDD_TMP="$(get_local_tmp_path)"

  logger "INFO: Creating bench main dir at: $HDD (and tmp dir: $HDD_TMP)"

  # Creating the main dir
  $DSH "mkdir -p $HDD/logs $HDD_TMP"

  # Create the main dir also on the extra machines path (if defined)
  if [ "$(get_extra_node_names)" ] ; then
    $DSH_EXTRA "mkdir -p $HDD/logs $HDD_TMP"
    local test_extra="$($DSH_EXTRA "[ -d '$HDD' ] && [ -d '$HDD_TMP' ] && echo '$testKey'")"
    if [ ! "$(echo -e "$test_extra"|grep "$testKey")" ] ; then
      die "Cannot create base directories for extra machines: $HDD $HDD_TMP"
    fi
  fi

  # Testing the main dir
  if ! test_nodes "[ -d '$HDD' ] && [ -d '$HDD_TMP' ] " "ERROR" ; then
    local err_message="Cannot create base directories: $HDD $HDD_TMP
DEBUG: ls -lah $HDD $HDD_TMP
$($DSH "ls -lah '$HDD/../'; ls -lah '$HDD_TMP/../' " )
"
    die "$err_message"

  else
    logger "DEBUG: Base dirs created successfully"
  fi

  # specify which binaries to use for monitoring
  set_monit_binaries
}

# Cleanup after a benchmark suite run, and before starting one
# $1 disk name
delete_bench_local_folder() {
  local disk_name="$1"
  [ ! "$disk_name" ] && die "No disk specified to delete_bench_local_folder(). Cannot continue."

  local disks="$(get_all_disks "$disk_name")"

  # Delete when not specified (default)
  if [ "$DELETE_HDFS" == "1" ] ; then
    logger "INFO: Deleting previous run files of disk config: $disk_name in: $(get_aloja_dir "$PORT_PREFIX")"
    local all_disks_cmd
    for disk_tmp in $disks ; do
      local  disk_full_path="$disk_tmp/$(get_aloja_dir "$PORT_PREFIX")"
      $DSH "[ -d '$disk_full_path' ] && (rm -rf $disk_full_path || lsof +D $disk_full_path)" # lsof for debugging in case it cannot be deleted

      #check if we had problems deleting a folder
      #test_directory_not_exists "$disk_full_path"
      all_disks_cmd+="[ ! -d '$disk_full_path' ] && "
    done

    if ! test_nodes "${all_disks_cmd:0:(-3)}" "ERROR" ; then
      die "Cannot delete directory(ies)"
    else
      logger "DEBUG: Previous files successfully deleted"
    fi
  else
    logger "INFO: Deleting only the log dir and stats files"
    for disk_tmp in $disks ; do
      $DSH "find $disk_tmp/$(get_aloja_dir "$PORT_PREFIX")/*logs -type f -exec rm {} \; ;
            rm -rf $disk_tmp/$(get_aloja_dir "$PORT_PREFIX")/*.{sar,log,out};"
    done
  fi
}


set_omm_killer() {
  logger "WARNING: OOM killer might not be set for benchmark"
  #Example: echo 15 > proc/<pid>/oom_adj significantly increase the likelihood that process <pid> will be OOM killed.
  #pgrep apache2 |sudo xargs -I %PID sh -c 'echo 10 > /proc/%PID/oom_adj'
}

# Prints time stamp with milliseconds precision
timestamp() {
#  sec=$(date +%s)
#  nanosec=$(date +%N)
#  tmp=$(expr $sec \* 1000)
#  msec=$(expr $nanosec / 1000000)
#  echo $(expr $tmp + $msec)
  echo -e $(date +%s%3N)
}

calc_exec_time() {
  awk "BEGIN {printf \"%.3f\n\", ($2-$1)/1000}"
}

# Starts the timer for measuring benchmark time
# $1 bench name
set_bench_start() {
  [ ! "$1" ] && die "benchmark name not set"
  local bench_name="$(get_bench_name_with_num "$1")"

  BENCH_TIME="0" #reset global variable

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
  [ ! "$1" ] && die "benchmark name not set"

  local end_exec="$(timestamp)"
  local bench_name="$(get_bench_name_with_num "$1")"

  if [ "$bench_name" ] && [ "${EXEC_START["$bench_name"]}" ] ; then
    # Test if we already have the accurate time calculated, if not calculate it
    if [ ! "$BENCH_TIME" ] || [ "$BENCH_TIME" == "0" ] ; then
      local start_exec="${EXEC_START["$bench_name"]}"
      local total_secs="$(calc_exec_time $start_exec $end_exec)"
      EXEC_TIME["$bench_name"]="$total_secs"
    else
      EXEC_TIME["$bench_name"]="$BENCH_TIME"
    fi

    EXEC_END["$bench_name"]="$end_exec"

    # Also save the exit status
    EXEC_STATUS["$bench_name"]="$EXIT_STATUS"
  else
    die "Empty benchmark name supplied or empty EXEC_START[$bench_name]"
  fi
}

# Checks if command needs to be executed concurrently
# $1 cmd
concurrent_run() {
  local cmd="$1"

  if (( "$BENCH_CONCURRENCY" > 1 )) ; then
    local cmd_tmp
    for (( i=0; i<$BENCH_CONCURRENCY; i++)) ; do
      cmd_tmp+="$cmd &
"
    done

    cmd="${cmd_tmp:0:(-1)}
wait"
  fi

  echo -e "$cmd"
}

# Runs the given command in the whole cluster wrapped "in time"
# Creates a file descriptor to return output in realtime as well as keeping it
# in a var to extract its time
# $1 the command
# $2 set bench time
# $3 nodes SSH string ($DSH)
# $4 bench name (optional)
time_cmd() {
  local cmd="$1"
  local set_bench_time="$2"
  local nodes_SSH="$3"
  local bench_name="$4"

  #TODO remove in the future
  [[ ! "$bench_name" && "$bench" ]] && bench_name="$bench"

  # Clean bench name for storing into file
  bench_name="$(safe_file_name "$bench_name")"

  # Default to all the nodes
  [ ! "$nodes_SSH" ] && nodes_SSH="$DSH"

  # If concurrency is set on the benchmark
  if (( "$BENCH_CONCURRENCY" > 1 )) ; then
    cmd="$(concurrent_run "$cmd")"
    logger "INFO: executing $bench_name with $BENCH_CONCURRENCY of concurrency"
    logger "DEBUG: Concurrent cmd: $cmd"
  fi

  # Check if cmd tries to run in background
  local in_background
  if [ "${cmd:(-1)}" == "&" ] ; then
    in_background="&"
    cmd="${cmd:0:(-1)}"
  fi

  # Output the exit status of the command
  cmd+="$(echo -e "\necho \"Bench return val for ${bench_name}: \$? PIPESTATUS: \${PIPESTATUS[@]}\"")"

  # Run the command normally, capturing the output, and creating a dump file and timing the command
  if [ ! "$in_background" ] && [ "$set_bench_time" ] ; then
    exec 9>&2 # Create a new file descriptor

    # Forcing a pseudo-tty, so that on SIGTERM the command is propagated to the ssh command(s)
    local cmd_output="$(\
shopt -s huponexit;                                               `# Make sure we HUP on exit` \
$nodes_SSH  --                                                    `#  Force a pseudo-tty in DSH with -o -t -o -t`\
"stty -echo -onlcr 2> /dev/null;"                                              `# Avoid \n\r in tty` \
"export TIMEFORMAT=\"Bench time ${bench_name} \$(hostname) %R\";" `# Change to seconds the bash time format` \
"time bash -O huponexit -c '{ ${cmd}; }'\" "                      `# Time and run the command` \
"|tee $(get_local_bench_path)/${bench_name}_\$(hostname).out 2>&1 \""  `# Output all to tty and local file on each host` \
2>&1 |tee $(get_local_bench_path)/${bench_name}.out |tee >(cat - >&9)  `# Capture all the combined output to file ` \
)"

    9>&- # Close the file descriptor
  # Run but don't set times (or wrap the command with single quotes as when timing)
  elif [ ! "$in_background" ] && [ ! "$set_bench_time" ] ; then
  ($nodes_SSH "$cmd"|tee "$(get_local_bench_path)/${bench_name}_\$(hostname).out" 2>&1)
  # Run in background or don't set times (we don't capture times here)
  else
    set_bench_time=""
    ($nodes_SSH "$cmd"|tee "$(get_local_bench_path)/${bench_name}_\$(hostname).out" 2>&1) &
  fi

  # Set the accurate time to the global var (we take the value from the last line, that should be the slowest node)
  if [ "$set_bench_time" ] ; then
    BENCH_TIME="$(tail -n1 <<< "$cmd_output"|awk 'END{print $NF}')"
    logger "DEBUG: BENCH_TIME=$BENCH_TIME"
    if ! is_number "$BENCH_TIME" ; then
      logger "WARNING: cannot get the benchmark time correctly"
    fi

    #Save exit status
    local status
    EXIT_STATUS="$(grep 'Bench return val' <<< "$cmd_output"|cut -d':' -f2-|sed 's/[^0-9 ]*//g'|tr -s ' '|tr -d '\n' )" # get only the numbers
    EXIT_STATUS="${EXIT_STATUS:1}" # remove leading space

    # Check if we get something other than zeros as exit status
    if [[ "$EXIT_STATUS" =~ [0]+ ]] ; then
      status="OK"
    else
      status="FAILED"
    fi

    logger "INFO: Ran $bench_name for $BENCH_TIME seconds. With $status status."
  fi
}

# Runs the given command wrapped "in time"
# Creates a file descriptor to return output in realtime as well as keeping it
# in a var to extract its time
# $1 the command
# $2 set bench time
time_cmd_master() {
   time_cmd "$1" "$2" "$DSH_MASTER"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec (optional)
# $4 nodes SSH string ($DSH)
# $5 dont save benchmark internally, handled by caller (optional)
execute_cmd(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local nodes_SSH="$4"
  local dont_save="$5"

  # Default to all the nodes
  [ ! "$nodes_SSH" ] && nodes_SSH="$DSH"

  # Start metrics monitor (if needed)
  if [ "$time_exec" ] ; then
    #save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  logger "DEBUG: command for $bench:\n$cmd"

  # Run the command and time it
  time_cmd "$cmd" "$time_exec" "$nodes_SSH" "$bench"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    #save_disk_usage "AFTER"
    [ ! "$dont_save" ] && save_bench "$bench"
  fi
}

# Wrapper to set the number of nodes to ALL (including master)
# $1 benchmark name
# $2 command
# $3 if to time exec (optional)
# $4 dont save benchmark internally, handled by caller (optional)
execute_all(){
  execute_cmd "$1" "$2" "$3" "$4"
}

# Wrapper to set the number of nodes to MASTER only
# $1 benchmark name
# $2 command
# $3 if to time exec (optional)
# $4 dont save benchmark internally, handled by caller (optional)
execute_master(){
  execute_cmd "$1" "$2" "$3" "$DSH_MASTER" "$4"
}

# Wrapper to set the number of nodes to SLAVES only
# $1 benchmark name
# $2 command
# $3 if to time exec (optional)
# $4 dont save benchmark internally, handled by caller (optional)
execute_slaves(){
  execute_cmd "$1" "$2" "$3" "$DSH_SLAVES" "$4"
}

save_disk_usage() {
  echo "# Checking disk space with df $1" >> $JOB_PATH/disk.log
  $DSH "df -h" 2>&1 >> $JOB_PATH/disk.log
  echo "# Checking hadoop folder space $1" >> $JOB_PATH/disk.log
  $DSH "du -sh $(get_local_bench_path)/* 2> /dev/null"  >> $JOB_PATH/disk.log
}

check_bench_list() {
  if [ ! "$BENCH_LIST" ] ; then
    BENCH_LIST="$BENCH_ENABLED"
  else
    for bench_tmp in $BENCH_LIST ; do
      if ! inList "$BENCH_ENABLED" "$bench_tmp" ; then
        die "Benchmark $bench_tmp not enabled in BENCH_ENABLED. Enabled: $BENCH_ENABLED"
      fi
    done
  fi
}

# Returns and iterable list of defined benchmark validations
# $1 bench list
# $2 validates list
get_bench_validates() {
  local bench_list="$1"
  local bench_validates="$2"
  local enabled_validates

  for bench_validate in $bench_validates ; do
    if inList "$bench_list" "$bench_validate" ; then
      enabled_validates+="$bench_validate "
#    else
#      logger "DEBUG: not in list $bench_validate list $bench_list"
    fi
  done

  echo -e "${enabled_validates:0:(-1)}" #remove the trailing space
}

# Removes validates from the list (if any)
# $1 bench list
# $2 validates list
remove_bench_validates() {
  local bench_list="$1"
  local bench_validates="$2"
  local no_validates

  for bench_tmp in $bench_list ; do
    if ! inList "$bench_validates" "$bench_tmp" ; then
      no_validates+="$bench_tmp "
    fi
  done

  echo -e "${no_validates:0:(-1)}" #remove the trailing space
}

# Cleans the local bench folder from nodes
clean_bench_local_folder() {
  if [ ! "$BENCH_LEAVE_SERVICES" ] ; then
    logger "INFO: Cleaning up local bench dirs"
    delete_bench_local_folder "$DISK"
  else
    logger "WARNING: Leaving local folders in each node as specified, you should delete them MANUALLY"
  fi
}

# To avoid perl warnings in certain systems (ubuntu 12 at least)
get_perl_exports() {
  local export_perl="
export LC_CTYPE=en_US.UTF-8;
export LC_ALL=en_US.UTF-8;
"
  echo -e "$export_perl"
}

# Outputs needed exports for running services (-S option)
print_exports() {
  logger "INFO: Printing Java exports (if any)"
  function_call get_java_exports "DEBUG"
  logger "INFO: Printing Hadoop exports (if any)"
  function_call get_hadoop_exports "DEBUG"
  logger "INFO: Printing Hive exports (if any)"
  function_call get_hive_exports "DEBUG"
}

# Create a file for the query, and returns the full path
# $1 file name
# $2 content
create_local_file() {
  local file_name="$1"
  local file_content="$2"

  local local_file_path="$(get_local_bench_path)/$file_name"

  # Crate a file
  $DSH_MASTER "cat > $local_file_path <<EOF
$file_content
EOF"

  echo -e "$local_file_path"
}

# Create a file for the query, and returns the full path
# $1 file name (relative to bench dir)
get_local_file() {
  local file_name="$1"

  local local_file_path="$(get_local_bench_path)/$file_name"

  # Crate a file
  local file_content="$($DSH_MASTER "cat '$local_file_path'")"

  echo -e "$file_content"
}

# Checks if an external server is defined to rsync results immediately
# $1 job folder name
rsync_extenal() {
  local job_folder="$1"
  local job_folder_full_path="$(get_repo_path)jobs_$clusterName/$job_folder"

  # If we have share on the master node, first copy to global-share, then to the remote
  if [ "$dont_mount_share_master" ] ; then
    #log_INFO "Rsyncing results to global server (~/share is on the master of the cluster)"
    #vm_rsync_from "$(get_repo_path)jobs_${clusterName}/${job_folder}" "127.0.0.1:~/share/share-global/jobs_$clusterName/" "22" "--progress"
    log_INFO "Copying results to global server (~/share is on the master of the cluster)"
    execute_master "CP_global" "cp -ruv $(get_repo_path)jobs_${clusterName}/${job_folder} ~/share/share-global/jobs_$clusterName/"

    # Use remove FS to rsync the results to continue running benchmarks and not using the master node's network
    if [ "$remoteFileServer" ] ; then
  #    if [ ! -d "$job_folder_full_path" ] ; then
        logger "INFO: Syncing results to external server"
        local relative_share="$(basename $(get_repo_path))"
        vm_rsync_from "$relative_share/jobs_${clusterName}/${job_folder}" "$remoteFileServer:share/jobs_$clusterName/" "$remoteFileServerPort" "" "$remoteFileServerProxy" "$fileServerFullPathAloja"
  #    else
  #      logger "WARNING: path $job_folder_full_path is not a directory"
  #    fi
    else
      logger "DEBUG: No remote file server defined to send results"
    fi
  # Just copy to the remote
  elif [ "$remoteFileServer" ] ; then
#    if [ ! -d "$job_folder_full_path" ] ; then
      logger "INFO: Rsyncing results to external server"
      vm_rsync_from "$(get_repo_path)jobs_${clusterName}/${job_folder}" "$remoteFileServer:share/jobs_$clusterName/" "$remoteFileServerPort" "--progress" "$remoteFileServerProxy"
#    else
#      logger "WARNING: path $job_folder_full_path is not a directory"
#    fi
  else
    logger "DEBUG: No remote file server defined to send results"
  fi

}

# Gets a list of the different devices and mount points in the cluster
# returns /dev/sda1 /
get_device_mounts(){
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  local device_mounts
  device_mounts="$($DSH "lsblk| awk '{if (\$7 ~ /\//) print \"/dev/\"substr(\$1, 3) \" \" \$7}'")" # single quotes need to be double spaced
  device_mounts="$(echo -e "$device_mounts"|cut -d' ' -f2-|sort|uniq)" #removes the hostname: and leaves only unique lines

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
