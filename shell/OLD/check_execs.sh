#!/bin/bash

if [ "$#" -lt "1" ]; then
  echo "Usage: check_execs.sh execs_list [output]"
  exit
fi

outputdir="empty_execs.txt"
if [ "$#" -gt "1" ]; then
  outputdir=$2
fi

dir=`cat $1`
MYSQL_CREDENTIALS='-uroot'

check_exec() {
  mysql $MYSQL_CREDENTIALS 'aloja2' -e "select id_exec from aloja2.execs where exec = '$1' AND id_exec IN (SELECT id_exec FROM aloja_logs.SAR_cpu WHERE id_exec=id_exec) LIMIT 1" > $2
}

for execution in $dir; do
  check_exec "$execution" "tmp.txt"
  if [ $(wc tmp.txt -l | cut -d\  -f1) -lt "1" ]; then
    echo $execution >> $outputdir
  fi
  rm tmp.txt
done
