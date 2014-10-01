#!/bin/bash

if [ "$#" -ne "2" ]; then
  echo "Usage: get_exec_names.sh base_folder output_file"
  exit
fi

CUR_DIR=`pwd` 
cd $1
for folder in 201* ; do
  if [ -d $folder ]; then
    cd "$folder"
    for bzip_file in *.tar.bz2 ; do
      bench_folder="${bzip_file%%.*}"
      #Sanity check
      if [[ "$bench_folder" != "*" && "${bench_folder:0:4}" != "prep" && "${bench_folder:0:4}" != "run_" && "${bench_folder:0:5}" != "conf_" && "${bench_folder:(-5)}" != "_conf" ]]; then
        echo "$folder/$bench_folder" >> "$CUR_DIR/$2"
      fi
   done
   cd ..
  fi
done
