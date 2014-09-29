#!/bin/bash

INSERT_DB=1 #if to dump CSV into the DB
DROP_DB_FIRST= #if to drop whatever is there on the first folder
REDO_ALL=1 #if to redo folders that have source files
REDO_UNTARS= #if to redo the untars for folders that have it
INSERT_BY_EXEC=1 #if to insert right after each folder

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

#TODO check if these variables are still needed
DROP_DB_FIRST=""
first_host=""
hostn=""

#Check if to use a special version of sar or the system one
#nico pc
#if [[ "$HOSTNAME" == "darchi" ]] ; then
if [[ ! -z $(lsb_release -a|grep Arch) ]] ; then
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

MYSQL_CREDENTIALS="-uvagrant -pvagrant -h127.0.0.1 -P4306"
#MYSQL_CREDENTIALS="-u npm -paaa -h gallactica "

MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b --show-warnings -B" #--show-warnings -B
DB="aloja2"
MYSQL="mysql $MYSQL_ARGS $DB -e "

if [ "$INSERT_DB" == "1" ] ; then
  mysql $MYSQL_CREDENTIALS -e "CREATE DATABASE IF NOT EXISTS \`$DB\`;"
  . "$CUR_DIR/create_db.sh"
fi

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
  parts[6]"\",\"" \
  substr(parts[7],2)"\",\"" \
  substr(parts[8],2)"\",\"" \
  substr(parts[9],2)"\",\"" \
  substr(parts[10],2)"\",\"" \
  substr(parts[11],2)"\",\"" \
  substr(parts[12],2) "\",\"" \
  substr($5,7,(pri_mas-1)) "\"" \
  } \
  ' )"

  # Time from Zabbix format
  # substr(zt,0,4) "-" substr(zt,5,2) "-" substr(zt,7,2) " " substr(zt,9,2) ":" substr(zt,11,2) ":" substr(zt,13,2) "\",\"" \

}

get_id_exec(){
    id_exec=$($MYSQL "SELECT id_exec FROM execs WHERE exec = '$1'
    AND id_exec NOT IN (select distinct (id_exec) from SAR_cpu where id_exec is not null and host not like '%-1001')
    LIMIT 1;"| tail -n 1)
}

get_id_exec_conf_params(){
    id_exec=$($MYSQL "SELECT id_exec FROM execs WHERE exec = '$1'
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

######################################

echo "Starting"

for folder in 201* ; do

  #TODO and folder not in list of folders to avoid repetitions
  if [[ -d "$folder" ]] && [ "${folder:0:8}" -gt "20120101" ] ; then
    echo "Entering folder $folder"
    cd "$folder"

    #get all executions detail
    exec_params=""
    get_exec_params "log_${folder}.log" "$folder"
    if [[ -z $exec_params ]] ; then
      echo "CANNOT FIND EXEC DETAILS IN LOG"
      #continue
    fi

	##First untar prep folders (needed to fill conf parameters table, excluding prep jobs)
	for bzip_file in prep_*.tar.bz2 ; do
		bench_folder="${bzip_file%%.*}"
		if [[ "${bench_folder:0:4}" != "run_" && "${bench_folder:0:5}" != "conf_" && ( ( ! -d "$bench_folder" ) || "$REDO_UNTARS" == "1" ) ]]  ; then
	        echo "Untaring $bzip_file"
	        tar -xjf "$bzip_file"
		fi
	done
	
    for bzip_file in *.tar.bz2 ; do

      bench_folder="${bzip_file%%.*}"
      if [[ "${bench_folder:0:4}" != "run_" && "${bench_folder:0:5}" != "prep_" && "${bench_folder:0:5}" != "conf_" && ( ( ! -d "$bench_folder" ) || "$REDO_UNTARS" == "1" ) ]]  ; then
        echo "Untaring $bzip_file"
        tar -xjf "$bzip_file"
      fi

      if [[ -d "$bench_folder" && "${bench_folder:0:4}" != "prep" && "${bench_folder:0:4}" != "run_" && "${bench_folder:0:5}" != "conf_" ]] ; then

        cd "$bench_folder"
        echo "Entering $bench_folder"

        exec="${folder}/${bench_folder}"

        #insert config and get ID_exec
        exec_values=$(echo "$exec_params" |egrep "^\"$bench_folder")
        if [[ ! -z $exec_values ]] ; then
          if [[ ! $folder == *_az ]] ; then
            cluster="1"
          else
            cluster="2"
          fi

          insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link)
                  VALUES (NULL, $cluster, \"$exec\", $exec_values)
                  ON DUPLICATE KEY UPDATE
                  start_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 0,19)}')',
                  end_time='$(echo "$exec_values"|awk '{first=index($0, ",\"201")+2; part=substr($0,first); print substr(part, 23,19)}')';"
          echo "$insert"
          $MYSQL "$insert"
        else
          echo "CANNOT FIND BENCH $bench_folder EXEC DETAILS IN LOG"
          #continue
        fi

        id_exec=""
        get_id_exec_conf_params "$exec"
        
        if [[ ! -z "$id_exec" ]] ; then
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
				echo "Not prep folder, considering all confs belonging to exec"
				jobconfs=$(find "./history/done" -type f -name "job*.xml");
			fi
			
			#Dump parameters from valid conf files to DB
			for job_conf in $jobconfs ; do
				params=$($CUR_DIR/getconf_param.sh -f $job_conf);
				filename=$(basename "$job_conf")
				job_name="${filename%.*}"
				job_name="${job_name:0:(-5)}"
				insert_conf_params_DB "$params" "$id_exec" "$job_name"
			done
		fi
		
		id_exec=""
        get_id_exec "$exec"

        echo -e "EP $exec_params \nEV $exec_values\nIDE $id_exec\nCluster $cluster"
			
        if [[ ! -z "$id_exec" ]] ; then

          #if dir does not exists or need to insert in DB
          if [[ "$REDO_ALL" == "1" || "$INSERT_DB" == "1" ]]  ; then
			
              #get the Hadoop job logs
              job_files=$(find "./history/done" -type f -name "job*"|grep -v ".xml")

              echo "Generating Hadoop Job CSVs for $bench_folder"
              rm -rf "hadoop_job"
rm -rf "sysstat"
              mkdir -p "hadoop_job"

              for job_file in $job_files ; do
                #Get hadoop job name
                job_name="${job_file##*/}"
                job_name="${job_name:0:21}"

                echo "Processing Job $job_name File $job_file"

                echo "Extrating Job history details for $job_file"
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
                  echo "Inserting into DB $csv_file TN $table_name"
                  #add host and missing data to csv
                  awk "NR == 1 {\$1=\"id,id_exec,job_name,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${job_name},\"\$1; print }" "$csv_file" > tmp.csv

                  insert_DB "${table_name}" "tmp.csv" "" ","
                else
                  echo -e "File $csv_file is INVALID\n$(cat $csv_file)"
                fi
              done
              cd ..; echo -e "\n"

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
                      echo "ERROR, no command for $table_name"
                    fi
                  done
                else
                  echo "File $sar_file is INVALID"
                fi
              done

              for vmstats_file in [vmstat-]*.log ; do
                if [[ $(head $vmstats_file |wc -l) -gt 1 ]] ; then
                  #get host name from file name
                  hostn="${vmstats_file:7:-4}"
                  table_name="VMSTATS"
                  echo "Inserting into DB $vmstats_file TN $table_name"

                  tail -n +2 "$vmstats_file" | awk '{out="";for(i=1;i<=NF;i++){out=out "," $i}}{print substr(out,2)}' | awk "NR == 1 {\$1=\"id_field,id_exec,host,time,\"\$1; print } NR > 1 {\$1=\"NULL,${id_exec},${hostn},\" (NR-2) \",\"\$1; print }" > tmp.csv

                  insert_DB "${table_name}" "tmp.csv" "" ","
                else
                  echo "File $vmstats_file is INVALID"
                fi
              done

              for bwm_file in [bwm-]*.log ; do
                if [[ $(head $bwm_file |wc -l) > 1 ]] ; then
                  #get host name from file name
                  hostn="${bwm_file:4:-4}"
                  #there are two formats, 9 and 15 fields
                  bwm_format="$(head -n 1 "$bwm_file" |grep -o ';'|wc -l)"
                  echo "BWM format $bwm_format"
                  head -n3 "$bwm_file"
                  if [[ $bwm_format -gt 9 ]] ; then
                    table_name="BWM2"
                    cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;timestamp;iface_name;bytes_out_s;bytes_in_s;bytes_total_s;bytes_in;bytes_out;packets_out_s;packets_in_s;packets_total_s;packets_in;packets_out;errors_out_s;errors_in_s;errors_in;errors_out\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp.csv
                  else
                    table_name="BWM"
                    cat "$bwm_file" | awk "NR == 1 {print \"id;id_exec;host;unix_timestamp;iface_name;bytes_out;bytes_in;bytes_total;packets_out;packets_in;packets_total;errors_out;errors_in\"} NR > 1 {\$1=\"NULL;${id_exec};${hostn};\"\$1; print }" > tmp.csv
                  fi

                  echo "Inserting into DB $bwm_file TN $table_name"

                  insert_DB "${table_name}" "tmp.csv" "" ";"
                else
                  echo "File $bwm_file is INVALID"
                fi
              done

            fi

          fi
          cd ..; echo -e "\n"
        fi
    done
    cd ..; echo -e "\n"
  fi
done