#!/bin/bash

INSERT_DB=1 #if to dump CSV into the DB
DROP_DB_FIRST=1 #if to drop whatever is there on the first folder
REDO_ALL= #if to redo folders that have source files
REDO_UNTARS= #if to redo the untars for folders that have it
INSERT_BY_EXEC=1 #if to insert right after each folder

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

#TODO check if these variables are still needed
DROP_DB_FIRST=""
first_host=""
hostn=""
#CREATE TABLE AND LOAD VALUES FROM CSV FILE
# $1 TABLE NAME $2 PATH TO CSV FILE $3 DROP THE DB FIRST $4 DELIMITER
insert_DB(){
  echo "Inserting into DB $sar_file TN $1"
  if [[ "$DROP_DB_FIRST" == "1" && ( -z "$first_host" || "$first_host" == "$hostn" ) ]] ; then
    first_host="$hostn"
    echo "Droping and creating DB $1"
    bash "$CUR_DIR/load_csv.sh" "$2" "$1" "drop" "$4"
  else
    echo ""
    bash "$CUR_DIR/load_csv.sh" "$2" "$1" "$3" "$4"
  fi
  rm $2
}

echo "Starting"

for folder in 201* ; do

  if [[ -d "$folder" ]] && [ "${folder:0:8}" -gt "20130101" ] ; then
    echo "Entering folder $folder"
    cd "$folder"

    for bzip_file in *.tar.bz2 ; do

      bench_folder="${bzip_file%%.*}"

      if [[ "${bench_folder:0:4}" != "prep" && "${bench_folder:0:4}" != "run_" && ( ( ! -d "$bench_folder" ) || "$REDO_UNTARS" == "1" ) ]]  ; then
        echo "Untaring $bzip_file"
        tar -xjf "$bzip_file"
      fi

      if [[ -d "$bench_folder" ]] ; then

        cd "$bench_folder"

        if [[ ! -z $(ls sar*.sar) ]] ; then

          #if dir does not exists or need to insert in DB
          if [[ "$REDO_ALL" == "1" || ( ! -d "sysstat" ) || "$INSERT_DB" == "1" ]]  ; then

            #only produce SAR files if dir does not exists, but insert in DB down below
            if [[ "$REDO_ALL" == "1" || ( ! -d "sysstat" ) ]]  ; then
              echo "Generating SAR CSVs for $bench_folder"
              rm -rf "sysstat"
              mkdir -p "sysstat"

              for sar_file in sar*.sar ; do

                echo "Extracting from $sar_file"

                hostn="${sar_file:4:-4}"

                sar -b      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.io_rate.csv"
                sar -B      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.io_paging.csv"
                sar -I SUM  -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.interrupts.csv"
                sar -u      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.cpu.csv"
                sar -q      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.load.csv"
                sar -r      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.memory_util.csv"
                sar -R      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.memory.csv"
                sar -S      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.swap.csv"
                sar -W      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.swap_util.csv"
                sar -w      -f "$sar_file" |awk 'BEGIN { OFS="," }NR == 1 { date="20" substr($4,7,2) "-" substr($4,0,2) "-" substr($4,4,2);} NR == 3 {$1="date";print } NR >3 {  $1=date" "$1;print }'|head -n -1 > "sysstat/${hostn}.switches.csv"

                #paste "sysstat/${hostn}-"*.csv > "sysstat/${hostn}.mix.csv"

                #(per device)
                #sar -dp     -f "$sar_file" > "sysstat/${hostn}.block_device.csv"
                #sar -n DEV  -f "$sar_file" > "sysstat/${hostn}.net.csv"

              done

              #get the Hadoop job logs
              job_files=$(find "./history/done" -type f -name "job*"|grep -v ".xml")

              echo "Generating Hadoop Job CSVs for $bench_folder"
              rm -rf "hadoop_job"
              mkdir -p "hadoop_job"

              for job_file in $job_files ; do
                #Get hadoop job name
                job_name="${job_file##*/}"
                job_name="${job_name:0:21}"

                echo "Processing Job $job_name File $job_file"

#get the line, fields, cut by counters into files, transform to csv
tail "$job_file" | egrep 'Job JOBID=".*?" FINISH_TIME=".*?" JOB_STATUS="SUCCESS"'  | awk 'BEGIN {FS="\" "} \
{for(i=1;i<=NF;i++){ \
{print $i "\""} \
}}'|tr "{[" "\n"|\
sed -e 's/^(\([A-Z_]*\).*(\([0-9]*\)).*/\1="\2"/g'|\
head -n -1|egrep -v "^\(" |\
awk -v "job_name=$job_name" 'BEGIN {FS="="; a="";b="";name="SUMMARY";}\
{if($0 !~ /^.*COUNTERS=/) {a=a","$1; b=b","$2}\
else if(length($b)>0 && length($a)>0) {print substr(a,2) "\n" substr(b,2) > "hadoop_job/" job_name "." name ".csv"; a="";b="";name=$1}
}
END {if(length($b)>0 && length($a)>0) {print substr(a,2) "\n" substr(b,2) > "hadoop_job/" job_name "." name ".csv"; }}'

               echo "Extrating Job history details for $job_file"
               python2.7 "$CUR_DIR/job_history.py" "$job_file" > "hadoop_job/${job_name}.job_history.csv"
               python2.7 "$CUR_DIR/job_history.py" -t "$job_file" > "hadoop_job/${job_name}.task_history.csv"

              done
            fi

            #DB inserting scripts
            #TODO improve drop DB alg, can fail if first file is empty

            if [ "$INSERT_DB" == "1" ] ; then
              #first SAR CSVs
              cd sysstat
              for csv_file in *.csv ; do
                if [[ $(cat $csv_file |wc -l) > 1 ]] ; then
                  #get host name from csv file name
                  separator_pos=$(echo "$csv_file" | awk '{ print index($1,".")}')
                  separator_pos=$(expr "$separator_pos" - 1)
                  hostn="${csv_file:0:$separator_pos}"

                  table_name="SAR_${csv_file:$(expr length "${hostn}." ):-4}_dump"
                  echo "Inserting into DB $csv_file TN $table_name"
                  #add host and missing data to csv
                  awk "NR == 1 {\$1=\"exec,host,\"\$1; print } NR > 1 {\$1=\"${folder}/${bench_folder},${hostn},\"\$1; print }" "$csv_file" > tmp.csv

                  if [[ "$DROP_DB_FIRST" == "1" && ( -z "$first_host" || "$first_host" == "$hostn" ) ]] ; then

                    first_host="$hostn"
                    echo "Droping and creating DB $table_name"
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name" drop
                  else
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name"
                  fi
                  rm tmp.csv
                else
                  echo "File $csv_file is INVALID"
                fi

              done
              cd ..; echo -e "\n"

               for sar_file in sar*.sar ; do
                if [[ $(head $sar_file |wc -l) > 1 ]] ; then

                  for table_name in "SAR_block_devices" "SAR_net_devices" "SAR_io_rate" "SAR_net_errors" "SAR_net_sockets" ; do
                    sar_command=""
                    if [ "$table_name" == "SAR_block_devices" ] ; then
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
                      sadf -d "$sar_file" -- $sar_command | awk "NR == 1 {\$2=\"exec;\" \$2; print \$2} NR > 1 {\$1=\"${folder}/${bench_folder};\"\$1; print }" > "$csv_name"
                      insert_DB "${table_name}_dump" "$csv_name" "" ";"
                      #rm "$csv_name"
                    else
                      echo "ERROR, no command for $table_name"
                    fi
                  done

                else
                  echo "File $sar_file is INVALID"
                fi
              done


              for vmstats_file in [vmstat-]*.log ; do
                if [[ $(head $vmstats_file |wc -l) > 1 ]] ; then
                  #get host name from file name
                  hostn="${vmstats_file:7:-4}"
                  table_name="VMSTATS_dump"
                  echo "Inserting into DB $vmstats_file TN $table_name"
                  #add host and missing data to csv
                  tail -n +2 "$vmstats_file" | awk '{out="";for(i=1;i<=NF;i++){out=out "," $i}}{print substr(out,2)}' | awk "NR == 1 {\$1=\"exec,host,time,\"\$1; print } NR > 1 {\$1=\"${folder}/${bench_folder},${hostn},\" (NR-2) \",\"\$1; print }" > tmp.csv

                  if [[ "$DROP_DB_FIRST" == "1" && ( -z "$first_host" || "$first_host" == "$hostn" ) ]] ; then

                    first_host="$hostn"
                    echo "Droping and creating DB $table_name"
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name" drop
                  else
                    echo ""
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name"
                  fi
                  rm tmp.csv
                else
                  echo "File $vmstats_file is INVALID"
                fi
              done

              for bwm_file in [bwm-]*.log ; do
                if [[ $(head $bwm_file |wc -l) > 1 ]] ; then
                  #get host name from file name
                  hostn="${bwm_file:4:-4}"
                  table_name="BWM_dump"
                  echo "Inserting into DB $bwm_file TN $table_name"
                  #add host and missing data to csv
                  cat "$bwm_file" | tr ";" "," | awk "NR == 1 {print \"exec,host,time,unix_timestamp,iface_name,bytes_out,bytes_in,bytes_total,packets_out,packets_in,packets_total,errors_out,errors_in\"} NR > 1 {\$1=\"${folder}/${bench_folder},${hostn},\" (NR-2) \",\"\$1; print }" > tmp.csv

                  if [[ "$DROP_DB_FIRST" == "1" && ( -z "$first_host" || "$first_host" == "$hostn" ) ]] ; then

                    first_host="$hostn"
                    echo "Droping and creating DB $table_name"
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name" drop
                  else
                    echo ""
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name"
                  fi
                  rm tmp.csv
                else
                  echo "File $bwm_file is INVALID"
                fi
              done

              #then Hadoop's
              cd hadoop_job
              for csv_file in *.csv ; do
                if [[ $(head $csv_file |wc -l) > 1 ]] ; then
                  #get the job name and counter type from csv file name
                  separator_pos=$(echo "$csv_file" | awk '{ print index($1,".")}')
                  job_name="${csv_file:0:$(($separator_pos - 1))}"
                  counter="${csv_file:$separator_pos:-4}"
                  table_name="JOB_${counter}_dump"
                  echo "Inserting into DB $csv_file TN $table_name"
                  #add host and missing data to csv
                  awk "NR == 1 {\$1=\"exec,job_name,\"\$1; print } NR > 1 {\$1=\"${folder}/${bench_folder},${job_name},\"\$1; print }" "$csv_file" > tmp.csv

                  if [[ "$DROP_DB_FIRST" == "1" && ( -z "$first_host" || "$first_host" == "$counter" ) ]] ; then
                    first_host="$counter"
                    echo "Droping and creating DB $table_name"
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name" drop
                  else
                    bash "$CUR_DIR/load_csv.sh" tmp.csv "$table_name"
                  fi
                  rm tmp.csv
                else
                  echo "File $csv_file is INVALID"
                fi

              done
              cd ..; echo -e "\n"

              #we drop DB in first folder only
              DROP_DB_FIRST=""
            fi

            if [ "$INSERT_BY_EXEC" == "1" ] ; then
              echo -e "\nProcessing EXEC into DB"
              bash "$CUR_DIR/load_db.sh" "" "1"
            fi
          fi
        fi
        cd ..; echo -e "\n"
      fi
    done
    cd ..; echo -e "\n"
  fi
done