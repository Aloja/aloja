#common functions fro aloja-import2db.sh

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#CREATE TABLE AND LOAD VALUES FROM CSV FILE
# $1 TABLE NAME $2 PATH TO CSV FILE $3 DROP THE DB FIRST $4 DELIMITER $5 DB
insert_DB(){

  echo "Inserting into DB $sar_file TN $1"

  if [[ $(head "$2"|wc -l) > 1 ]] ; then
    echo "Loading $2 into $1"
head -n3 "$2"

#tx levels READ UNCOMMITTED READ-COMMITTED
    $MYSQL "
    SET time_zone = '+00:00';
    SET tx_isolation = 'READ-COMMITTED';
    SET GLOBAL tx_isolation = 'READ-COMMITTED';

    LOAD DATA LOCAL INFILE '$2' INTO TABLE $1
    FIELDS TERMINATED BY '$4' OPTIONALLY ENCLOSED BY '\"'
    IGNORE 1 LINES;"
    echo -e "Loaded $2 into $1\n"

  else
    echo "EMPTY CSV FILE FOR $csv_name $(cat $csv_name)"
  fi

  rm $2
}


#$1 id_cluster
get_clusterConfigFile() {
  local clusterConfigFile="$(find $CUR_DIR_TMP/../conf/ -type f -name cluster_*-$1.conf)"
  echo "$clusterConfigFile";
}

#$1 id_cluster $2 clusterConfigFile (optional)
get_insert_cluster_sql() {

  if [ "$2" ] ; then
    local clusterConfigFile="$2"
  else
    local clusterConfigFile="$(get_clusterConfigFile)"
  fi

  if [ -f "$clusterConfigFile" ] ; then

    source "$clusterConfigFile"

    #load the providers specific functions and overrrides
    providerFunctionsFile="$CUR_DIR_TMP/../../aloja-deploy/providers/${defaultProvider}.sh"

    source "$providerFunctionsFile"

    local sql="
INSERT into aloja2.clusters  set
      name='$clusterName', id_cluster='$clusterID', cost_hour='$clusterCostHour', cost_remote='$clusterCostDisk', cost_SSD='$clusterCostSSD', cost_IB='$clusterCostIB', type='$clusterType', link='',
      provider='$defaultProvider', datanodes='$numberOfNodes', headnodes='1', vm_size='$vmSize', vm_OS='$vmType', vm_cores='$vmCores', vm_RAM='$vmRAM', description='$clusterDescription'
ON DUPLICATE KEY UPDATE
      name='$clusterName', id_cluster='$clusterID', cost_hour='$clusterCostHour', cost_remote='$clusterCostDisk', cost_SSD='$clusterCostSSD', cost_IB='$clusterCostIB', type='$clusterType', link='',
      provider='$defaultProvider', datanodes='$numberOfNodes', headnodes='1', vm_size='$vmSize', vm_OS='$vmType', vm_cores='$vmCores', vm_RAM='$vmRAM', description='$clusterDescription';\n"

    local nodeName="$(get_master_name)"
    sql+="insert ignore into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='master';\n"

    for nodeName in $(get_slaves_names) ; do
      sql+="insert ignore into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='slave';\n"
    done

    echo -e "$sql\n"
    else
       logger "ERROR: cannot find cluster file: $clusterConfigFile"
    fi
}

#$1 folder $2 $folder_OK
move2done() {

  if [ "$1" ] && [ "$2" ] ; then
    mkdir -p "$BASE_DIR/DONE"
    mkdir -p $BASE_DIR/FAIL/{0..3}
    if (( "$2" >= 3 )) ; then
      logger "OK=$2 Moving folder $1 to DONE"
      cp -ru "$BASE_DIR/$1" "$BASE_DIR/DONE/"
      rm -rf "$BASE_DIR/$1"
    else
      logger "OK=$2 Moving $1 to FAIL/$2 for manual check"
      cp -ru "$BASE_DIR/$1" "$BASE_DIR/FAIL/$2/"
      rm -rf "$BASE_DIR/$1"
    fi
  fi
}

get_filter_sql() {
  echo "
#Re-updates filters for the whole DB, normally it is done after each insert

#filter, execs that don't have any Hadoop details

update ignore aloja2.execs SET filter = 0;
update ignore aloja2.execs SET filter = 1 where bench like 'HiBench%' AND id_exec  NOT IN(select distinct (id_exec) FROM aloja_logs.JOB_status where id_exec is not null);

#perf_detail, aloja2.execs without perf counters

update ignore aloja2.execs SET perf_details = 0;
update ignore aloja2.execs SET perf_details = 1 where id_exec IN(select distinct (id_exec) from aloja_logs.SAR_cpu where id_exec is not null);

#valid, set everything as valid, exept the ones that do not match the following rules
update ignore aloja2.execs SET valid = 1;
update ignore aloja2.execs SET valid = 0 where bench_type = 'HiBench' and bench = 'terasort' and id_exec NOT IN (
  select distinct(id_exec) from
    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore aloja2.execs e INNER JOIN (SELECT id_exec,IFNULL(SUM(js.reduce),0) as 'suma' FROM aloja2.execs e2 left JOIN aloja_logs.JOB_status js USING (id_exec) WHERE  e2.bench NOT LIKE 'prep%' GROUP BY id_exec) i using(id_exec) SET valid = 0 WHERE  suma < 1;


#azure VMs
update ignore aloja2.clusters  SET vm_size='A3' where vm_size IN ('large', 'Large');
update ignore aloja2.clusters  SET vm_size='A2' where vm_size IN ('medium', 'Medium');
update ignore aloja2.clusters  SET vm_size='A4' where vm_size IN ('extralarge', 'Extralarge');
update ignore aloja2.clusters  SET vm_size='D4' where vm_size IN ('Standard_D4');

##HDInsight filters
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set valid = 0 where type != 'PaaS' AND exec LIKE '%hdi%';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set valid = 1, filter = 0 where provider = 'hdinsight';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time < 700 OR id_cluster =25 AND YEAR(start_time) = '2014';
update ignore aloja2.execs set id_cluster=25 where exec like '%alojahdi32%' AND YEAR(start_time) = '2014';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time>5000 AND YEAR(start_time) = '2014';
update ignore aloja2.execs set bench_type = 'HiBench-1TB' where id_cluster IN (20,23,24,25) AND exe_time > 10000 AND bench = 'terasort' AND YEAR(start_time) = '2014';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench_type = 'HDI' AND bench = 'terasort' AND exe_time > 5000 AND YEAR(start_time) = '2014';
update ignore aloja2.execs set bench_type = 'HiBench' where id_cluster IN (20,23,24,25) AND bench_type = 'HDI' AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 24 AND bench = 'terasort' AND exe_time > 900 AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 23 AND bench = 'terasort' AND exe_time > 1100 AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 20 AND bench = 'terasort' AND exe_time > 2300 AND YEAR(start_time) = '2014';

update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set exec_type = 'experimental' where exec_type = 'default' and vm_OS = 'linux' and comp != 0 and provider = 'hdinsight' and start_time < '2015-05-22';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set exec_type = 'default' where exec_type != 'default' and vm_OS = 'linux' and comp = 0 and provider = 'hdinsight' and start_time < '2015-05-22';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set disk = 'RR1' where disk != 'RR1' and provider = 'hdinsight' and start_time < '2015-05-22';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set filter = 1 where type = 'PaaS' and provider = 'hdinsight' and exe_time < 100;
update ignore aloja2.execs set filter = 1 where bench IN ('prep_terasort-t','terasort-t','prep_wordcount,terasort','wordcount,terasort');

#Wrong imports filter
update ignore aloja2.execs set filter = 1 where (iosf IS NULL or iosf=0 or iofilebuf IS NULL or iofilebuf=0 OR blk_size IS NULL or iofilebuf = 0 OR replication IS NULL or replication = 0 or comp IS NULL) and valid = 1 and filter = 0;

##Datasize and scale factor
update ignore aloja2.execs set datasize = NULL;
update ignore aloja2.execs set scale_factor = 'N/A';

update ignore aloja2.execs e JOIN JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.HDFS_BYTES_READ where c.type != 'PaaS' and bench != 'terasort';
update ignore aloja2.execs e JOIN HDI_JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.WASB_BYTES_READ where c.type = 'PaaS' and bench != 'terasort';

update ignore aloja2.execs e JOIN JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.HDFS_BYTES_WRITTEN where c.type != 'PaaS' and bench = 'terasort';
update ignore aloja2.execs e JOIN HDI_JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.WASB_BYTES_WRITTEN where c.type = 'PaaS' and bench = 'terasort';

update ignore aloja2.execs e set e.scale_factor = '32GB/Dn' where e.bench='wordcount' and e.bench_type LIKE 'HiBench%';

update ignore aloja2.execs e set e.scale_factor='24GB/Dn' where e.bench='sort' and e.bench_type LIKE 'HiBench%';

update ignore aloja2.execs set bench_type = 'HiBench' where bench_type LIKE 'HiBench-%';
update ignore aloja2.execs set bench_type = 'HiBench3' where bench_type LIKE 'HiBench3-%';
"

#update ignore aloja2.execs SET valid = 1 where bench_type = 'HiBench' and bench = 'sort' and id_exec IN (
#  select distinct(id_exec) from
#    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'sort' and HDFS_BYTES_WRITTEN between '73910080224' and '73910985034')
#    tmp_table
#);

}


#$1 id_exec
get_filter_sql_exec() {
  if [ "$1" ] ; then
    echo "
#Updates filters for an id_exec

#filter, execs that don't have any Hadoop details

update ignore aloja2.execs SET filter = 0 where id_exec = '$1' AND bench like 'HiBench%';
update ignore aloja2.execs SET filter = 1 where id_exec = '$1' AND bench like 'HiBench%' AND id_exec NOT IN(select distinct (id_exec) FROM aloja_logs.JOB_status where id_exec = '$1' AND id_exec is not null);

#perf_detail, aloja2.execs without perf counters

update ignore aloja2.execs SET perf_details = 0 where id_exec = '$1';
update ignore aloja2.execs SET perf_details = 1 where id_exec = '$1' AND id_exec IN(select distinct (id_exec) from aloja_logs.SAR_cpu where id_exec = '$1' AND id_exec is not null);

#valid, set everything as valid, exept the ones that do not match the following rules
update ignore aloja2.execs SET valid = 1 where id_exec = '$1' ;
update ignore aloja2.execs SET valid = 0 where id_exec = '$1' AND bench_type = 'HiBench' and bench = 'terasort' and id_exec NOT IN (
  select distinct(id_exec) from
    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where id_exec = '$1' AND bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore aloja2.execs e INNER JOIN (SELECT id_exec,IFNULL(SUM(js.reduce),0) as 'suma' FROM aloja2.execs e2 left JOIN aloja_logs.JOB_status js USING (id_exec) WHERE e2.id_exec = '$1' AND  e2.bench NOT LIKE 'prep%' GROUP BY id_exec) i using(id_exec) SET valid = 0 WHERE e.id_exec = '$1' AND  suma < 1;


"

#update ignore aloja2.execs SET valid = 1 where bench_type = 'HiBench' and bench = 'sort' and id_exec IN (
#  select distinct(id_exec) from
#    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'sort' and HDFS_BYTES_WRITTEN between '73910080224' and '73910985034')
#    tmp_table
#);
  fi

}

# Gets the configuration for the benchmark for both legacy format (from folder name)
# $1 log_file path
legacy_get_exec_params() {
  #here get the zabbix URL to parse filtering prepares and other benchmarks
  #|grep -v -e 'prep_' -e 'b_min_' -e 'b_10_'|
  local exec_params="$(grep  -e 'href'  "$1" |grep 8099 |\
  awk -v exec=$2 ' \
  { pri_bar = (index($1,"/")+1); \
  conf = substr($1, 0, (pri_bar-2));\
  pri_mas = (index($5,">")-7);\
  time_pos = (index($5,"&stime=")+7);\
  split(exec, parts,"_"); \
  bench = substr($5,(pri_mas+8));\
  zt = substr($5,(time_pos),14);\
  \
  if ( $(NF-1) ~  /^[0-9]*$/ && $(NF-1) > 1)\
  print \
  "\"" bench "\",\"" \
  $(NF-1) "\",\"" \
  strftime("%F %H:%M:%S", ($3-$(NF-1)), 1) "\",\""\
  strftime("%F %H:%M:%S", $3, 1) "\",\""\
  parts[4]"\",\"" \
  parts[5]"\",\"" \
  substr(parts[6],2)"\",\"" \
  substr(parts[7],2)"\",\"" \
  substr(parts[8],2)"\",\"" \
  substr(parts[9],2)"\",\"" \
  substr(parts[10],2)"\",\"" \
  substr(parts[11],2)"\",\"" \
  substr(parts[12],2) "\",\"" \
  substr($5,7,(pri_mas-1)) "\"" \
  } \
  ' )"

  echo -e "$exec_params"
}

# Gets the configuration for the benchmark
# for both legacy format (from folder name)
# and newer, from config.sh
# $1 log_file path
# $2 name
get_exec_params() {

  local log_file="$1"
  local name="$2"

  local exec_params

  # output format:
  # "wordcount","2286","2015-03-17 20:47:41","2015-03-17 21:25:47","ETH","RL3","","4","10","1","65536","0","64","http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=AZ&stime=20150317214741&period=2286"
  # "job","exe_time","start_time","end_time","net","disk","bench","maps","iosf","replication","iofilebuf","comp","blk_size","zabbix_link"

  # different parsers for legacy-style and new-style configs
  if [ "${name:15:6}" == "_conf_" ]; then
    exec_params="$(legacy_get_exec_params "$log_file")"
  else

    local job=""
    local exe_time=""
    local start_time=""
    local end_time=""
    local net=$(extract_config_var "NET")
    local disk=$(extract_config_var "DISK")
    local bench=$(extract_config_var "BENCH")
    local maps=$(extract_config_var "MAX_MAPS")
    local iosf=$(extract_config_var "IO_FACTOR")
    local replication=$(extract_config_var "REPLICATION")
    local iofilebuf=$(extract_config_var "IO_FILE")
    local comp=$(extract_config_var "COMPRESS_TYPE")
    local blk_size=$(extract_config_var "BLOCK_SIZE")
    local exec_type=$(extract_config_var "EXEC_TYPE")
    #legacy, exec type didn't exist until May 18th 2015
    if [[ exec_type == "" ]]; then
      exec_type="default"
    fi

    blk_size=$((blk_size / 1048576 ))
    local zabbix_link=""
    hadoop_version=$(extract_config_var "HADOOP_VERSION")
    # Remove "hadoop" string from version: "hadoop2" -> "2"
    hadoop_version="${hadoop_version//hadoop}"

    # load arrays
    local temp_array
    temp_array=$(extract_config_var "EXEC_TIME")
    temp_array="exec_time=$temp_array"
    declare -A exec_time
    eval $temp_array
    temp_array=$(extract_config_var "EXEC_START")
    temp_array="exec_start=$temp_array"
    declare -A exec_start
    eval $temp_array
    temp_array=$(extract_config_var "EXEC_END")
    temp_array="exec_end=$temp_array"
    declare -A exec_end
    eval $temp_array

    for index in "${!exec_time[@]}"; do
      # Add a new line if there is something before
      if [ "$exec_params" != "" ]; then
        exec_params="${exec_params}"$'\n'
      fi

      job="$index"
      exe_time="${exec_time[$index]}"
      start_time="${exec_start[$index]}"
      start_time=$(date -d @$((start_time / 1000)) +"%F %H:%M:%S")  # convert to seconds and format
      end_time="${exec_end[$index]}"
      end_time=$(date -d @$((end_time / 1000)) +"%F %H:%M:%S")  # convert to seconds and format

      exec_params="$exec_params\"$job\",\"$exe_time\",\"$start_time\",\"$end_time\",\"$net\",\"$disk\",\"$bench\",\"$maps\",\"$iosf\",\"$replication\",\"$iofilebuf\",\"$comp\",\"$blk_size\",\"$zabbix_link\",\"$hadoop_version\",\"$exec_type\""
    done

  fi

  echo -e "$exec_params"

#echo -e "$1\n$exec_params"

  # Time from Zabbix format
  # substr(zt,0,4) "-" substr(zt,5,2) "-" substr(zt,7,2) " " substr(zt,9,2) ":" substr(zt,11,2) ":" substr(zt,13,2) "\",\"" \
}

extract_config_var() {
  local value=$(cat config.sh | grep -E "^$1=" | cut -d= -f2-)
  echo "$value"
}

get_id_exec(){

  if [ "$REDO_ALL" ] ; then
    local filter=""
  else
    local filter="AND id_exec NOT IN (select distinct (id_exec) from aloja_logs.SAR_cpu where id_exec is not null ) #and host not like '%-1001'"
  fi

  local query="SELECT id_exec FROM aloja2.execs WHERE exec = '$1' $filter LIMIT 1;"

  #logger "GET ID EXEC query: $query"

  echo "$($MYSQL "$query"| tail -n 1)"
}


get_id_exec_conf_params(){
    id_exec_conf_params=$($MYSQL "SELECT id_exec FROM aloja2.execs WHERE exec = '$1'
    AND id_exec NOT IN (select distinct (id_exec) from execs_conf_parameters where id_exec is not null)
    LIMIT 1;"| tail -n 1)
}

insert_conf_params_DB(){
	job_name=$3;
	id_exec=$2;
	params=$1;
	for param in $params ; do
		param_name=$(echo $param | cut -d= -f1)
		param_value=$(echo $param | cut -d= -f2)
		insert="INSERT INTO execs_conf_parameters (id_execs_conf_parameters, id_exec, job_name, parameter_name, parameter_value)
			VALUES(NULL, $id_exec, \"$job_name\", \"$param_name\", \"$param_value\" );"
		$MYSQL "$insert";
	done
}

get_job_confs() {

  id_exec_conf_params=""
  get_id_exec_conf_params "$exec"

  logger "Attempting to get XML configuration for ID get_id_exec_conf_params"
  if [[ ! -z "$id_exec_conf_params" ]] ; then
    jobconfs=""
    #get Haddop conf files which are NOT jobs of prep
    if [ -d "prep_$bench_folder" ]; then
      #1st: get jobs in prep
      cd ../"prep_$bench_folder"
      prepjobs=$(find "./history" -type f -name "job*.xml");
      #2nd: get jobs in bench folder
      cd ../$bench_folder
      jobconfs=$(find "./history" -type f -name "job*.xml");
      #3rd: 2 files, with one line per job in bench folder and prep folder
      echo $jobconfs | tr ' ' '\n' > file.tmp
      echo $prepjobs | tr ' ' '\n' > file2.tmp
      #4rd: strip jobs in prep folder and cleanup
      jobconfs=$(grep -v -f file2.tmp file.tmp)
      rm file.tmp file2.tmp
    else
      logger "Not prep folder, considering all confs belonging to exec"
      jobconfs=$(find "./history/done" -type f -name "job*.xml");
    fi

    #Dump parameters from valid conf files to DB
    for job_conf in $jobconfs ; do
      params=$($CUR_DIR/getconf_param.sh -f $job_conf);
      filename=$(basename "$job_conf")
      job_name="${filename%.*}"
      job_name="${job_name:0:(-5)}"
      insert_conf_params_DB "$params" "$id_exec_conf_params" "$job_name"
    done

  else
    logger "ERROR: cannot get id_exec for $bench_folder"
  fi
}

#$1 job jhist $2 do not run aloja-tools.jar (already having tasks.out and globals.out)
import_hadoop2_jhist() {
    if [ -z $2 ]; then
        java -cp "$CUR_DIR/../aloja-tools/lib/aloja-tools.jar" alojatools.JhistToJSON $1 tasks.out globals.out
    fi
    jobTimestamp=${array[2]}
    jobName="`$CUR_DIR/../aloja-tools/jq -r '.job_name' globals.out`"
    jobId="`$CUR_DIR/../aloja-tools/jq '.JOB_ID' globals.out`"
    startTime="`$CUR_DIR/../aloja-tools/jq -r '.LAUNCH_TIME' globals.out`"
    startTimeTS="`expr $startTime / 1000`"
    finishTime="`$CUR_DIR/../aloja-tools/jq -r '.FINISH_TIME' globals.out`"
    finishTimeTS="`expr $finishTime / 1000`"
    totalTime="`expr $finishTime - $startTime`"
    totalTime="`expr $totalTime / 1000`"
    startTime=`date -d @$startTimeTS +"%Y-%m-%d %H:%M:%S"`
    finishTime=`date -d @$finishTimeTS +"%Y-%m-%d %H:%M:%S"`

    ##In hadoop 2 usually some bench names are cut or capitalized
    if [[ "$jobName" =~ "word" ]]; then
	    jobName="wordcount"
	fi

	if [ "$jobName" == "random-text-writer" ]; then
		jobName="prep_wordcount"
	fi
	if [[ "$jobName" =~ "TeraGen" ]]; then
		jobName="prep_terasort"
	fi
	if [[ "$jobName" =~ "TeraSort" ]]; then
		jobName="terasort"
	fi

	values=`$CUR_DIR/../aloja-tools/jq -S '' globals.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	insert="INSERT INTO HDI_JOB_details SET id_exec=$id_exec,${values%?}
		        ON DUPLICATE KEY UPDATE
		    LAUNCH_TIME=`$CUR_DIR/../aloja-tools/jq '.["LAUNCH_TIME"]' globals.out`,
		    FINISH_TIME=`$CUR_DIR/../aloja-tools/jq '.["SUBMIT_TIME"]' globals.out`;"
    logger "$insert"

	$MYSQL "$insert"

    local result=`$MYSQL "select count(*) FROM aloja_logs.JOB_status JOIN aloja2.execs e USING (id_exec) where e.id_exec=$id_exec" -N`
	if [ -z "$ONLY_META_DATA" ] && [ "$result" -eq 0 ]; then
		waste=()
		reduce=()
		map=()
		for i in `seq 0 1 $totalTime`; do
			waste[$i]=0
			reduce[$i]=0
			map[$i]=0
		done

		runnignTime=`expr $finishTimeTS - $startTimeTS`
		read -a tasks <<< `$CUR_DIR/../aloja-tools/jq -r 'keys' tasks.out | sed 's/,/\ /g' | sed 's/\[/\ /g' | sed 's/\]/\ /g'`
		for task in "${tasks[@]}" ; do
			taskId=`echo $task | sed 's/"/\ /g'`
			taskStatus=`$CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_STATUS" tasks.out`
			taskType=`$CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_TYPE" tasks.out`
			taskStartTime=`$CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_START_TIME" tasks.out`
			taskFinishTime=`$CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_FINISH_TIME" tasks.out`
			taskStartTime=`expr $taskStartTime / 1000`
			taskFinishTime=`expr $taskFinishTime / 1000`
			values=`$CUR_DIR/../aloja-tools/jq --raw-output ".$task" tasks.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`

			insert="INSERT INTO aloja_logs.HDI_JOB_tasks SET TASK_ID=$task,JOB_ID=$jobId,id_exec=$id_exec,${values%?}
							ON DUPLICATE KEY UPDATE JOB_ID=JOB_ID,${values%?};"

			logger "$insert"
			$MYSQL "$insert"

			normalStartTime=`expr $taskStartTime - $startTimeTS`
			normalFinishTime=`expr $taskFinishTime - $startTimeTS`
			if [ "$taskStatus" == "FAILED" ]; then
				waste[$normalStartTime]=$(expr ${waste[$normalStartTime]} + 1)
				waste[$normalFinishTime]=$(expr ${waste[$normalFinishTime]} - 1)
			elif [ "$taskType" == "MAP" ]; then
				map[$normalStartTime]=$(expr ${map[$normalStartTime]} + 1)
				map[$normalFinishTime]=$(expr ${map[$normalFinishTime]} - 1)
			elif [ "$taskType" == "REDUCE" ]; then
				reduce[$normalStartTime]=$(expr ${reduce[$normalStartTime]} + 1)
				reduce[$normalFinishTime]=$(expr ${reduce[$normalFinishTime]} - 1)
			fi
		done
		for i in `seq 0 1 $totalTime`; do
			if [ $i -gt 0 ]; then
				previous=$(expr $i - 1)
				map[$i]=$(expr ${map[$i]} + ${map[$previous]})
				reduce[$i]=$(expr ${reduce[$i]} + ${reduce[$previous]})
				waste[$i]=$(expr ${waste[$i]} + ${waste[$previous]})
			fi
			currentTime=`expr $startTimeTS + $i`
			currentDate=`date -d @$currentTime +"%Y-%m-%d %H:%M:%S"`
			insert="INSERT INTO aloja_logs.JOB_status(id_exec,job_name,JOBID,date,maps,shuffle,merge,reduce,waste)
					VALUES ($id_exec,'$exec',$jobId,'$currentDate',${map[$i]},0,0,${reduce[$i]},${waste[$i]})
					ON DUPLICATE KEY UPDATE waste=${waste[$i]},maps=${map[$i]},reduce=${reduce[$i]},date='$currentDate';"

			logger "$insert"
			$MYSQL "$insert"
		done
	fi
	#cleaning
	rm tasks.out
	rm globals.out
}

#Expects folder to contain jhist (Job History) files
extract_import_hadoop2_jobs() {
  if [ "$defaultProvider" == "hdinsight" ] || [ "$defaultProvider" == "rackspacecbd" ]; then
    for jhist in `find mr-history/ -type f -name *.jhist | grep SUCCEEDED` ; do
      import_hadoop2_jhist "$jhist"
    done
  else
    for jhist in `find history/ -type f -name *.jhist | grep SUCCEEDED` ; do
      import_hadoop2_jhist "$jhist"
    done
  fi
}

extract_hadoop_jobs() {
  #get the Hadoop job logs
  job_files=$(find "./history" -type f -name "job*"|grep -v ".xml")

  logger "Generating Hadoop Job CSVs for $bench_folder"
  rm -rf "hadoop_job"
  mkdir -p "hadoop_job"

  for job_file in $job_files ; do
    #Get hadoop job name
    job_name="${job_file##*/}"
    job_name="${job_name:0:21}"

    logger "Processing Job $job_name File $job_file"

    logger "Extrating Job history details for $job_file"
    python2.7 "$CUR_DIR/job_history.py" -j "hadoop_job/${job_name}.details.csv" -d "hadoop_job/${job_name}.status.csv" -t "hadoop_job/${job_name}.tasks.csv" -i "$job_file"

  done
}

import_hadoop_jobs() {

  cd hadoop_job
  for csv_file in *.csv ; do
    if [[ $(head $csv_file |wc -l) > 1 ]] ; then
      #get the job name and counter type from csv file name
      separator_pos=$(echo "$csv_file" | awk '{ print index($1,".")}')
      job_name="${csv_file:0:$(($separator_pos - 1))}"
      counter="${csv_file:$separator_pos:-4}"
      table_name="JOB_${counter}"
      logger "Inserting into DB $csv_file TN $table_name"
      #add host and missing data to csv
      awk "NR == 1 {\$1=\"id,id_exec,job_name,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${job_name},\"\$1; print }" "$csv_file" > tmp_${csv_file}.csv

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "${table_name}" "tmp_${csv_file}.csv" "" "," &
      else
        insert_DB "${table_name}" "tmp_${csv_file}.csv" "" ","
      fi

      local data_OK="1"
    else
      logger "File $csv_file is INVALID\n$(cat $csv_file)"
    fi
  done

  [ "$data_OK" ] && folder_OK="$(( folder_OK + data_OK ))"

  cd ..; logger "\n"
}

import_sar_files() {
  for sar_file in sar*.sar ; do
    if [[ $(head $sar_file |wc -l) > 1 ]] ; then

      for table_name in "SAR_cpu" "SAR_io_paging" "SAR_interrupts" "SAR_load" "SAR_memory_util" "SAR_memory" "SAR_swap" "SAR_swap_util" "SAR_switches" "SAR_block_devices" "SAR_net_devices" "SAR_io_rate" "SAR_net_errors" "SAR_net_sockets"; do
        sar_command=""
        if [ "$table_name" == "SAR_cpu" ] ; then
          sar_command="-u"
        elif [ "$table_name" == "SAR_io_paging" ] ; then
          sar_command="-B"
        elif [ "$table_name" == "SAR_interrupts" ] ; then
          sar_command="-I SUM"
        elif [ "$table_name" == "SAR_load" ] ; then
          sar_command="-q"
        elif [ "$table_name" == "SAR_memory_util" ] ; then
          sar_command="-r"
        elif [ "$table_name" == "SAR_memory" ] ; then
          sar_command="-R"
        elif [ "$table_name" == "SAR_swap" ] ; then
          sar_command="-S"
        elif [ "$table_name" == "SAR_swap_util" ] ; then
          sar_command="-W"
        elif [ "$table_name" == "SAR_switches" ] ; then
          sar_command="-w"
        elif [ "$table_name" == "SAR_block_devices" ] ; then
          sar_command="-d"
        elif [ "$table_name" == "SAR_net_devices" ] ; then
          sar_command="-n ALL"
        elif [ "$table_name" == "SAR_io_rate" ] ; then
          sar_command="-b"
        elif [ "$table_name" == "SAR_net_errors" ] ; then
          sar_command="-n EDEV"
        elif [ "$table_name" == "SAR_net_sockets" ] ; then
          sar_command="-n SOCK"
        fi

        if [ "$sar_command" != "" ] ; then
          csv_name="$sar_file.$table_name.csv"
          $sadf -d "$sar_file" -- $sar_command |\
          sed 's/ UTC//g' | \
          awk "NR == 1 {sub(\"timestamp\", \"date\", \$2); sub(\"hostname\", \"host\", \$2); \
                        \$2=\"id;id_exec;\" \$2; print \$2} \
               NR > 1  {\$1=\"NULL;${id_exec};\"\$1;  print }" > "$csv_name"

          if [ "$PARALLEL_INSERTS" ] ; then
            insert_DB "aloja_logs.${table_name}" "$csv_name" "" ";" &
          else
            insert_DB "aloja_logs.${table_name}" "$csv_name" "" ";"
          fi

          local data_OK="1"
        else
          logger "ERROR: no command for $table_name"
        fi
      done
    else
      logger "ERROR: File $sar_file is INVALID"
    fi
  done

  [ "$data_OK" ] && folder_OK="$(( folder_OK + data_OK ))"
}

import_vmstats_files() {
  for vmstats_file in [vmstat-]*.log ; do
    if [[ $(head $vmstats_file |wc -l) -gt 1 ]] ; then
      #get host name from file name
      hostn="${vmstats_file:7:-4}"
      table_name="VMSTATS"
      logger "Inserting into DB $vmstats_file TN $table_name"

      tail -n +2 "$vmstats_file" | awk '{out="";for(i=1;i<=NF;i++){out=out "," $i}}{print substr(out,2)}' | awk "NR == 1 {\$1=\"id_field,id_exec,host,time,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${hostn},\" (NR-2) \",\"\$1; print }" > tmp_${vmstats_file}.csv

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "aloja_logs.${table_name}" "tmp_${vmstats_file}.csv" "" "," &
      else
        insert_DB "aloja_logs.${table_name}" "tmp_${vmstats_file}.csv" "" ","
      fi

    else
      logger "ERROR: File $vmstats_file is INVALID"
    fi
  done
}

import_bwm_files() {
  for bwm_file in [bwm-]*.log ; do
    if [[ $(head $bwm_file |wc -l) > 1 ]] ; then
      #get host name from file name
      hostn="${bwm_file:4:-4}"
      #there are two formats, 9 and 15 fields
      bwm_format="$(head -n 1 "$bwm_file" |grep -o ';'|wc -l)"
      logger "BWM format $bwm_format"
      head -n3 "$bwm_file"
      if [[ $bwm_format -gt 9 ]] ; then
        table_name="BWM2"
        cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;timestamp;iface_name;bytes_out_s;bytes_in_s;bytes_total_s;bytes_in;bytes_out;packets_out_s;packets_in_s;packets_total_s;packets_in;packets_out;errors_out_s;errors_in_s;errors_in;errors_out\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp_${bwm_file}.csv
      else
        table_name="BWM"
        cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;unix_timestamp;iface_name;bytes_out;bytes_in;bytes_total;packets_out;packets_in;packets_total;errors_out;errors_in\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp_${bwm_file}.csv
      fi

      logger "Inserting into DB $bwm_file TN $table_name"

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "aloja_logs.${table_name}" "tmp_${bwm_file}.csv" "" ";" &
      else
        insert_DB "aloja_logs.${table_name}" "tmp_${bwm_file}.csv" "" ";"
      fi

    else
      logger "File $bwm_file is INVALID"
    fi
  done
}

#$1 folder
delete_untars() {
  logger "INFO: Deleting untared folders to save space"
  if [ -d "$1" ] ; then
    #echo "Entering $folder"
    cd $1
    for tarball in *.tar.bz2 ; do
      folder_name="${tarball:0:(-8)}"
      #echo "Found $tarball Folder $folder_name"
      if [ -d "$folder_name" ] ; then
        logger "Deleting $folder_name"
        rm -rf $folder_name
      fi
    done
    cd ..
  fi
}

#$1 name history folder
get_xml_exec_params() {
	local histFolder="history/"
	if [ ! -z $1 ]; then
	  histFolder=$1
    fi

	xmlFile=$(find $histFolder -type f -name *.xml | head -n 1)
	replication=$(xmllint --xpath "string(//property[name='dfs.replication']/value)" $xmlFile)
	compressCodec=$(xmllint --xpath "string(//property[name='mapreduce.map.output.compress.codec']/value)" $xmlFile)
	maps=$(xmllint --xpath "string(//property[name='mapreduce.tasktracker.map.tasks.maximum']/value)" $xmlFile)
	blocksize=$(xmllint --xpath "string(//property[name='dfs.blocksize']/value)" $xmlFile)
	iosf=$(xmllint --xpath "string(//property[name='mapreduce.task.io.sort.factor']/value)" $xmlFile)
	iofilebuf=$(xmllint --xpath "string(//property[name='io.file.buffer.size']/value)" $xmlFile)
	compressionEnabled=$(xmllint --xpath "string(//property[name='mapreduce.map.output.compress']/value)" $xmlFile)
	if [ "$compressionEnabled" = "false" ]; then
		compressCodec=0
	elif [ "$compressCodec" = "org.apache.hadoop.io.compress.SnappyCodec" ]; then
		compressCodec=3
	elif [ "$compressCodec" = "org.apache.hadoop.io.compress.DefaultCodec" ]; then
		compressCodec=1
	elif [ "$compressCodec" = "org.apache.hadoop.io.compress.BZip2Codec " ]; then
		compressCodec=2
	else
		compressCodec=0
	fi

	blocksize=`expr $blocksize / 1000000`
}
