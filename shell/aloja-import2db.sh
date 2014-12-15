#!/bin/bash

INSERT_DB=1 #if to dump CSV into the DB
DROP_DB_FIRST= #if to drop whatever is there on the first folder
REDO_ALL=1 #if to redo folders that have source files
REDO_UNTARS= #if to redo the untars for folders that have it
INSERT_BY_EXEC=1 #if to insert right after each folder

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

#TODO check if these variables are still needed
DROP_DB_FIRST=""
first_host=""
hostn=""

#Check if to use a special version of sar or the system one
#nico pc
#if [[ "$HOSTNAME" == "darchi" ]] ; then
if [[ ! -z $(uname -a|grep "\-ARCH") ]] ; then
  sadf="$CUR_DIR/sar/archlinux/sadf"
#ubuntu
#elif [[ ! -z $(lsb_release -a|grep Ubuntu) ]] ; then
#  sadf="$CUR_DIR/sar/ubuntu/sadf"
#other
else
  sadf="/usr/bin/sadf"
fi

#TABLE MANIPULATION
#MYSQL_ARGS="-uroot --local-infile -f -b --show-warnings " #--show-warnings -B

MYSQL_CREDENTIALS="" #using sudo if from same machine
#MYSQL_CREDENTIALS="-uvagrant -pvagrant -h127.0.0.1 -P4306"
#MYSQL_CREDENTIALS="-u npm -paaa -h gallactica "

MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b --show-warnings -B" #--show-warnings -B
DB="aloja2"
MYSQL="sudo mysql $MYSQL_ARGS $DB -e "

#TODO temporal
mysql $MYSQL_CREDENTIALS -e "DROP database $DB;"

if [ "$INSERT_DB" == "1" ] ; then

  sudo mysql $MYSQL_CREDENTIALS -e "CREATE DATABASE IF NOT EXISTS \`$DB\`;"
  source "$CUR_DIR/create_db.sh"
fi

######################################

logger "Starting"

for folder in 201* ; do

  logger "Iterating folder\t$folder"

  #TODO and folder not in list of folders to avoid repetitions
  if [[ -d "$folder" ]] && [ "${folder:0:8}" -gt "20120101" ] ; then
    logger "Entering folder\t$folder"
    cd "$folder"

    #get all executions details
    exec_params=""
    get_exec_params "log_${folder}.log" "$folder"

    if [[ -z $exec_params ]] ; then
      logger "ERROR: cannot find exec details in log. Exiting folder..."
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

      if [ ! -d "$bench_folder" ] ; then

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

        id_exec=""
        get_id_exec_conf_params "$exec"
        
        if [[ ! -z "$id_exec" ]] ; then
        	jobconfs=""
          #get_job_confs

			#Dump parameters from valid conf files to DB
			for job_conf in $jobconfs ; do
				params=$($CUR_DIR/getconf_param.sh -f $job_conf);
				filename=$(basename "$job_conf")
				job_name="${filename%.*}"
				job_name="${job_name:0:(-5)}"
				insert_conf_params_DB "$params" "$id_exec" "$job_name"
			done
      else
        logger "ERROR: $bench_folder does not exist"
		  fi
		
		    id_exec=""
        get_id_exec "$exec"

        logger "EP $exec_params \nEV $exec_values\nIDE $id_exec\nCluster $cluster"
			
        if [[ ! -z "$id_exec" ]] ; then

          #if dir does not exists or need to insert in DB
          if [[ "$REDO_ALL" == "1" || "$INSERT_DB" == "1" ]]  ; then
			
              #get the Hadoop job logs
              job_files=$(find "./history/done" -type f -name "job*"|grep -v ".xml")

              logger "Generating Hadoop Job CSVs for $bench_folder"
              #rm -rf "hadoop_job"
              #rm -rf "sysstat"
              mkdir -p "hadoop_job"

              for job_file in $job_files ; do
                #Get hadoop job name
                job_name="${job_file##*/}"
                job_name="${job_name:0:21}"

                logger "Processing Job $job_name File $job_file"

                logger "Extrating Job history details for $job_file"
                python2.7 "$CUR_DIR/job_history.py" -j "hadoop_job/${job_name}.details.csv" -d "hadoop_job/${job_name}.status.csv" -t "hadoop_job/${job_name}.tasks.csv" -i "$job_file"

              done
            fi

            #DB inserting scripts
            if [ "$INSERT_DB" == "1" ] ; then
              #start with Hadoop's
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
                  awk "NR == 1 {\$1=\"id,id_exec,job_name,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${job_name},\"\$1; print }" "$csv_file" > tmp.csv

                  insert_DB "${table_name}" "tmp.csv" "" ","
                else
                  logger "File $csv_file is INVALID\n$(cat $csv_file)"
                fi
              done
              cd ..; logger "\n"

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

                      insert_DB "${table_name}" "$csv_name" "" ";"
                    else
                      logger "ERROR: no command for $table_name"
                    fi
                  done
                else
                  logger "ERROR: File $sar_file is INVALID"
                fi
              done

              for vmstats_file in [vmstat-]*.log ; do
                if [[ $(head $vmstats_file |wc -l) -gt 1 ]] ; then
                  #get host name from file name
                  hostn="${vmstats_file:7:-4}"
                  table_name="VMSTATS"
                  logger "Inserting into DB $vmstats_file TN $table_name"

                  tail -n +2 "$vmstats_file" | awk '{out="";for(i=1;i<=NF;i++){out=out "," $i}}{print substr(out,2)}' | awk "NR == 1 {\$1=\"id_field,id_exec,host,time,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${hostn},\" (NR-2) \",\"\$1; print }" > tmp.csv

                  insert_DB "${table_name}" "tmp.csv" "" ","
                else
                  logger "ERROR: File $vmstats_file is INVALID"
                fi
              done

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
                    cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;timestamp;iface_name;bytes_out_s;bytes_in_s;bytes_total_s;bytes_in;bytes_out;packets_out_s;packets_in_s;packets_total_s;packets_in;packets_out;errors_out_s;errors_in_s;errors_in;errors_out\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp.csv
                  else
                    table_name="BWM"
                    cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;unix_timestamp;iface_name;bytes_out;bytes_in;bytes_total;packets_out;packets_in;packets_total;errors_out;errors_in\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp.csv
                  fi

                  logger "Inserting into DB $bwm_file TN $table_name"

                  insert_DB "${table_name}" "tmp.csv" "" ";"
                else
                  logger "File $bwm_file is INVALID"
                fi
              done

            fi

          fi
          cd ..; logger "\n"
        fi
    done
    cd ..; logger "\n"
  fi
done