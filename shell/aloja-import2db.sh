#!/bin/bash

INSERT_DB="1" #if to dump CSV into the DB
REDO_ALL="1" #if to redo folders that have source files and IDs in DB
REDO_UNTARS="" #if to redo the untars for folders that have it
PARALLEL_INSERTS="1" #if to fork subprocecess when inserting data
MOVE_TO_DONE="1" #if set moves completed folders to DONE

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

#TODO check if these variables are still needed
first_host=""
hostn=""

#DEV_PC="true" #set to true to insert to vagrant
#Check if to use a special version of sar or the system one
#nico pc
if [[ ! -z $(uname -a|grep "\-ARCH") ]] ; then
  sadf="$CUR_DIR/sar/archlinux/sadf"
  DEV_PC="true"
#ubuntu
#elif [[ ! -z $(lsb_release -a|grep Ubuntu) ]] ; then
#  sadf="$CUR_DIR/sar/ubuntu/sadf"
#other
else
  sadf="/usr/bin/sadf"
fi

#TABLE MANIPULATION
#MYSQL_ARGS="-uroot --local-infile -f -b --show-warnings " #--show-warnings -B

if [ ! "$DEV_PC" ] ; then
  MYSQL_CREDENTIALS="" #using sudo if from same machine
  #MYSQL_CREDENTIALS="-u npm -paaa -h gallactica "
  REDO_ALL="1" #if to redo folders that have source files and IDs in DB
else
  MYSQL_CREDENTIALS="-uvagrant -pvagrant -h127.0.0.1 -P4306"
fi

MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b --show-warnings -B" #--show-warnings -B
DB="aloja2"
MYSQL="sudo mysql $MYSQL_ARGS $DB -e "

#logger "Dropping database $DB"
#sudo mysql $MYSQL_CREDENTIALS -e "DROP database $DB;"

if [ "$INSERT_DB" == "1" ] ; then
  sudo mysql $MYSQL_CREDENTIALS -e "CREATE DATABASE IF NOT EXISTS \`$DB\`;"
  source "$CUR_DIR/common/create_db.sh"
fi

######################################

#filter folders by date
min_date="20120101"
min_time="$(date --utc --date "$min_date" +%s)"

logger "Starting"

for folder in 201* ; do
	hdinsight='^[0-9]{4}_(.*)$'
	if [[ $folder =~ $hdinsight ]]; then
		#HDINSIGHT log
		source "$CUR_DIR/hdinsight/hdi-import2db.sh"
		importHDIJobs
	else
	
	  folder_OK="0"
	  cd "$BASE_DIR" #make sure we come back to the starting folder
	  logger "Iterating folder\t$folder CP: $(pwd)"
	
	  folder_time="$(date --utc --date "${folder:0:8}" +%s)"
	
	  if [ -d "$folder" ] && [ "$folder_time" -gt "$min_time" ] ; then
	    logger "Entering folder\t$folder"
	    cd "$folder"
	
	    #get all executions details
	    exec_params=""
	    get_exec_params "log_${folder}.log" "$folder"
	
	    if [[ -z $exec_params ]] ; then
	      logger "ERROR: cannot find exec details in log. Exiting folder...\nTEST: $(grep  -e 'href' "log_${folder}.log" |grep 8099)"
	      cd ..
	      continue
	    else
	      logger "Exec params:\n$exec_params"
	    fi
	
	    ##First untar prep folders (needed to fill conf parameters table, excluding prep jobs)
	    logger "Attempting to untar prep_folders (needed to fill conf parameters table, excluding prep jobs)"
	    for bzip_file in prep_*.tar.bz2 ; do
	      bench_folder="${bzip_file%%.*}"
	      if [ ! -d "$bench_folder" ] || [ "$REDO_UNTARS" == "1" ] ; then
	        logger "Untaring $bzip_file"
	        tar -xjf "$bzip_file"
	      fi
	    done
		
	    for bzip_file in *.tar.bz2 ; do
	
	      bench_folder="${bzip_file%%.*}"
	
	      #skip conf folders
	      [ "$bench_folder" == "host_conf" ] && continue
	
	      if [[ ! -d "$bench_folder" || "$REDO_UNTARS" == "1" && "${bench_folder:0:5}" != "prep_" ]] ; then
	        logger "Untaring $bzip_file in $(pwd)"
	        logger " LS: $(ls -lah "$bzip_file")"
	        tar -xjf "$bzip_file"
	      fi
	
	      if [ -d "$bench_folder" ] ; then
	
	        logger "Entering $bench_folder"
	        cd "$bench_folder"
	
	        exec="${folder}/${bench_folder}"
	
	        #insert config and get ID_exec
	        exec_values=$(echo "$exec_params" |egrep "^\"$bench_folder")
	        #TODO need to add ol naming scheme
	        if [[  $folder == *_az ]] ; then
	          cluster="2"
	        else
	          cluster="${folder:(-2):2}"
	
	          $MYSQL "$(get_insert_cluster_sql "$cluster")"
	        fi
	        logger "Cluster $cluster"
	
	        if [[ ! -z $exec_values ]] ; then
	
	          folder_OK="$(( folder_OK + 1 ))"
	
	          insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link)
	                  VALUES (NULL, $cluster, \"$exec\", $exec_values)
	                  ON DUPLICATE KEY UPDATE
	                  start_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 0,19)}')',
	                  end_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 23,19)}')';"
	          logger "$insert"
	
	          $MYSQL "$insert"
	        elif [ "$bench_folder" == "SCWC" ] ; then
	          logger "Processing SCWC"
	
	          insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link)
	                  VALUES (NULL, $cluster, \"$exec\", 'SCWC','10','0000-00-00','0000-00-00','ETH','HDD','SCWC','0','0','1','0','0','0','link')
	                  ;"
	                  #ON DUPLICATE KEY UPDATE
	                  #start_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 0,19)}')',
	                  #end_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 23,19)}')'
	          logger "$insert"
	
	          $MYSQL "$insert"
	
	        else
	          logger "ERROR: cannot find bench $bench_folder execution details in log"
	          #continue
	        fi
	
	        #get Job XML configuration if needed
	        #get_job_confs
	
			    id_exec=""
	        get_id_exec "$exec"
	
	        logger "EP $exec_params \nEV $exec_values\nIDE $id_exec\nCluster $cluster"
				
	        if [[ ! -z "$id_exec" ]] ; then
	
	          #if dir does not exists or need to insert in DB
	          if [[ "$REDO_ALL" == "1" || "$INSERT_DB" == "1" ]]  ; then
	            extract_hadoop_jobs
	          fi
	
	          #DB inserting scripts
	          if [ "$INSERT_DB" == "1" ] ; then
	            #start with Hadoop's
	            import_hadoop_jobs
	            wait
	            import_sar_files
	            wait
	            import_vmstats_files
	            wait
	            import_bwm_files
	            wait
	          fi
	        fi
	        cd ..; logger "Leaving folder $bench_folder\n"
	
	      else
	        logger "ERROR: cannot find folder $bench_folder\nLS: $(ls -lah)"
	      fi
	    done #end for bzip file
	    cd ..; logger "Leaving folder $folder\n"
	
	    if [ "$MOVE_TO_DONE" ] ; then
	      if (( "$folder_OK" >= 3 )) ; then
	        logger "OK=$folder_OK Moving folder $folder to DONE"
	        mkdir -p "$BASE_DIR/DONE"
	        mv "$BASE_DIR/$folder" "$BASE_DIR/DONE/"
	      else
	        logger "OK=$folder_OK Leaving folder $folder out to revise"
	      fi
	    fi
	
	  else
	    [ ! -d "$folder" ] && logger "ERROR: $folder not a folder, continuing."
	    [ -d "$folder" ] && [ "$folder_time" -gt "$min_time" ] && logger "ERROR: Folder time: $folder_time not greater than Min time: $min_time"
	  fi
	fi
done #end for folder