#common functions fro aloja-import2db.sh

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#CREATE TABLE AND LOAD VALUES FROM CSV FILE
# $1 TABLE NAME $2 PATH TO CSV FILE $3 DROP THE DB FIRST $4 DELIMITER $5 DB
insert_DB(){
  logger "INFO: Inserting into DB $sar_file TN $1"

  if [[ $(head "$2"|wc -l) > 1 ]] ; then
    logger "DEBUG: Loading $2 into $1"
    logger "DEBUG: File header:\n$(head -n3 "$2")"

    #tx levels READ UNCOMMITTED READ-COMMITTED

    $MYSQL "
    SET time_zone = '+00:00';

# Removed due to needing super permissions
#    SET tx_isolation = 'READ-COMMITTED';
#    SET GLOBAL tx_isolation = 'READ-COMMITTED';

    LOAD DATA LOCAL INFILE '$2' INTO TABLE $1
    FIELDS TERMINATED BY '$4' OPTIONALLY ENCLOSED BY '\"'
    IGNORE 1 LINES;"
    logger "DEBUG: Loaded $2 into $1\n"
  else
    logger "WARNING: empty CSV file $csv_name $(cat $csv_name)"
  fi

  # Delete the temporary file
  rm "$2"
}

# Transition function to be able to import an especific folder
# $1 folder to import
# $2 reload caches
import_from_folder() {
  local folder="$1"
  local reload_caches="$2"

  # Remove trailing slash if any
  [ "${folder:(-1)}" == "/" ] && folder="${folder:0:(-1)}"

  # Test for full or relative path
  if [ "${folder:0:1}" == "/" ] ; then
    BASE_DIR="${folder%/*}"
    folder="${folder##*/}"
  # if not, check if we have a cluster defined (eg from benchs)
  elif [ "$clusterName" ] ; then
    BASE_DIR="$BENCH_SHARE_DIR/jobs_${clusterName}"
  # use the current path
  else
    BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  fi

  [ ! -d "$BASE_DIR/$folder" ] && die "Cannot find $BASE_DIR/$folder folder. Exit..."

  logger "INFO: Importing data from from $BASE_DIR/$folder"

  INSERT_DB="1" #if to dump CSV into the DB
  REDO_ALL="1" #if to redo folders that have source files and IDs in DB
  REDO_UNTARS="" #if to redo the untars for folders that have it
  PARALLEL_INSERTS="" #if to fork subprocecess when inserting data
  MOVE_TO_DONE="" #if set moves completed folders to DONE

  sadf="/usr/bin/sadf"

  if ! which mysql ; then
    source "$ALOJA_REPO_PATH/shell/common/install_functions.sh"
    install_packages "mysql-client" "update"
  fi

  MYSQL_CREDENTIALS="-uvagrant -pvagrant -h aloja-web -P3306"
  MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b --show-warnings -B" #--show-warnings -B
  DB="aloja2"
  MYSQL_CREATE="sudo mysql $MYSQL_ARGS -e " #do not include DB name in case it doesn't exist yet
  MYSQL="sudo mysql $MYSQL_ARGS $DB -e "

  # Finally, run the command
  import_folder "$folder"
  logger "INFO: clearing unzipped files"
  delete_untars "$BASE_DIR/$folder"

  [ "$reload_caches" ] && refresh_web_caches "aloja-web"

  # Construct the helper URL
  if [ "$id_execs" ] ; then
    for id_exec in ${id_execs[@]} ; do
      query_string+="&execs[]=$id_exec"
    done
    logger "INFO: URL of perf charts http://localhost:8080/perfcharts?${query_string:1}&detail=1"
  fi
}


# Imports the given folder into ALOJA-WEB
# TODO old code moved here need refactoring
# $1 folder to import
import_folder() {
  local folder="$1"

  #filter folders by date
  min_date="20120101"
  min_time="$(date --utc --date "$min_date" +%s)"

	[ "$folder" ] || die "Empty folder supplied to import_folder()"

  folder_OK="0"
  cd "$BASE_DIR" #make sure we come back to the starting folder
  logger "INFO: Iterating folder\t$folder CP: $(pwd)"

  folder_time="$(date --utc --date "${folder:0:8}" +%s)"

  if [ -d "$folder" ] && [ "$folder_time" -gt "$min_time" ] ; then
    logger "INFO: Entering folder\t$folder"
    cd "$folder"

    #get all executions details
    exec_params="$(get_exec_params "log_${folder}.log" "$folder")"
    hadoop_version=$(extract_config_var "HADOOP_VERSION")
    hadoop_major_version="$(get_hadoop_major_version "$hadoop_version")"

    if [[ -z $exec_params ]] ; then
      logger "ERROR: cannot find exec details in log. Exiting folder...\nTEST: $(grep  -e 'href' "log_${folder}.log" |grep 8099)"
      cd ..

      #move folder to failed dir
      if [ "$MOVE_TO_DONE" ] ; then
        delete_untars "$BASE_DIR/$folder"
        move2done "$folder" "$folder_OK"
      fi

      continue
    else
      logger "DEBUG: Exec params:\n$exec_params"
    fi


    # First untar prep folders (if any). Needed to fill conf parameters table, excluding prep jobs
    # NOTE: this is for legacy HiBench
    if ls prep_*.tar.bz2 1> /dev/null 2>&1; then
      logger "INFO: Attempting to untar prep_folders (needed to fill conf parameters table, excluding prep jobs)"
      for bzip_file in prep_*.tar.bz2 ; do
        bench_folder="${bzip_file%%.*}"
        if [ ! -d "$bench_folder" ] || [ "$REDO_UNTARS" == "1" ] ; then
          logger "INFO: Untaring $bzip_file"
          tar -xjf "$bzip_file"
        fi
      done
    else
      logger "INFO: No prep_* bench folder found (LEGACY)"
    fi

    for bzip_file in *.tar.bz2 ; do
      bench_folder="${bzip_file%%.*}"

      #skip conf folders
      [ "$bench_folder" == "host_conf" ] && continue

      if [[ ! -d "$bench_folder" || "$REDO_UNTARS" == "1" && "${bench_folder:0:5}" != "prep_" ]] ; then
        logger "INFO: Untaring $bzip_file in $(pwd)"
        logger "DEBUG:  LS: $(ls -lah "$bzip_file")"
        tar -xjf "$bzip_file"
      fi

      if [ -d "$bench_folder" ] ; then

        logger "INFO: Entering $bench_folder"
        cd "$bench_folder"

        exec="${folder}/${bench_folder}"

        #insert config and get ID_exec
        exec_values=$(echo "$exec_params" |egrep "^\"$bench_folder")

        if [[  $folder == *_az ]] ; then
          id_cluster="2"
        else
          id_cluster="$(get_id_cluster "$folder")"

          clusterConfigFile="$(get_clusterConfigFile $id_cluster)"
          source $clusterConfigFile

          logger "DEBUG: id_cluster=$id_cluster clusterConfigFile=$clusterConfigFile"

          #TODO this check wont work for old folders with numeric values at the end, need another strategy
          #line to fix update execs set id_cluster=1 where id_cluster IN (28,32,56,64);
          if [ -f "$clusterConfigFile" ] && [[ $id_cluster =~ ^-?[0-9]+$ ]] ; then
            $MYSQL "$(get_insert_cluster_sql "$id_cluster" "$clusterConfigFile")"
          else
            id_cluster="1"
          fi
        fi

        if [ "$exec_values" ] ; then
          folder_OK="$(( folder_OK + 1 ))"

          # Legacy config, taken from folder and log
          if [ "${name:15:6}" == "_conf_" ]; then
            insert="INSERT INTO aloja2.execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link,hadoop_version,exec_type)
                  VALUES (NULL, $id_cluster, \"$exec\", $exec_values)
                  ON DUPLICATE KEY UPDATE
                    id_cluster=VALUES(id_cluster),
                    exec=VALUES(exec),
                    bench=VALUES(bench),
                    exe_time=VALUES(exe_time),
                    start_time=VALUES(start_time),
                    end_time=VALUES(end_time),
                    net=VALUES(net),
                    disk=VALUES(disk),
                    bench_type=VALUES(bench_type),
                    maps=VALUES(maps),
                    iosf=VALUES(iosf),
                    replication=VALUES(replication),
                    iofilebuf=VALUES(iofilebuf),
                    comp=VALUES(comp),
                    blk_size=VALUES(blk_size),
                    zabbix_link=VALUES(zabbix_link),
                    hadoop_version=VALUES(hadoop_version),
                    exec_type=VALUES(exec_type);"
          # New style, with more db fields
          else
            insert="INSERT INTO aloja2.execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link,hadoop_version,exec_type, datasize, scale_factor)
                  VALUES (NULL, $id_cluster, \"$exec\", $exec_values)
                  ON DUPLICATE KEY UPDATE
                    id_cluster=VALUES(id_cluster),
                    exec=VALUES(exec),
                    bench=VALUES(bench),
                    exe_time=VALUES(exe_time),
                    start_time=VALUES(start_time),
                    end_time=VALUES(end_time),
                    net=VALUES(net),
                    disk=VALUES(disk),
                    bench_type=VALUES(bench_type),
                    maps=VALUES(maps),
                    iosf=VALUES(iosf),
                    replication=VALUES(replication),
                    iofilebuf=VALUES(iofilebuf),
                    comp=VALUES(comp),
                    blk_size=VALUES(blk_size),
                    zabbix_link=VALUES(zabbix_link),
                    hadoop_version=VALUES(hadoop_version),
                    exec_type=VALUES(exec_type),
                    datasize=VALUES(datasize),
                    scale_factor=VALUES(scale_factor);"
          fi

          #logger "DEBUG: $insert"
          $MYSQL "$insert"

          if [ "$hadoop_major_version" == "2" ]; then
              if [ "$defaultProvider" == "hdinsight" ] || [ "$defaultProvider" == "rackspacecbd" ]; then
                get_xml_exec_params "mr-history"
              else
                get_xml_exec_params "history"
              fi
            update="UPDATE aloja2.execs SET replication=\"$replication\",comp=\"$compressCodec\",maps=\"$maps\",blk_size=\"$blocksize\",iosf=\"$iosf\",iofilebuf=\"$iofilebuf\" WHERE exec=\"$exec\";"
            logger "DEBUG: updating exec params from execution conf: $update"
            $MYSQL "$update"
          fi

        # An example of how to imput values to de DB in another way
        elif [ "$bench_folder" == "SCWC" ] ; then
          logger "DEBUG: Processing SCWC"

          insert="INSERT INTO aloja2.execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link)
                  VALUES (NULL, $id_cluster, \"$exec\", 'SCWC','10','0000-00-00','0000-00-00','ETH','HDD','SCWC','0','0','1','0','0','0','link')
                  ;"
                  #ON DUPLICATE KEY UPDATE
                  #start_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 0,19)}')',
                  #end_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 23,19)}')'
          logger "INFO: $insert"

          $MYSQL "$insert"

        else
          logger "ERROR: cannot find bench $bench_folder execution details in log"
          #continue
        fi

        #get Job XML configuration if needed
        #get_job_confs

        # Get the DB id for the exec
        id_exec="$(get_id_exec "$exec")"

        # Save the different id_execs to construc the URL at the end
        id_execs+=("$id_exec")

        logger "DEBUG: EP $exec_params \nEV $exec_values\nIDE $id_exec\nCluster $id_cluster"

        if [[ ! -z "$id_exec" ]] && [ -z "$ONLY_META_DATA" ] ; then

          #if dir does not exists or need to insert in DB
          if [ "$hadoop_major_version" != "2" ]; then
        if [[ "$REDO_ALL" == "1" || "$INSERT_DB" == "1" ]]  ; then
        extract_hadoop_jobs
        fi
          fi

          #DB inserting scripts
          if [ "$INSERT_DB" == "1" ] ; then
            #start with Hadoop's
            if [ "$hadoop_major_version" != "2" ]; then
             import_hadoop_jobs
            else
              extract_import_hadoop2_jobs
            fi
            import_AOP4Hadoop_files
            wait
            import_sar_files
            wait
            import_vmstats_files
            wait
            import_bwm_files
            wait
          fi
        fi
        cd ..; logger "INFO: Leaving folder $bench_folder\n"

        #update DB filters
        logger "INFO: checking if run was valid"
        #logger "DEBUG: $(get_filter_sql_exec "$id_exec")"
        $MYSQL "$(get_filter_sql_exec "$id_exec")"

      else
        logger "ERROR: cannot find folder $bench_folder\nLS: $(ls -lah)"
      fi
    done #end for bzip file
    cd ..; logger "INFO: Leaving folder $folder\n"

    if [ "$MOVE_TO_DONE" ] ; then
      delete_untars "$BASE_DIR/$folder"
      move2done "$folder" "$folder_OK"
    fi

  else
    [ ! -d "$folder" ] && logger "ERROR: $folder not a folder, continuing."
    [ -d "$folder" ] && [ "$folder_time" -gt "$min_time" ] && logger "ERROR: Folder time: $folder_time not greater than Min time: $min_time"
  fi

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
    sql+="insert into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='master'
ON DUPLICATE KEY UPDATE id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='master';\n"

    for nodeName in $(get_slaves_names) ; do
      sql+="insert into hosts set id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='slave'
ON DUPLICATE KEY UPDATE id_host='$clusterID$(get_vm_id "$nodeName")', id_cluster='$clusterID', host_name='$nodeName', role='slave';\n"
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
      logger "DEBUG: OK=$2 Moving folder $1 to DONE"
      cp -ru "$BASE_DIR/$1" "$BASE_DIR/DONE/"
      rm -rf "$BASE_DIR/$1"
    else
      logger "DEBUG: OK=$2 Moving $1 to FAIL/$2 for manual check"
      cp -ru "$BASE_DIR/$1" "$BASE_DIR/FAIL/$2/"
      rm -rf "$BASE_DIR/$1"
    fi
  fi
}

get_filter_sql() {
  echo "
#Re-updates filters for the whole DB, normally it is done after each insert

#exec type not set
update ignore aloja2.execs SET exec_type = 'default' WHERE exec_type = '' OR exec_type IS NULL;

#filter, execs that don't have any Hadoop details

update ignore aloja2.execs SET filter = 0;
update ignore aloja2.execs SET filter = 1 where (bench like 'HiBench%' OR bench = 'Hadoop-Examples') AND id_exec  NOT IN(select distinct (id_exec) FROM aloja_logs.JOB_status where id_exec is not null);

#perf_detail, aloja2.execs without perf counters

update ignore aloja2.execs SET perf_details = 0;
update ignore aloja2.execs SET perf_details = 1 where id_exec IN(select distinct (id_exec) from aloja_logs.SAR_cpu where id_exec is not null);

#valid, set everything as valid, except the ones that do not match the following rules
update ignore aloja2.execs SET valid = 1;
update ignore aloja2.execs SET valid = 0 where bench_type = 'HiBench' and bench = 'terasort' and id_exec NOT IN (
  select distinct(id_exec) from
    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore aloja2.execs e INNER JOIN (SELECT id_exec,IFNULL(SUM(js.reduce),0) as 'suma' FROM aloja2.execs e2 left JOIN aloja_logs.JOB_status js USING (id_exec) WHERE  e2.bench NOT LIKE 'prep%' and e2.bench NOT IN ('teragen','randomtextwriter') GROUP BY id_exec) i using(id_exec) SET valid = 0 WHERE  suma < 1;

##HDInsight filters
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set valid = 0 where type != 'PaaS' AND exec LIKE '%hdi%';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set valid = 1, filter = 0 where provider = 'hdinsight';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time < 700 OR id_cluster =25 AND YEAR(start_time) = '2014';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time>5000 AND YEAR(start_time) = '2014';
update ignore aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench_type = 'HDI' AND bench = 'terasort' AND exe_time > 5000 AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 24 AND bench = 'terasort' AND exe_time > 900 AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 23 AND bench = 'terasort' AND exe_time > 1100 AND YEAR(start_time) = '2014';

update ignore aloja2.execs set filter = 1 where id_cluster = 20 AND bench = 'terasort' AND exe_time > 2300 AND YEAR(start_time) = '2014';

update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set filter = 1 where type = 'PaaS' and provider = 'hdinsight' and exe_time < 100;
update ignore aloja2.execs set filter = 1 where bench IN ('prep_terasort-t','terasort-t','prep_wordcount,terasort','wordcount,terasort');

#Wrong imports filter
update ignore aloja2.execs set filter = 1 where (iosf IS NULL or iosf=0 or iofilebuf IS NULL or iofilebuf=0 OR blk_size IS NULL or iofilebuf = 0 OR replication IS NULL or replication = 0 or comp IS NULL or maps = 0 or maps IS NULL) and valid = 1 and filter = 0;
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

update ignore aloja2.execs SET filter = 0 where id_exec = '$1' AND (bench like 'HiBench%' OR bench = 'Hadoop-Examples') ;
update ignore aloja2.execs SET filter = 1 where id_exec = '$1' AND (bench like 'HiBench%' OR bench = 'Hadoop-Examples') AND id_exec NOT IN(select distinct (id_exec) FROM aloja_logs.JOB_status where id_exec = '$1' AND id_exec is not null);

#perf_detail, aloja2.execs without perf counters

update ignore aloja2.execs SET perf_details = 0 where id_exec = '$1';
update ignore aloja2.execs SET perf_details = 1 where id_exec = '$1' AND id_exec IN(select distinct (id_exec) from aloja_logs.SAR_cpu where id_exec = '$1' AND id_exec is not null);

#valid, set everything as valid, except the ones that do not match the following rules
update ignore aloja2.execs SET valid = 1 where id_exec = '$1' ;
update ignore aloja2.execs SET valid = 0 where id_exec = '$1' AND bench_type = 'HiBench' and bench = 'terasort' and id_exec NOT IN (
  select distinct(id_exec) from
    (select b.id_exec from aloja2.execs b join JOB_details using (id_exec) where id_exec = '$1' AND bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore aloja2.execs e INNER JOIN (SELECT id_exec,IFNULL(SUM(js.reduce),0) as 'suma' FROM aloja2.execs e2 left JOIN aloja_logs.JOB_status js USING (id_exec) WHERE e2.id_exec = '$1' AND  e2.bench NOT LIKE 'prep%' and e2.bench NOT IN ('teragen','randomtextwriter') GROUP BY id_exec) i using(id_exec) SET valid = 0 WHERE e.id_exec = '$1' AND  suma < 1;
update ignore aloja2.execs SET exec_type = 'default' WHERE id_exec = '$1' AND exec_type = '' OR exec_type IS NULL;

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
    local bench=$(extract_config_var "BENCH_SUITE")

    # if not found, try previous name
    [ ! "$bench" ] && local bench=$(extract_config_var "BENCH")

    local maps=$(extract_config_var "MAX_MAPS")
    local iosf=$(extract_config_var "IO_FACTOR")
    local replication=$(extract_config_var "REPLICATION")
    local iofilebuf=$(extract_config_var "IO_FILE")
    local comp=$(extract_config_var "COMPRESS_TYPE")
    local blk_size=$(extract_config_var "BLOCK_SIZE")
    local exec_type=$(extract_config_var "EXEC_TYPE")
    local datasize=$(extract_config_var "BENCH_DATA_SIZE")
    #compatibility with legacy runs
    if [[ $datasize == "" ]]; then
       datasize=0
    fi

    local scale_factor=$(extract_config_var "BENCH_SCALE_FACTOR")
    #legacy, exec type didn't exist until May 18th 2015
    if [[ exec_type == "" ]]; then
      exec_type="default"
    fi

    blk_size=$((blk_size / 1048576 ))
    local zabbix_link=""
    hadoop_version=$(extract_config_var "HADOOP_VERSION")
    hadoop_major_version="$(get_hadoop_major_version "$hadoop_version")"

    # Remove "hadoop" string from version: "hadoop2" -> "2"
    #hadoop_version="${hadoop_version//hadoop}"

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

      exec_params="$exec_params\"$job\",\"$exe_time\",\"$start_time\",\"$end_time\",\"$net\",\"$disk\",\"$bench\",\"$maps\",\"$iosf\",\"$replication\",\"$iofilebuf\",\"$comp\",\"$blk_size\",\"$zabbix_link\",\"$hadoop_version\",\"$exec_type\",\"$datasize\",\"$scale_factor\" "
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

  logger "INFO: Attempting to get XML configuration for ID get_id_exec_conf_params"
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
      logger "INFO: Not prep folder, considering all confs belonging to exec"
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
return 1
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
	dbFieldList=$($MYSQL "describe HDI_JOB_details" | tail -n+2)
	finalValues="none"
	while IFS=',' read -ra ADDR; do
      for i in "${ADDR[@]}"; do
          test=$(echo $i | cut -d= -f1)
          if [[ $(echo ${dbFieldList} | grep ${test}) ]]; then
            if [ "$finalValues" != "none" ]; then
              finalValues+=",$i"
            else
              finalValues="$i"
            fi
          else
            logger "WARNING: Field ${test} not found on table HDI_JOB_details"
          fi
      done
    done <<< "$values"

	local insert="INSERT IGNORE INTO HDI_JOB_details SET id_exec=$id_exec,${finalValues}
		        ON DUPLICATE KEY UPDATE
		    LAUNCH_TIME=`$CUR_DIR/../aloja-tools/jq '.["LAUNCH_TIME"]' globals.out`,
		    FINISH_TIME=`$CUR_DIR/../aloja-tools/jq '.["SUBMIT_TIME"]' globals.out`;"
    logger "DEBUG: $insert"

	$MYSQL "$insert"

    local result=`$MYSQL "select count(*) FROM aloja_logs.JOB_status JOIN aloja2.execs e USING (id_exec) where e.id_exec=$id_exec" -N`


	if [ -z "$ONLY_META_DATA" ] && [ "$result" -eq 0 ]; then
		local waste=()
		local reduce=()
		local map=()
		local insert_tasks insert_status


		for i in `seq 0 1 $totalTime`; do
			waste[$i]=0
			reduce[$i]=0
			map[$i]=0
		done

		runnignTime=`expr $finishTimeTS - $startTimeTS`
		read -a tasks <<< `$CUR_DIR/../aloja-tools/jq -r 'keys' tasks.out | sed 's/,/\ /g' | sed 's/\[/\ /g' | sed 's/\]/\ /g'`

		dbFieldList=$($MYSQL "describe aloja_logs.HDI_JOB_tasks" | tail -n+2)

		# TODO this loop is very slow, ading & and wait to parallelize a bit
		for task in "${tasks[@]}" ; do

			# try to pa
			taskId="$(echo $task | sed 's/"/\ /g')" &
			taskStatus="$($CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_STATUS" tasks.out)" &
			taskType="$($CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_TYPE" tasks.out)" &
			taskStartTime="$($CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_START_TIME" tasks.out)" &
			taskFinishTime="$($CUR_DIR/../aloja-tools/jq --raw-output ".$task.TASK_FINISH_TIME" tasks.out)" &
			taskStartTime="$(expr $taskStartTime / 1000)" &
			taskFinishTime="$(expr $taskFinishTime / 1000)" &
			values="$($CUR_DIR/../aloja-tools/jq --raw-output ".$task" tasks.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g')" &

      wait
      
          finalValues="none"
          while IFS=',' read -ra ADDR; do
            for i in "${ADDR[@]}"; do
                test=$(echo $i | cut -d= -f1)
                if [[ $(echo ${dbFieldList} | grep ${test}) ]]; then
                  if [ "$finalValues" != "none" ]; then
                    finalValues+=",$i"
                  else
                    finalValues="$i"
                  fi
                else
                    logger "WARNING: Field ${test} not found on table HDI_JOB_tasks"
                fi
            done
          done <<< "$values"

			insert_tasks="$insert_tasks
INSERT IGNORE INTO aloja_logs.HDI_JOB_tasks SET TASK_ID=$task,JOB_ID=$jobId,id_exec=$id_exec,${finalValues}
  ON DUPLICATE KEY UPDATE JOB_ID=JOB_ID,${finalValues};"

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

    logger "DEBUG: Inserting into HDI_JOB_tasks"
    #create a tmp file as command it is too long sometimes
    local tmp_file="$(mktemp)"
    echo -e "$insert_tasks" > "$tmp_file"
    $MYSQL "$(< "$tmp_file")"
    rm -f "$tmp_file"

		for i in `seq 0 1 $totalTime`; do
			if [ $i -gt 0 ]; then
				previous=$(expr ${i} - 1)
				map[$i]=$(expr ${map[$i]} + ${map[$previous]})
				reduce[$i]=$(expr ${reduce[$i]} + ${reduce[$previous]})
				waste[$i]=$(expr ${waste[$i]} + ${waste[$previous]})
			fi
			currentTime=`expr $startTimeTS + $i`
			currentDate=`date -d @$currentTime +"%Y-%m-%d %H:%M:%S"`
			insert_status="$insert_status
INSERT IGNORE INTO aloja_logs.JOB_status(id_exec,job_name,JOBID,date,maps,shuffle,merge,reduce,waste)
  VALUES ($id_exec,'$exec',$jobId,'$currentDate',${map[$i]},0,0,${reduce[$i]},${waste[$i]})
	ON DUPLICATE KEY UPDATE waste=${waste[$i]},maps=${map[$i]},reduce=${reduce[$i]},date='$currentDate';"

		done
		logger "DEBUG: Inserting into JOB_status"
		$MYSQL "$insert"
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

  logger "INFO: Generating Hadoop Job CSVs for $bench_folder"
  rm -rf "hadoop_job"
  mkdir -p "hadoop_job"

  for job_file in $job_files ; do
    #Get hadoop job name
    job_name="${job_file##*/}"
    job_name="${job_name:0:21}"

    logger "INFO: Processing Job $job_name File $job_file"

    logger "INFO: Extrating Job history details for $job_file"
    python2.7 "$ALOJA_REPO_PATH/shell/job_history.py" -j "hadoop_job/${job_name}.details.csv" -d "hadoop_job/${job_name}.status.csv" -t "hadoop_job/${job_name}.tasks.csv" -i "$job_file"

  done
}

import_hadoop_jobs() {

  cd hadoop_job
  for csv_file in *.csv ; do
    if [[ $(head $csv_file |wc -l) > 1 ]] ; then
      #get the job name and counter type from csv file name
      local separator_pos=$(echo "$csv_file" | awk '{ print index($1,".")}')
      local job_name="${csv_file:0:$(($separator_pos - 1))}"
      local counter="${csv_file:$separator_pos:-4}"
      local table_name="JOB_${counter}"

      if [[ "$table_name" == "JOB_status" || "$table_name" == "JOB_tasks" ]] ; then
        table_name="aloja_logs.$table_name"
      else
        table_name="aloja2.$table_name"
      fi

      logger "INFO: Inserting into DB $csv_file TN $table_name"
      #add host and missing data to csv
      awk "NR == 1 {\$1=\"id,id_exec,job_name,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${job_name},\"\$1; print }" "$csv_file" > tmp_${csv_file}.csv

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "$table_name" "tmp_${csv_file}.csv" "" "," &
      else
        insert_DB "$table_name" "tmp_${csv_file}.csv" "" ","
      fi

      local data_OK="1"
    else
      logger "ERROR: Hadoop file $csv_file is INVALID\n$(cat $csv_file)"
    fi
  done

  [ "$data_OK" ] && folder_OK="$(( folder_OK + data_OK ))"

  cd ..;
}

import_sar_files() {
  for sar_file in sar*.sar ; do
    if [[ $(head $sar_file |wc -l) > 1 ]] ; then

      for table_name in "SAR_cpu" "SAR_io_paging" "SAR_interrupts" "SAR_load" "SAR_memory_util" "SAR_memory" "SAR_swap" "SAR_swap_util" "SAR_switches" "SAR_block_devices" "SAR_net_devices" "SAR_io_rate" "SAR_net_errors" "SAR_net_sockets"; do
        local sar_command=""
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
          local csv_name="$sar_file.$table_name.csv"
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
      logger "ERROR: sar File $sar_file is INVALID"
    fi
  done

  [ "$data_OK" ] && folder_OK="$(( folder_OK + data_OK ))"
}

import_vmstats_files() {
  for vmstats_file in vmstat-*.log ; do
    if [[ $(head $vmstats_file |wc -l) -gt 1 ]] ; then
      #get host name from file name
      hostn="${vmstats_file:7:-4}"
      table_name="VMSTATS"
      logger "INFO: Inserting into DB $vmstats_file TN $table_name"

      tail -n +2 "$vmstats_file" | awk '{out="";for(i=1;i<=NF;i++){out=out "," $i}}{print substr(out,2)}' | awk "NR == 1 {\$1=\"id_field,id_exec,host,time,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${hostn},\" (NR-2) \",\"\$1; print }" > tmp_${vmstats_file}.csv

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "aloja_logs.${table_name}" "tmp_${vmstats_file}.csv" "" "," &
      else
        insert_DB "aloja_logs.${table_name}" "tmp_${vmstats_file}.csv" "" ","
      fi

    else
      logger "DEBUG: vmstats File $vmstats_file is INVALID"
    fi
  done
}

# Imports log generated by AOP4Hadoop (if any)
# More info at: https://github.com/Aloja/AOP4Hadoop
import_AOP4Hadoop_files() {
  local AOP_file_name="aloja.log"
  local tmp_file="tmp_${AOP_file_name}.csv"

  if [ -f "$AOP_file_name" ] ; then
    if [[ $(head $AOP_file_name |wc -l) -gt 1 ]] ; then
      table_name="AOP4Hadoop"
      logger "INFO: Inserting into DB $AOP_file_name TN $table_name"
      awk -F ',' -v id_exec=$id_exec '{gsub(/ /, "", $3); print "NULL,"id_exec","$1","$2","$3","$4","$5","$6","$7}' "$AOP_file_name" > "$tmp_file"
      insert_DB "aloja_logs.${table_name}" "$tmp_file" "" ","
    fi
  fi
}

import_bwm_files() {
  for bwm_file in bwm-*.log ; do 2> /dev/null
    if [ -f "$bwm_file" ] && [[ $(head $bwm_file |wc -l) > 1 ]] ; then
      #get host name from file name
      hostn="${bwm_file:4:-4}"
      #there are two formats, 9 and 15 fields
      bwm_format="$(head -n 1 "$bwm_file" |grep -o ';'|wc -l)"
      logger "INFO: BWM format $bwm_format"
      head -n3 "$bwm_file"
      if [[ $bwm_format -gt 9 ]] ; then
        table_name="BWM2"
        cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;timestamp;iface_name;bytes_out_s;bytes_in_s;bytes_total_s;bytes_in;bytes_out;packets_out_s;packets_in_s;packets_total_s;packets_in;packets_out;errors_out_s;errors_in_s;errors_in;errors_out\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp_${bwm_file}.csv
      else
        table_name="BWM"
        cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;unix_timestamp;iface_name;bytes_out;bytes_in;bytes_total;packets_out;packets_in;packets_total;errors_out;errors_in\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp_${bwm_file}.csv
      fi

      logger "INFO: Inserting into DB $bwm_file TN $table_name"

      if [ "$PARALLEL_INSERTS" ] ; then
        insert_DB "aloja_logs.${table_name}" "tmp_${bwm_file}.csv" "" ";" &
      else
        insert_DB "aloja_logs.${table_name}" "tmp_${bwm_file}.csv" "" ";"
      fi

    else
      logger "DEBUG: bwm File $bwm_file is INVALID"
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
        logger "INFO: Deleting untarred $folder_name folder"
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
	if [ "$xmlFile" ]; then
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
    else
      logger "ERROR: FAILED TO IMPORT JOB, NO HISTORY SAVED"
    fi
}


# Just opens the specified web for cache generation
# $1 url
hit_page() {
  wget -O /dev/null "$1"
  #-o /dev/null
}

# $1 host name
refresh_web_caches() {
  local host_name="$1"
  
  [ "$host_name" ] || die "No hostname supplied"

  logger "INFO: Re-generating basic caches..."
  hit_page "http://$host_name/?NO_CACHE=1"
  hit_page "http://$host_name/benchdata?NO_CACHE=1"
  hit_page "http://$host_name/counters?NO_CACHE=1"
  hit_page "http://$host_name/benchexecs?NO_CACHE=1"
  hit_page "http://$host_name/bestconfig?NO_CACHE=1"
  hit_page "http://$host_name/configimprovement?NO_CACHE=1"
  hit_page "http://$host_name/parameval?NO_CACHE=1"
  hit_page "http://$host_name/costperfeval?NO_CACHE=1"
  #hit_page "http://$host_name/perfcharts?random=1&NO_CACHE=1"
  hit_page "http://$host_name/metrics?NO_CACHE=1"
  hit_page "http://$host_name/metrics?type=MEMORY&NO_CACHE=1"
  hit_page "http://$host_name/metrics?type=DISK&NO_CACHE=1"
  hit_page "http://$host_name/metrics?type=NETWORK&NO_CACHE=1"
  hit_page "http://$host_name/dbscan?NO_CACHE=1"
  hit_page "http://$host_name/dbscanexecs?NO_CACHE=1"

#  hit_page "http://$host_name/"
#  hit_page "http://$host_name/benchdata"
#  hit_page "http://$host_name/counters"
#  hit_page "http://$host_name/benchexecs"
#  hit_page "http://$host_name/bestconfig"
#  hit_page "http://$host_name/configimprovement"
#  hit_page "http://$host_name/parameval"
#  hit_page "http://$host_name/costperfeval"
#  #hit_page "http://$host_name/perfcharts?random=1"
#  hit_page "http://$host_name/metrics"
#  hit_page "http://$host_name/metrics?type=MEMORY"
#  hit_page "http://$host_name/metrics?type=DISK"
#  hit_page "http://$host_name/metrics?type=NETWORK"
#  hit_page "http://$host_name/dbscan"
#  hit_page "http://$host_name/dbscanexecs"
}