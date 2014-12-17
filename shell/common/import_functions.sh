#common functions fro aloja-import2db.sh

#CREATE TABLE AND LOAD VALUES FROM CSV FILE
# $1 TABLE NAME $2 PATH TO CSV FILE $3 DROP THE DB FIRST $4 DELIMITER $5 DB
insert_DB(){

  echo "Inserting into DB $sar_file TN $1"

  if [[ $(head "$2"|wc -l) > 1 ]] ; then
    echo "Loading $2 into $1"
head -n3 "$2"

    $MYSQL "
    SET time_zone = '+00:00';
    LOAD DATA LOCAL INFILE '$2' INTO TABLE $1
    FIELDS TERMINATED BY '$4' OPTIONALLY ENCLOSED BY '\"'
    IGNORE 1 LINES;"
    echo -e "Loaded $2 into $1\n"

  else
    echo "EMPTY CSV FILE FOR $csv_name $(cat $csv_name)"
  fi

  rm $2
}

#$1 cluster
get_insert_cluster_sql() {
  local clusterConfigFile="$(find $CUR_DIR/conf/ -type f -name cluster_*-$1.conf)"
  source "$clusterConfigFile"

  local sql="
INSERT into clusters set
      name='$clusterName', id_cluster='$clusterID', cost_hour='$clusterCostHour', type='$clusterType', link=''
   ON DUPLICATE KEY UPDATE
      name='$clusterName', id_cluster='$clusterID', cost_hour='$clusterCostHour', type='$clusterType', link='';\n"

  local nodeName="$(get_master_name)"
  sql+="insert ignore into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='master';\n"

  for nodeName in $(get_slaves_names) ; do
    sql+="insert ignore into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='slave';\n"
  done

  echo -e "$sql\n"
}


get_exec_params(){
  #here get the zabbix URL to parse filtering prepares and other benchmarks
  exec_params="$(grep  -e 'href'  "$1" |grep 8099 |grep -v -e 'prep_' -e 'b_min_' -e 'b_10_'|\
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

#echo -e "$1\n$exec_params"

  # Time from Zabbix format
  # substr(zt,0,4) "-" substr(zt,5,2) "-" substr(zt,7,2) " " substr(zt,9,2) ":" substr(zt,11,2) ":" substr(zt,13,2) "\",\"" \

}

get_id_exec(){
    id_exec=$($MYSQL "SELECT id_exec FROM execs WHERE exec = '$1'
    AND id_exec NOT IN (select distinct (id_exec) from SAR_cpu where id_exec is not null ) #and host not like '%-1001'
    LIMIT 1;"| tail -n 1)
}

get_id_exec_conf_params(){
    id_exec_conf_params=$($MYSQL "SELECT id_exec FROM execs WHERE exec = '$1'
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
      prepjobs=$(find "./history/done" -type f -name "job*.xml");
      #2nd: get jobs in bench folder
      cd ../$bench_folder
      jobconfs=$(find "./history/done" -type f -name "job*.xml");
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

