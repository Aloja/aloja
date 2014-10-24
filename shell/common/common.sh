#common bash variables and functions across ALOJA
#must be sourced

#common variables
testKey="###OK###"

#common funtions

#$1 message $2 severity $3 log to file
logger() {
  local log_file="aloja-deploy.log"
  local dateTime="$(date +%Y%m%d_%H%M%S)"
  if [ ! -z "$vm_name" ] ; then
    local vm_info=" $vm_name"
  else
    local vm_info=""
  fi

  if [ -z "$3" ] ; then
    echo "$dateTime $$${vm_info}: $1"
  else
    echo "$dateTime $$${vm_info}: $1" >> $log_file
  fi
}

#trasposes new lines to selected string
#$1 string to traspose $2 traspose
nl2char() {
  tmp="$(echo -e "$1"|tr "\n" "$2")"
  echo "${tmp::-1}" #remove trailing $2
}

#$1 startTime
getElapsedTime() {
  elapsedTime='ERROR: start time not set.'
  [ ! -z $1 ] && elapsedTime="$(( $(date +%s) - $1 ))"
  echo "$elapsedTime"
}