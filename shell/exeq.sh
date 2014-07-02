#!/bin/bash

#first check if already running
self_name="$(basename $0)"
self_pid="$$"
exists=$(pgrep $self_name|wc -l)
if [ "$exists" != "2" ] ; then
  echo "Process $self_name already running"
  exit
fi

trap 'kill $(jobs -p); exit;' SIGINT SIGTERM EXIT



echo "USER $USER"

Q_PATH="/home/$USER/qsub/queue"
EXEC_PATH="$Q_PATH/exec"
DONE_PATH="$Q_PATH/done"
CONF_PATH="$Q_PATH/conf"
LOG_FILE="$Q_PATH/queue.log"


file_name=""
#command="ls -l $Q_PATH| egrep -v '^d'|tail -n +2|head -n 1|awk '{print \$(NF)}'"
#command="ls -l $Q_PATH| egrep -v '^d'|tail -n +2|head -n 1|awk '{print \$(NF)}'"
get_first_file(){
  file_name=`ls -l $Q_PATH| egrep -v -e '^d'|grep '_conf_'|tail -n +1|head -n 1|awk '{print \$(NF)}'`
  #echo "FN $file_name" 2>&1 |tee -a "$LOG_FILE"
}

iteration=0
while true
do
  get_first_file
  current_file="$file_name"
  mod=$((iteration % 10))

  if [ -f "$current_file" ] ; then
    echo "Executing: $current_file" 2>&1 |tee -a "$LOG_FILE"
    mv "$Q_PATH/$current_file" "$EXEC_PATH/" 2>&1 |tee -a "$LOG_FILE"

    #execute command(s)
    /bin/bash "$EXEC_PATH/$current_file" 2>&1 >> "$LOG_FILE"

    echo "Done $current_file" 2>&1 |tee -a "$LOG_FILE"
    mv  "$EXEC_PATH/$current_file" "$DONE_PATH/" 2>&1 |tee -a "$LOG_FILE"
  else
    if [ "$mod" == "0" ] ; then
      echo "Sleeping, iteration $iteration" 2>&1 |tee -a "$LOG_FILE"
    fi
    sleep 1
  fi

  iteration=$((iteration + 1))
done

