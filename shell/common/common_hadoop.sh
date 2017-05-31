#HADOOP SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_java.sh"
set_java_requires

get_hadoop_config_folder() {
  local config_folder_name

  if [ "$HADOOP_CUSTOM_CONFIG" ] ; then
    config_folder_name="$HADOOP_CUSTOM_CONFIG"
  elif [ "$HADOOP_EXTRA_JARS" == "AOP4Hadoop" ] ; then
    config_folder_name="hadoop1_AOP_conf_template"
  elif [ "$(get_hadoop_major_version)" == "2" ]; then
    config_folder_name="hadoop2_conf_template"
  else
    config_folder_name="hadoop1_conf_template"
  fi

  echo -e "$config_folder_name"
}

set_hadoop_config_folder() {
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS $(get_hadoop_config_folder)"
}

# Sets the required files to download/copy
set_hadoop_requires() {
 if [ "$clusterType" != "PaaS" ]; then
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION.tar.gz"
  else
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION-bin.tar.gz"
  fi

  if [ "$HADOOP_EXTRA_JARS" ] ; then
    BENCH_REQUIRED_FILES["HADOOP_EXTRA_JARS"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/$HADOOP_EXTRA_JARS.tar.gz"
  fi
 fi

  # also set the config here
  set_hadoop_config_folder

  # measure number of mappers and reducers
  [ ! "$ALOJA_FAST_MODE" ] && BENCH_PERF_MONITORS+=" MapRed JavaStat"
}

# Helper to print a line with Hadoop required exports
get_hadoop_exports() {

 if [ "$clusterType" == "PaaS" ]; then
  : # Empty
 else
  local to_export

  # For both versions
  to_export="$(get_java_exports)
export HADOOP_CONF_DIR='$HDD/hadoop_conf';
export HADOOP_LOG_DIR='$HDD/hadoop_logs';
export HADOOP_HOME='$(get_local_apps_path)/${HADOOP_VERSION}';
export HADOOP_OPTS='$HADOOP_OPTS';"

  # For v2 only
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    to_export="$to_export
export HADOOP_YARN_HOME='$(get_local_apps_path)/${HADOOP_VERSION}';
export YARN_LOG_DIR='$HDD/hadoop_logs';
"
  fi

  if [ "$HADOOP_EXTRA_JARS" ] ; then
    # Right now jar files are hard-coded
    to_export="$to_export
export HADOOP_USER_CLASSPATH_FIRST=true;
export HADOOP_CLASSPATH=$(get_local_apps_path)/$HADOOP_EXTRA_JARS/aspectjrt-1.6.5.jar:$(get_local_apps_path)/$HADOOP_EXTRA_JARS/AOP4Hadoop-hadoop-core-1.0.3.jar:\$HADOOP_CLASSPATH;"
  fi

  echo -e "$to_export"
 fi
}

# Function to return job specific config
# rr in the case of PaaS where we cannot change the server config
get_hadoop_job_config() {
  local job_config="$BENCH_EXTRA_CONFIG"

  # For v2 only
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    job_config+=" -D mapreduce.job.maps='$MAX_MAPS'"
    job_config+=" -D mapreduce.job.reduces='$MAX_MAPS'"
    #if [ ! -z "$AM_MB" ]; then
    #  job_config+=" -Dyarn.yarn.app.mapreduce.am.resource.mb='${AM_MB}'"
    #fi
    if [ "$clusterType" != "PaaS" ]; then
      if [ ! -z "$MAPS_MB" ]; then
        job_config+=" -Dmapreduce.map.memory.mb='${MAPS_MB}'"
      fi
      if [ ! -z "$REDUCES_MB" ]; then
        job_config+=" -Dmapreduce.reduce.memory.mb='${REDUCES_MB}'"
      fi
    fi
  else
    job_config+=" -D mapred.map.tasks='$MAX_MAPS'"
    job_config+=" -D mapred.reduce.tasks='$MAX_MAPS'"
  fi

  echo -e "${job_config:1}" #remove leading space
}


# Get the list of slaves
# $1 list of nodes
# $2 master name
get_hadoop_slaves() {
  local all_nodes="$1"
  local master_name="$2"
  local only_slaves

  # Special case for master/slave mode in one node
  if [ "$NUMBER_OF_DATA_NODES" == "0" ] ; then
    only_slaves="$master_name"
  # Normal case
  elif [ "$all_nodes" ] && [ "$master_name" ] ; then
    only_slaves="$(echo -e "$all_nodes"|grep -v "$master_name")"
  else
    die "Empty list of nodes supplied"
  fi

  echo -e "$only_slaves"
}

# Sets a coma separeted list of disks for the hadoop conf file
#1 disk type $2 postfix $3 port prefix
get_hadoop_conf_dir() {
  local dir

  local disks="$(get_specified_disks "$1")"
  for disk_tmp in $disks ; do
    dir="$dir\,$disk_tmp/$(get_aloja_dir "$3")/$2"
  done

  if [ "$dir" ] ; then
    dir="${dir:2}" #remove leading \,
    echo -e "$dir"
  else
    die "Cannot get disk config for specified disk $1. Disks: $disks"
  fi
}


#old code moved here
# TODO cleanup
initialize_hadoop_vars() {

 if [ "$clusterType" == "PaaS" ]; then

  BENCH_HADOOP_DIR="/usr/hdp/current/hadoop-client" #execution dir for HDP add other ones
  HADOOP_CONF_DIR="/etc/hadoop/conf"
  HADOOP_EXPORTS=""

  #update_traps "stop_monit;" "update_logger"
 else
  [ ! "$HDD" ] && die "HDD var not set!"

  BENCH_HADOOP_DIR="$(get_local_apps_path)/$HADOOP_VERSION" #execution dir

  HADOOP_CONF_DIR="$HDD/hadoop_conf"
  HADOOP_EXPORTS="$(get_hadoop_exports)"

  # Use instrumented version of Hadoop
  if [ "$INSTRUMENTATION" == "1" ] ; then
    HADOOP_VERSION="${HADOOP_VERSION}-instr"
  fi

#  if [ ! "$BENCH_LEAVE_SERVICES" ] ; then
    #make sure all spawned background jobs and services are stopped or killed when done
    if [ "$INSTRUMENTATION" == "1" ] ; then
      update_traps "stop_hadoop; stop_sniffer;" "update_logger"
    else
      update_traps "stop_hadoop; " "update_logger"
    fi
#  else
#      update_traps "logger 'WARNING: leaving Hadoop services running as requested (stop manually).';"
#  fi

 fi
}

get_hadoop_ports() {

# Hadop 1 ports
#  <name>dfs.datanode.address</name>
#  <value>##HOST##:##PORT_PREFIX##0010</value>
#  <name>dfs.datanode.ipc.address</name>
#  <value>##HOST##:##PORT_PREFIX##0020</value>
#  <name>dfs.http.address</name>
#  <value>##NAMENODE##:##PORT_PREFIX##0070</value>
#  <name>dfs.datanode.http.address</name>
#  <value>##HOST##:##PORT_PREFIX##0075</value>
#  <name>dfs.secondary.http.address</name>
#  <value>##NAMENODE##:##PORT_PREFIX##0090</value>
#  <name>dfs.backup.http.address</name>
#  <value>##NAMENODE##:##PORT_PREFIX##0105</value>
#
#  <name>mapred.job.tracker</name>
#  <value>##MASTER##:##PORT_PREFIX##8021</value>
#  <name>mapred.job.tracker.http.address</name>
#  <value>##MASTER##:##PORT_PREFIX##0030</value>
#  <name>mapred.task.tracker.http.address</name>
#  <value>##HOST##:##PORT_PREFIX##0060</value>
#  <!-- For infiniBand -->
#  <name>mapred.tasktracker.dns.interface</name>
#  <value>##IFACE##</value>
#  
#  <name>fs.default.name</name>
#  <value>hdfs://##NAMENODE##:##PORT_PREFIX##8020</value>

# For v2
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    ports+="${PORT_PREFIX}0010
${PORT_PREFIX}0020
${PORT_PREFIX}0070
${PORT_PREFIX}0075
${PORT_PREFIX}0090
${PORT_PREFIX}0105
${PORT_PREFIX}8021
${PORT_PREFIX}0030
${PORT_PREFIX}0060
${PORT_PREFIX}8020
${PORT_PREFIX}8030
${PORT_PREFIX}8031
${PORT_PREFIX}8032
${PORT_PREFIX}0033"

# Master
#tcp        0      0 192.168.99.100:39888    0.0.0.0:*               LISTEN      1000       170001      25763/java
#tcp        0      0 0.0.0.0:10033           0.0.0.0:*               LISTEN      1000       169994      25763/java
#tcp6       0      0 192.168.99.100:8088     :::*                    LISTEN      1000       168076      25617/java
#tcp6       0      0 192.168.99.100:8033     :::*                    LISTEN      1000       168264      25617/java
# Data
#tcp        0      0 127.0.0.1:42433         0.0.0.0:*               LISTEN      1000       95790       29702/java

# For v1
  else
    ports="${PORT_PREFIX}0010
${PORT_PREFIX}0020
${PORT_PREFIX}0070
${PORT_PREFIX}0075
${PORT_PREFIX}0090
${PORT_PREFIX}0105
${PORT_PREFIX}8021
${PORT_PREFIX}0030
${PORT_PREFIX}0060
${PORT_PREFIX}8020"

  fi

  echo -e "$ports"
}

# Sets the substitution values for the hadoop config
get_hadoop_substitutions() {

  #generate the path for the hadoop config files, including support for multiple volumes
  HDFS_NDIR="$(get_hadoop_conf_dir "$DISK" "dfs/name" "$PORT_PREFIX")"
  HDFS_DDIR="$(get_hadoop_conf_dir "$DISK" "dfs/data" "$PORT_PREFIX")"

  IO_MB="$((IO_FACTOR * 10))"
  MAX_REDS="$MAX_MAPS"

  cat <<EOF
s,##JAVA_HOME##,$(get_java_home),g;
s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
s,##JAVA_XMS##,$JAVA_XMS,g;
s,##JAVA_XMX##,$JAVA_XMX,g;
s,##JAVA_AM_XMS##,$JAVA_AM_XMS,g;
s,##JAVA_AM_XMX##,$JAVA_AM_XMX,g;
s,##LOG_DIR##,$HDD/hadoop_logs,g;
s,##REPLICATION##,$REPLICATION,g;
s,##MASTER##,$master_name,g;
s,##NAMENODE##,$master_name,g;
s,##TMP_DIR##,$HDD_TMP,g;
s,##HDFS_NDIR##,$HDFS_NDIR,g;
s,##HDFS_DDIR##,$HDFS_DDIR,g;
s,##MAX_MAPS##,$MAX_MAPS,g;
s,##MAX_REDS##,$MAX_REDS,g;
s,##IFACE##,$IFACE,g;
s,##IO_FACTOR##,$IO_FACTOR,g;
s,##IO_MB##,$IO_MB,g;
s,##PORT_PREFIX##,$PORT_PREFIX,g;
s,##IO_FILE##,$IO_FILE,g;
s,##BLOCK_SIZE##,$BLOCK_SIZE,g;
s,##PHYS_MEM##,$PHYS_MEM,g;
s,##YARN_MAX_MEM##,$YARN_MAX_MEM,g;
s,##NUM_CORES##,$NUM_CORES,g;
s,##CONTAINER_MIN_MB##,$CONTAINER_MIN_MB,g;
s,##CONTAINER_MAX_MB##,$CONTAINER_MAX_MB,g;
s,##MAPS_MB##,$MAPS_MB,g;
s,##REDUCES_MB##,$REDUCES_MB,g;
s,##AM_MB##,$AM_MB,g;
s,##BENCH_LOCAL_DIR##,$BENCH_LOCAL_DIR,g;
s,##HDD##,$HDD,g;
EOF
}

prepare_hadoop_config(){

 if [ "$clusterType" == "PaaS" ]; then
  # Save config
  logger "INFO: Saving bench spefic config to job folder"
  for node in $node_names ; do
    ssh "$node" "
    mkdir -p $JOB_PATH/conf_$node;
    cp $HADOOP_CONF_DIR/* $JOB_PATH/conf_$node/" &
  done

  if [ "$DELETE_HDFS" == "1" ] ; then
    format_HDFS "$(get_hadoop_major_version)"
  else
    logger "INFO: Deleting previous Job history files (in case necessary)"
    $DSH_MASTER "$BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r -skipTrash /tmp/hadoop-yarn/history" 2> /dev/null
  fi
 else
  logger "INFO: Preparing Hadoop run specific config"
  $DSH "mkdir -p $HDD/hadoop_conf; cp -r $(get_local_configs_path)/$(get_hadoop_config_folder)/* '$HDD/hadoop_conf';"

  # Create datanodes socket file with required permissions
  # see http://www.ibm.com/support/knowledgecenter/STXKQY_4.2.0/com.ibm.spectrum.scale.v4r2.adv.doc/bl1adv_ConfigureShortCircuitRead.htm
  local short_circuit
  if [ ! "$noSudo" ] ; then
    local dn_socket="/var/run/aloja-run/hadoop_socket_$PORT_PREFIX"
    local test_action="$($DSH "sudo mkdir -p '$dn_socket' && sudo chown $userAloja '$dn_socket' && sudo chmod 750 '$dn_socket' && rm -f '$dn_socket/dn_socket' && echo '$testKey';")"
    if [[ "$test_action" == *"$testKey"* ]] ; then
      short_circuit="1"
    else
      #log_WARN
      die "Cannot create/set permissions for datanodes short circuit at: $dn_socket. Test output: $test_action"
    fi
  fi

  # Get the values
  subs=$(get_hadoop_substitutions)
  slaves="$(get_hadoop_slaves "$node_names" "$master_name")"

  $DSH "
$(get_perl_exports)
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/hadoop-env.sh;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/*.xml;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/*.properties

echo -e '$master_name' > $HADOOP_CONF_DIR/masters;
echo -e \"$slaves\" > $HADOOP_CONF_DIR/slaves;

if [ '$short_circuit' ] ; then
  /usr/bin/perl -0777 -i -pe 's{<!-- ##SHORT_CIRCUIT## -->}{
<property>
  <name>dfs.client.read.shortcircuit</name>
  <value>true</value>
</property>
<property>
  <name>dfs.domain.socket.path</name>
  <value>$dn_socket/dn_socket</value>
</property>
<property>
  <name>dfs.client.read.shortcircuit.streams.cache.size</name>
  <value>4096</value>
</property>}g' $HADOOP_CONF_DIR/hdfs-site.xml;
fi
"

  # Extra config for v2
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    $DSH "
$export_perl
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/yarn-site.xml;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/yarn-env.sh;
/usr/bin/perl -i -pe \"$subs\" $HADOOP_CONF_DIR/mapred-env.sh"
  fi

  # TODO this part need to be improved, it needs the node for multiple hostnames in a machine (eg. when IB)
  logger "INFO: Replacing per host config"
  for node in $node_names ; do
    ssh "$node" "
$export_perl
/usr/bin/perl -i -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/mapred-site.xml
/usr/bin/perl -i -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/hdfs-site.xml"
    # Extra config for v2
    if [ "$(get_hadoop_major_version)" == "2" ]; then
      ssh "$node" "$export_perl
/usr/bin/perl -i -pe \"s,##HOST##,$node,g;\" $HADOOP_CONF_DIR/yarn-site.xml"
    fi
  done

  # Save config
  logger "INFO: Saving bench spefic config to job folder"
  for node in $node_names ; do
    ssh "$node" "
mkdir -p $JOB_PATH/conf_$node;
cp $HADOOP_CONF_DIR/* $JOB_PATH/conf_$node/" &
  done

  if [ "$DELETE_HDFS" == "1" ] ; then
    format_HDFS
  else
    logger "INFO: Deleting previous Job history files (in case necessary)"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r -skipTrash /tmp/hadoop-yarn/history" 2> /dev/null
  fi

  # Set correct permissions for instrumentation's sniffer
  [ "$INSTRUMENTATION" == "1" ] && instrumentation_set_perms
 fi
}

# Returns if Hadoop v1 or v2
# $1 the hadoop string (optional, if not uses $HADOOP_VERSION)
get_hadoop_major_version() {
  if [ "$1" ] ; then
    local hadoop_string="$1"
  else
    local hadoop_string="$HADOOP_VERSION"
  fi

  local major_version=""
  if [ "$clusterType" == "PaaS" ]; then
    major_version="2"
  elif [[ "$hadoop_string" == *"p-1"* ]] ; then
    major_version="1"
  elif [[ "$hadoop_string" == *"p-2"* ]] ; then
    major_version="2"
  #backwards compatibility with old runs
  elif [ "$hadoop_string" == "hadoop2" ]; then
    major_version="2"
  else
    logger "WARNING: Cannot determine Hadoop major version.  Supplied version $hadoop_string"
  fi

  echo -e "$major_version"
}

# Formats the HDFS and NameNode for both Hadoop versions
format_HDFS(){
  if [ "$clusterType" != "PaaS" ] && [ "$clusterType" != "SaaS" ]; then
#     $DSH_MASTER "echo Y | sudo $BENCH_HADOOP_DIR/bin/hdfs namenode -format"
#     $DSH_MASTER "echo Y | sudo $BENCH_HADOOP_DIR/bin/hdfs datanode -format"
#  else
  local hadoop_version="$(get_hadoop_major_version)"
  logger "INFO: Formating HDFS and NameNode dirs"

    if [ "$(get_hadoop_major_version)" == "1" ]; then
      $DSH_MASTER "
  $HADOOP_EXPORTS yes Y | $BENCH_HADOOP_DIR/bin/hadoop namenode -format;
  $HADOOP_EXPORTS yes Y | $BENCH_HADOOP_DIR/bin/hadoop datanode -format;"
  
    elif [ "$(get_hadoop_major_version)" == "2" ] ; then
      $DSH_MASTER "
  $HADOOP_EXPORTS yes Y | $BENCH_HADOOP_DIR/bin/hdfs namenode -format;
  $HADOOP_EXPORTS yes Y | $BENCH_HADOOP_DIR/bin/hdfs datanode -format"
  
    else
      die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
    fi
  fi   
}

# Deletes from HDFS if DELETE_HDFS is set
# $1 bench name
# $2 path to folder
clean_HDFS() {
  if [ "$DELETE_HDFS" == "1" ] ; then
    hadoop_delete_path "$1" "$2"
  fi
}


# Just an alias
start_hadoop() {
  restart_hadoop
}

get_HDFS_status() {
  if [ "$(get_hadoop_major_version)" == "1" ]; then
    local report=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop dfsadmin -report 2> /dev/null")
  elif [ "$(get_hadoop_major_version)" == "2" ] ; then
    local report=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfsadmin -report 2> /dev/null")
  else
    die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
  fi
  echo -e "$report"
}

# Extracts the num of datanodes according to version number and output
# $1 report
get_num_datanodes_OK() {
  local report="$1"
  [ ! "$report" ] && die "Empty datanodes report"

  if [ "$(get_hadoop_major_version)" == "1" ]; then
    local num=$(echo "$report" | grep "Datanodes available" | awk '{print $3}')
  elif [ "$(get_hadoop_major_version)" == "2" ] ; then
    local num=$(echo "$report" | grep "Live datanodes" | awk '{print $3}')
    num="${num:1:${#num}-3}"
  else
    die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
  fi

  [ ! "$num" ] && die "Cannot extract the number of datanodes"

  echo -e "$num"
}

# Detects if in safe mode from output
# $1 report
in_safe_mode() {
  local report="$1"
  [ ! "$report" ] && die "Empty datanodes report"

  local safe_mode=$(echo "$report" | grep "Safe mode is ON")

  echo -e "$safe_mode"
}

restart_hadoop(){
  if [ "$clusterType" != "PaaS" ]; then
    logger "INFO: Restart Hadoop"
    # just in case stop all first
    stop_hadoop "" "$BENCH_LEAVE_SERVICES"

    if [ "$(get_hadoop_major_version)" == "1" ]; then
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/start-all.sh"
    elif [ "$(get_hadoop_major_version)" == "2" ] ; then
      $DSH_MASTER "$HADOOP_EXPORTS
        $BENCH_HADOOP_DIR/sbin/start-dfs.sh &
        $BENCH_HADOOP_DIR/sbin/start-yarn.sh &
        $BENCH_HADOOP_DIR/sbin/mr-jobhistory-daemon.sh start historyserver &
        wait"
    else
      die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
    fi

    for i in {0..300} ; do

      local report="$(get_HDFS_status)"

      logger "$report"

      local num="$(get_num_datanodes_OK "$report")"
      local safe_mode="$(in_safe_mode "$report")"

      # Check if we have all the needed datanodes ready, or if we are in the special case of 1 node cluster
      if [ "$num" == "$NUMBER_OF_DATA_NODES" ] || [[ "$num" == "1" && "$NUMBER_OF_DATA_NODES" == "0" ]] ; then
        if [ ! "$safe_mode" ] ; then
          #everything fine continue
          break
        elif [ "$i" == "30" ] ; then
          logger "INFO: Still in Safe mode, MANUALLY RESETTING SAFE MODE wating for $i seconds"
          if [ "$(get_hadoop_major_version)" == "1" ]; then
            $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop dfsadmin -safemode leave"
          elif [ "$(get_hadoop_major_version)" == "2" ] ; then
            $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfsadmin -safemode leave 2>&1"
          else
            die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
          fi
        else
          logger "INFO: Still in Safe mode, wating for $i seconds"
        fi
      elif [ "$i" == "60" ] && [[ -z $1 ]] ; then
        #try to restart hadoop deleting files and prepare again files
        if [ "$(get_hadoop_major_version)" == "1" ]; then
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/stop-dfs.sh" 2>&1 >> $LOG_PATH
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/stop-yarn.sh" 2>&1 >> $LOG_PATH
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver"
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/start-dfs.sh"
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/start-yarn.sh"
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/mr-jobhistory-daemon.sh start historyserver"
        elif [ "$(get_hadoop_major_version)" == "2" ] ; then
          $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfsadmin -safemode leave 2>&1"
        else
          die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
        fi
      elif [ "$i" == "180" ] && [[ -z $1 ]] ; then
        #try to restart hadoop deleting files and prepare again files
        logger "INFO: Resetting config to retry DELETE_HDFS WAS SET TO: $DELETE_HDFS"
        DELETE_HDFS="1"
        restart_hadoop no_retry
      elif [ "$i" == "120" ] ; then
        die "$num/$NUMBER_OF_DATA_NODES Datanodes available, EXIT"
      else
        logger "INFO: $num/$NUMBER_OF_DATA_NODES Datanodes available, wating for $i seconds"
        sleep 0.5
      fi
    done

    set_omm_killer

    logger "INFO: Hadoop ready"
  fi
}

get_job_list() {
  echo -e "$(execute_hadoop_new "$bench_name" "hadoop job -list|egrep \"job_[0-9_]+\"|cut -d\" \" -f2")"
}

hadoop_kill_jobs() {
  local job_list="$(get_job_list)"
  if [ "$job_list" ] ; then
    logger "WARNING: Killing hadoop jobs: $job_list"
    for job in $job_list ; do
      execute_hadoop_new "$bench_name" "hadoop job -kill $job"
    done
  else
    logger "INFO: no jobs to kill"
  fi
}

# Stops Hadoop and checks for open ports
# $1 dont retry, to prevent recursion (optional)
# $2 force stop, for use at restart (useful for -S)
stop_hadoop(){
  local dont_retry="$1"
  local force_stop="$2"

  #if [ "$clusterType=" != "PaaS" ] && [ "$DELETE_HDFS" == "1" ]; then
  if [ "$clusterType=" != "PaaS" ] && [[ ! "$BENCH_LEAVE_SERVICES" || "$force_stop" ]] && [ "$DELETE_HDFS" == "1" ] ; then
    if [ ! "$dont_retry" ] ; then
      logger "INFO: Stopping Hadoop"
    else
      logger "INFO: Stopping Hadoop (retry)"
    fi

    if [ "$(get_hadoop_major_version)" == "1" ]; then
      $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/stop-all.sh"
    elif [ "$(get_hadoop_major_version)" == "2" ] ; then
      $DSH_MASTER "
$HADOOP_EXPORTS $BENCH_HADOOP_DIR/sbin/stop-yarn.sh &
$BENCH_HADOOP_DIR/sbin/stop-dfs.sh &
$BENCH_HADOOP_DIR/sbin/mr-jobhistory-daemon.sh stop historyserver &
wait"
    else
      die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
    fi

    logger "INFO: testing Hadoop port for running processes"
    local hadoop_ports="$(get_hadoop_ports)"
    local open_port=""

    # First tell all ports together to save time
    local test_all_cmd
    local all_ports
    for port in $hadoop_ports ; do
      test_all_cmd+="lsof -i tcp:$port -s tcp:LISTEN || "
      all_ports+="$port "
    done
    logger "DEBUG: Testing for open ports in: $all_ports"
    sleep 0.5 # give some chance of stopping by themselves
    if ! test_nodes_inverse "${test_all_cmd:0:(-3)}" "WARNING" ; then
      open_port="true"
    else
      logger "DEBUG: All ports empty"
    fi

    # If any found, go one by one
    if [ "$open_port" ] ; then
      for port in $hadoop_ports ; do
        logger "DEBUG: testing port:$port"
        if ! test_nodes_inverse "lsof -i tcp:$port" "WARNING" ; then
          open_port="true"
          logger "ERROR: port:$port not empty, attempting to kill it gracefully"
          kill_on_port "$port"
        else
          logger "DEBUG: port:$port empty"
        fi
      done
    fi

    if [ "$open_port" ] && [ "$dont_retry" ] ; then
      #logger "ERROR: Please manually stop running Hadoop instances"
      die "Please manually stop running Hadoop instances"
    elif [ "$open_port" ] && [ ! "$retry" ] ; then
      stop_hadoop "dont_retry" "$BENCH_LEAVE_SERVICES"
    else
      logger "INFO: Stop Hadoop ready"
    fi
  elif [ "$clusterType=" == "PaaS" ] ; then
    log_WARN "In PaaS mode, not stopping Hadoop. But killing remaining jobs..."
    hadoop_kill_jobs
  else
    log_WARN "Not stopping Hadoop (as requested with -S or -N)."
    #hadoop_kill_jobs
  fi
}

# Performs the actual benchmark execution
# TODO old code needs cleanup
# $1 benchmark name
# $2 command
# $3 if prepare (optional)
execute_hadoop(){
  local bench="$1"
  local cmd="$2"
  local prefix="$3"

  save_disk_usage "BEFORE"

  restart_monit

  #TODO fix empty variable problem when not echoing
  local start_exec="$(timestamp)"
  local start_date="$(date --date='+1 hour' '+%Y%m%d%H%M%S')"
  logger "INFO: RUNNING ${prefix}${bench}"

  #TODO refactor
  local hadoop_exports
  if [ "$EXECUTE_HIBENCH" ] ; then
    hadoop_exports="$(get_HiBench_exports)
$(get_hadoop_exports)"
  else
    hadoop_exports="$(get_hadoop_exports)"
  fi

  logger "DEBUG: $hadoop_exports"

  $DSH_MASTER "$hadoop_exports export TIMEFORMAT='Time ${prefix}${bench} %R' && time $cmd"

  local end_exec="$(timestamp)"

  local total_secs=`calc_exec_time $start_exec $end_exec`
  logger "DONE RUNNING $bench Total time: ${total_secs}secs."

  # Save execution information in an array to allow import later
  
  EXEC_TIME["${prefix}${bench}"]="$total_secs"
  EXEC_START["${prefix}${bench}"]="$start_exec"
  EXEC_END["${prefix}${bench}"]="$end_exec"

  #url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
  #echo "SENDING: hibench.runs $end_exec <a href='$url'>${prefix}${bench} $CONF</a> <strong>Time:</strong> $total_secs s."
  #zabbix_sender "hibench.runs $end_exec <a href='$url'>${prefix}${bench} $CONF</a> <strong>Time:</strong> $total_secs s."

  stop_monit

  #save the prepare
  if [[ -z "$prefix" ]] && [ "$SAVE_BENCH" == "1" ] ; then
    logger "INFO: Saving $prefix to disk: $BENCH_SAVE_PREPARE_LOCATION"
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION"
  fi

  save_disk_usage "AFTER"

  #clean output data
  logger "INFO: Cleaning output data for $bench"
  if [[ "$bench" == "dfsioe"* ]] ; then
    local folder_in_HDFS="/benchmarks/TestDFSIO-Enh/Output"
  else
    local folder_in_HDFS="/HiBench/$(get_bench_name "$bench")/Output"
  fi

  if [ "$(get_hadoop_major_version)" == "1" ]; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -rmr -skipTrash $folder_in_HDFS"
  elif [ "$(get_hadoop_major_version)" == "2" ] ; then
    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r -skipTrash $folder_in_HDFS"
  else
    die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
  fi

  save_hadoop "${3}${1}"
}

# Returns the the path to the hadoop binary with the proper exports
# $1 dont include exports (optional)
# $2 use a different bin than hadoop ie. hdfs (optional)
get_hadoop_cmd() {
  local dont_include_exports="$1"
  local use_bin="${2:-hadoop}"
  local hadoop_exports
  local hadoop_cmd
  local hadoop_bin
  local chuser

  if [[ "$BENCH_HADOOP_DISTRO" == "cloudera" || "$BENCH_HADOOP_DISTRO" == "HDP" ]] ; then
    chuser="sudo -iu hdfs "
  fi

  # if in PaaS use the bin in PATH
  if [ "$clusterType" == "PaaS" ]; then
    hadoop_exports=""
    hadoop_bin="${chuser}${use_bin}"
  else
    if [ ! "$dont_include_exports" ] ; then
      #TODO refactor
      if [ "$EXECUTE_HIBENCH" ] ; then
        hadoop_exports="$(get_HiBench_exports)
$(get_hadoop_exports)"
      else
        hadoop_exports="$(get_hadoop_exports)"
      fi
    fi

    hadoop_bin="${chuser}$BENCH_HADOOP_DIR/bin/${use_bin}"
  fi

  if [ "$hadoop_exports" ] ; then
    hadoop_cmd="$hadoop_exports\n$hadoop_bin"
  else
    hadoop_cmd="$hadoop_bin"
  fi

  echo -e "$hadoop_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
# $4 chdir (optional) if supplied it will do a cd to that path
execute_hadoop_new(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local chdir
  [ "$4" ] && local chdir="cd $4; "

  local hadoop_cmd="${chdir}$(get_hadoop_cmd) $cmd"

  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity before" "${chdir}$(get_hadoop_cmd) fs -df"
  fi

  # Run the command and time it
  execute_master "$bench" "$hadoop_cmd" "$time_exec" "dont_save"

  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity after" "${chdir}$(get_hadoop_cmd) fs -df"
    save_hadoop "$bench"
  fi
}

# Deletes a file or directory recursively in HDFS
# $1 bench name
# $2 delete cmd
hadoop_delete_path() {
  local bench_name="$1"
  local path_to_delete="$2"

  if [ "$(get_hadoop_major_version)" == "2" ]; then
    local delete_cmd="-rm -r -f -skipTrash"
  else
    local delete_cmd="-rmr -skipTrash"
  fi

  execute_hadoop_new "$bench_name: deleting $path_to_delete" "fs $delete_cmd $path_to_delete"
}

# Copy file to HDFS
# $1 Destiny folder
# $2 Origin local folder
hadoop_copy_hdfs() {
  logger "INFO: Copying $2 from local $1 into HDFS"
  $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -mkdir $1"
  $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -copyFromLocal $2 $1"
  $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -ls $1"
}
#
#
#execute_hdi_hadoop() {
#  save_disk_usage "BEFORE"
#
#  restart_monit
#
#  #TODO fix empty variable problem when not echoing
#  local start_exec=`timestamp`
#  local start_date=$(date --date='+1 hour' '+%Y%m%d%H%M%S')
#  logger "INFO: # EXECUTING ${3}${1}"
#  local HADOOP_EXECUTABLE=hadoop
#  local HADOOP_EXAMPLES_JAR=/home/pristine/hadoop-mapreduce-examples.jar
#  if [ "$defaultProvider" == "rackspacecbd" ]; then
#    HADOOP_EXECUTABLE='sudo -u hdfs hadoop'
#    HADOOP_EXAMPLES_JAR=/usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples.jar
#  fi
#
#  #need to send all the environment variables over SSH
#  EXP="export JAVA_HOME=$JAVA_HOME && \
#export HADOOP_HOME=/usr/hdp/2.*/hadoop && \
#export HADOOP_EXECUTABLE='$HADOOP_EXECUTABLE' && \
#export HADOOP_CONF_DIR=/etc/hadoop/conf && \
#export HADOOP_EXAMPLES_JAR='$HADOOP_EXAMPLES_JAR' && \
#export MAPRED_EXECUTABLE=ONLY_IN_HADOOP_2 && \
#export HADOOP_VERSION=$HADOOP_VERSION && \
#export COMPRESS_GLOBAL=$COMPRESS_GLOBAL && \
#export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL && \
#export COMPRESS_CODEC_MAP=$COMPRESS_CODEC_MAP && \
#export NUM_MAPS=$NUM_MAPS && \
#export NUM_REDS=$NUM_REDS && \
#export DATASIZE=$DATASIZE && \
#export PAGES=$PAGES && \
#export CLASSES=$CLASSES && \
#export NGRAMS=$NGRAMS && \
#export RD_NUM_OF_FILES=$RD_NUM_OF_FILES && \
#export RD_FILE_SIZE=$RD_FILE_SIZE && \
#export WT_NUM_OF_FILES=$WT_NUM_OF_FILES && \
#export WT_FILE_SIZE=$WT_FILE_SIZE && \
#export NUM_OF_CLUSTERS=$NUM_OF_CLUSTERS && \
#export NUM_OF_SAMPLES=$NUM_OF_SAMPLES && \
#export SAMPLES_PER_INPUTFILE=$SAMPLES_PER_INPUTFILE && \
#export DIMENSIONS=$DIMENSIONS && \
#export MAX_ITERATION=$MAX_ITERATION && \
#export NUM_ITERATIONS=$NUM_ITERATIONS && \
#"
#
#  $DSH_MASTER "$EXP export TIMEFORMAT='Time ${3}${1} %R' && time $2"
#
#  local end_exec=`timestamp`
#
#  logger "INFO: # DONE EXECUTING $1"
#
#  local total_secs=`calc_exec_time $start_exec $end_exec`
#  echo "end total sec $total_secs"
#
#  # Save execution information in an array to allow import later
#
#  EXEC_TIME[${3}${1}]="$total_secs"
#  EXEC_START[${3}${1}]="$start_exec"
#  EXEC_END[${3}${1}]="$end_exec"
#
#  url="http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=${start_date}&period=${total_secs}"
#  echo "SENDING: hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."
#  zabbix_sender "hibench.runs $end_exec <a href='$url'>${3}${1} $CONF</a> <strong>Time:</strong> $total_secs s."
#
#
#  stop_monit
#
#  #save the prepare
#  if [[ -z $3 ]] && [ "$SAVE_BENCH" == "1" ] ; then
#    logger "INFO: Saving $3 to disk: $BENCH_SAVE_PREPARE_LOCATION"
#    $DSH_MASTER hadoop fs -get -ignoreCrc /HiBench $BENCH_SAVE_PREPARE_LOCATION
#  fi
#
#  save_disk_usage "AFTER"
#
#  #TODO should move to cleanup function
#  #clean output data
#  logger "INFO: Cleaning output data for $bench"
#  $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -rmr /HiBench/$(get_bench_name "$1")/Output"
#
#  save_hadoop "${3}${1}"
#}

# $1 bench name
save_hadoop() {
  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Just in case make sure dir is created first
  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/hadoop_logs/history;"
  execute_master "$bench_name" "mkdir -p $JOB_PATH/$bench_name_num/hadoop_logs/applications;"

  # Save hadoop logs
  # Hadoop 2 saves job history to HDFS, get it from there
  if [ "$clusterType" == "PaaS" ]; then
    if [ "$defaultProvider" == "rackspacecbd" ]; then

        sudo su hdfs -c "hdfs dfs -chmod -R 777 /mr-history"
        hdfs dfs -copyToLocal "/mr-history" "$JOB_PATH/$bench_name_num/hadoop_logs"
        sudo su hdfs -c "hdfs dfs -rm -r -skipTrash /mr-history/*"
        sudo su hdfs -c "hdfs dfs -expunge"

    elif [ "$defaultProvider" == "hdinsight" ]; then

        hdfs dfs -copyToLocal "/mr-history" "$JOB_PATH/$bench_name_num/hadoop_logs"
        hdfs dfs -rm -r -skipTrash "/mr-history"
        hdfs dfs -expunge

        headnode=$(echo $master_name | sed -r 's/[0]+/1/g') #Create the name of the second headnode (it stores the yarn-resourcemanager log)

        #Copy local YARN logs
        if [ "$BENCH_LEAVE_SERVICES" ] ; then

          execute_all "$bench_name" "cp -ru /var/log/hadoop-yarn/yarn/* $JOB_PATH/$bench_name_num/hadoop_logs"
          rsync -avur $headnode:/var/log/hadoop-yarn/yarn/* $JOB_PATH/$bench_name_num/hadoop_logs
          execute_all "$bench_name" "sudo cp -r /mnt/resource/hadoop/yarn/log/* $JOB_PATH/$bench_name_num/hadoop_logs"

        else

          #Yarn logs are created only once, they cannot be eliminated as they won't pop up again. Userlogs contains application specific logs, can be eliminated
          execute_all "$bench_name" "cp -ru /var/log/hadoop-yarn/yarn/* $JOB_PATH/$bench_name_num/hadoop_logs"
          rsync -avur $headnode:/var/log/hadoop-yarn/yarn/* $JOB_PATH/$bench_name_num/hadoop_logs

          cmd="for file in /var/log/hadoop-yarn/yarn/* ; do
            sudo cp /dev/null \$file
          done"

          execute_all "$bench_name" "$cmd"
          ssh $headnode "for file in /var/log/hadoop-yarn/yarn/*.{log,out} ; do sudo cp /dev/null \$file; done"

          #copy container logs
          execute_all "$bench_name" "sudo rsync -avu /mnt/resource/hadoop/yarn/log/* $JOB_PATH/$bench_name_num/hadoop_logs/applications --remove-source-files &&
          sudo rm -rf /mnt/resource/hadoop/yarn/log/*"

        fi
    fi
  else

    #we cannot move hadoop files
    #take into account naming *.date when changing dates
    #$DSH "cp $HDD/logs/hadoop-*.{log,out}* $JOB_PATH/$bench_name_num/"
    #$DSH "cp -r ${BENCH_HADOOP_DIR}/logs/* $JOB_PATH/$bench_name_num/ 2> /dev/null"
  # Hadoop 2 saves job history to HDFS, get it from there and then delete

      if [ "$(get_hadoop_major_version)" == "2" ] && [ "$clusterType=" != "PaaS" ]; then
        ##Copy history logs
        logger "INFO: Getting mapreduce job history logs from HDFS"
        execute_master "$bench_name" "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -copyToLocal $(get_local_bench_path)/hadoop_logs/history $JOB_PATH/$bench_name_num/hadoop_logs/history"
        execute_master "$bench_name" "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r -skipTrash $(get_local_bench_path)/hadoop_logs/history"

        ##Copy jobhistory daemon logs
        logger "INFO: Moving jobhistory daemon logs to logs dir"
        execute_master "$bench_name" "mv $BENCH_HADOOP_DIR/*.log $(get_local_bench_path)/hadoop_logs/history"
        #logger "INFO: Deleting history files after copy to local"

    #    $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hdfs dfs -rm -r /tmp/hadoop-yarn/staging/history"
      fi

      if [ "$EXECUTE_HIBENCH" == "true" ]; then
        #$DSH "cp $HADOOP_DIR/conf/* $JOB_PATH/$bench_name_num"
        $DSH_MASTER  "mv $BENCH_HIB_DIR/$bench/hibench.report  $JOB_PATH/$bench_name_num/hadoop_logs"
      fi

      #logger "INFO: Copying files to master == scp -r $JOB_PATH $MASTER:$JOB_PATH"
      #$DSH "scp -r $JOB_PATH $MASTER:$JOB_PATH"
      #pending, delete

      # Save sysstat data for instrumentation
      if [ "$INSTRUMENTATION" == "1" ] ; then
        $DSH "mkdir -p $JOB_PATH/traces"
        $DSH "cp $JOB_PATH/$bench_name_num/sar*.sar $JOB_PATH/traces/"
      fi

      #Copy local YARN logs ALWAYS
      if [ "$BENCH_LEAVE_SERVICES" ] ; then
         execute_all "$bench_name" "cp -ru $(get_local_bench_path)/hadoop_logs/* $JOB_PATH/$bench_name_num/hadoop_logs"
      else

         #Yarn logs are created only once, they cannot be eliminated as they won't pop up again. Userlogs contains application specific logs, can be eliminated
         execute_all "$bench_name" "cp -ru $(get_local_bench_path)/hadoop_logs/* $JOB_PATH/$bench_name_num/hadoop_logs"
         execute_all "$bench_name" "rm -r $(get_local_bench_path)/hadoop_logs/userlogs"

         cmd="for file in $(get_local_bench_path)/hadoop_logs/*.{log,out} ; do
                :> \$file
              done"

         execute_all "$bench_name" "$cmd"
      fi
  fi

  logger "INFO: Compresing and deleting hadoop configs for $bench_name_num"

  cmd="
    cd $JOB_PATH;
    if [ \"\$(ls conf_* 2> /dev/null)\" ] ; then
    tar -cjf $JOB_PATH/hadoop_host_conf.tar.bz2 conf_*;
    rm -rf conf_*;
    fi
  "
  execute_master "$bench_name" "$cmd"

  # save defaults
  save_bench "$bench_name"
}

clean_hadoop() {
  if [ ! "$BENCH_LEAVE_SERVICES" ] && [ "$clusterType" != "PaaS" ]; then
    stop_hadoop
  fi
}
