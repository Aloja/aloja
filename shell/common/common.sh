#common bash variables and functions across ALOJA
#must be sourced

# Check bash version >= 4
if (( BASH_VERSINFO[0] < 4 )) ; then
  echo -e "ERROR: bash 4 or newer is required to run ALOJA.  If not present, you can run it from the vagrant box"
  exit 1
fi

#common variables
startTime="$(date +%s)"
testKey="###OK###"

[ ! "$PARENT_PID" ] && PARENT_PID=$$ #for killing the process from subshells
EXTRA_TRAP_CMDS="" #add to this global extra commands for the trap cleanup (e.g., stop services)
DONT_RETRY_TRAP="" #prevent trap loops

#common funtions

#$1 message $2 severity $3 log to file
logger() {
  local log_file="aloja-deploy.log"
  local dateTime="$(date +%Y%m%d_%H%M%S)"
  local vm_info
  local to_stderr

  if [ "$vm_name" ] ; then
    local vm_info=" $vm_name"
  fi

  local output=""

  # Colorize when on interactive TERM TODO implement better
  if [[ -t 1 || "$ALOJA_FORCE_COLORS" ]] ; then
    local reset="$(tput sgr0)"
    local red="$(tput setaf 1)"
    local green="$(tput setaf 2)"
    local yellow="$(tput setaf 3)"
    local cyan="$(tput setaf 6)"
    local white="$(tput setaf 7)"

    if [[ "$1 " == "DEBUG:"* ]] ; then
      output="${cyan}$dateTime $$${vm_info}: $1${reset}"
    elif [[ "$1 " == "INFO:"* ]] ; then
      output="${green}$dateTime $$${vm_info}: $1${reset}"
    elif [[ "$1 " == "WARNING:"* ]] ; then
      output="${yellow}$dateTime $$${vm_info}: $1${reset}"
    elif [[ "$1 " == "ERROR:"* ]] ; then
      output="${red}$dateTime $$${vm_info}: $1${reset}"
    else
      output="${white}$dateTime $$${vm_info}: $1${reset}"
    fi
  # non-interactive (no colors)
  else
    output="$dateTime $$${vm_info}: $1"
  fi

  if [ -z "$3" ] ; then
    echo -e "$output"
  else
    echo -e "$output" >> $log_file
  fi
}

# [dangerous] Function that automatically logs all script output to file
# and strerr also to it's own file (if any)
# NOTE: some lines might be out of order and need to press a key to exit
# NOTE2: when starting the subprocess we loose the 'trap' so we need to set it (and update it if necessary)
# $1 file_name
log_all_output() {
  local file_name="$1"

  # Restore exec in case we are updating or it has been modified before
  exec &>/dev/tty

  if [ "$ALOJA_FORCE_COLORS" ] ; then
    local strip_colors="sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'"
    exec 1> >(setup_traps && tee -a >(eval $strip_colors >> "$file_name.log") ) \
         2> >(tee -a >(eval $strip_colors >> "$file_name.log") | \
              tee -a >(eval $strip_colors >> "$file_name.err") >&2)
  else
    exec 1> >(setup_traps && tee -a  "$file_name.log") \
         2> >(tee -a "$file_name.err" | tee -a "$file_name.log" >&2)
  fi

  #exec > >(tee -a "$file_name.log") 2>&1
  #touch "$file_name.log" "$file_name.err"
  #chmod 777 "$file_name.log" "$file_name.err"
  #stdbuf -i0 -o0 -e0 #avoid buffering
}

#log and die, $1 message
die() {
  logger "ERROR: $1" >&2 #>&2 to print the output
  kill -s TERM "$PARENT_PID"
  sleep 1 # to allow time for the kill
  echo "FATAL ERROR: should not be here. Exit" >2
  exit 1 #should not arrive here, but...
}

# Set the cleanup process on abanormal exit
# $1 extra commands to add
setup_traps(){
  local extra_cmds="$1"
  local trap_cmds="
((DONT_RETRY_TRAP++))
if (( DONT_RETRY_TRAP > 1 )) ; then
  echo 'In a trap loop. Exit' >2 ;
  exit 1;
fi
logger 'WARNING: TRAP received signal $signal for process $$. Cleaning up before exit...';
$extra_cmds
extra_traps;
"
  trap_cmds+='
jobs_to_kill="$(jobs -p)";
if (( "$(echo -e "$jobs_to_kill" |wc -l)" > 1 )) ; then
  logger "DEBUG: Attempting to kill -9 remaining process(es): $jobs_to_kill";
  kill -9 $jobs_to_kill;
else
  logger "DEBUG: No processes left, exiting";
fi
echo -e "\n\n" #to prevent buffering
exit 1;
'

  # First clear other possible traps
  trap - SIGINT SIGTERM SIGKILL EXIT

  # Create independent traps to know the signal
  for signal in SIGINT SIGTERM SIGKILL ; do
    trap "$trap_cmds" $signal
  done
}

# Executes the list of traps added during execution if any
extra_traps() {
  if [ "$EXTRA_TRAP_CMDS" ] ; then
    logger "DEBUG: Executing: $EXTRA_TRAP_CMDS"
    eval $EXTRA_TRAP_CMDS
  fi
}

# Updates the abnormal exit cleanup process with more commands to execute
# $1 extra commands
# $2 update the logger's traps too (optional)
update_traps(){
  local extra_cmds="$1"
  local update_logger="$2"

  # Update the globals so that they are not deleted if the function is called again
  EXTRA_TRAP_CMDS+="$extra_cmds"

  # Setup the traps again
  setup_traps
  [ "$update_logger" ] && log_all_output "$JOB_PATH/${0##*/}"
}

# Sources file and prints a log message
# with the intent to centralize and control sources
# NOTE: declares in sources will not work as they will be local to the function
# $1 file to source
source_file() {
  local file="$1"
  if [ -f "$file" ] ; then
    logger "DEBUG: Loading ${file##*/}"
    source "$file"
  else
    die "Cannot source ${file##*/}. Not found in path: $file"
  fi
}
#already loaded this file, but since we didn't had the logger we print it now
logger "DEBUG: Loading ${BASH_SOURCE##*/}"

#trasposes new lines to selected string
#$1 string to traspose $2 traspose
nl2char() {
  local tmp="$(echo -e "$1"|tr "\n" "$2")"
  echo -e "${tmp%?}" #remove trailing $2
}

#trasposes old string to new string
#$1 string to traspose $2 old string $2 new string
char2char() {
  local tmp="$(echo -e "$1"|tr "$2" "$3")"
  echo -e "${tmp}"
}

# Removes duplicate lines
# $1 string with possibly duplicate lines
remove_duplicate_lines() {
  local string="$1"
  echo -e "$(echo -e "$string"|sort -u)"
}

# Returns true if needle is in hay stack
# $1 hay stack (list)
# $2 needle (element)
inList() {
  local hay_stack="$1"
  local needle="$2"
  local found="1" #error code in shell

  for element in $hay_stack ; do
    if [ "$needle" == "$element" ] ; then
      local found="0" #success
      break
#    else
#      logger "DEBUG: not in list $element needle $needle list $hay_stack"
    fi
  done

  return "$found"
}

#$1 startTime
getElapsedTime() {
  elapsedTime='ERROR: start time not set.'
  [ ! -z $1 ] && elapsedTime="$(( $(date +%s) - $1 ))"
  echo "$elapsedTime"
}

templateLead='### BEGIN ALOJA TEMPLATE ###'
templateTail='### END ALOJA TEMPLATE ###'

# Edits a file on the local filesystem and inserts or updates template data
# $1 source filename path $2 replace content
template_update_file() {

  #logger "INFO: Applying template changes to $1"

  if [ "$(grep "$templateLead" "$testFile")" ] ; then
    #logger "INFO: template lines found, executing sed"
    local mktempFile="$(mktemp)"
    echo -e "$2" > "$mktempFile"

    sed -i.bak -e "/^$templateLead\$/,/^$templateTail\$/{ /^$templateLead\$/{p; r $mktempFile
            }; /^$templateTail\$/p; d }"  "$1"

    rm "$mktempFile" #remove the temporary file

  else
    #logger "INFO: not found, appending (or creating file)"
    echo -e "$templateLead\n$2\n$templateTail" >> "$testFile"
  fi
}

# Receives file contents and echos contents with template insertion or update
#$1 file content path $2 replace content
template_update_stream() {

  if [ "$(echo -e "$1" |grep "$templateLead")" ] ; then
    #logger "INFO: template lines found, executing sed"
    local mktempFile="$(mktemp)"
    echo -e "$2" > "$mktempFile"

    echo -e "$1" | sed -e "/^$templateLead\$/,/^$templateTail\$/{ /^$templateLead\$/{p; r $mktempFile
            }; /^$templateTail\$/p; d }"

    rm "$mktempFile" #remove the temporary file

  else
    #logger "INFO: not found, appending"
    echo -e "$1\n\n$templateLead\n$2\n$templateTail\n\n"
  fi
}

cachePrefix="cache_"
deployCacheFolderPath="$CONF_DIR/../../aloja-deploy/cache"

#$1 filename $2 contents
cache_put() {
  local cacheFileName="$deployCacheFolderPath/${cachePrefix}${1}"
  echo -e "$2" > "$cacheFileName"
}

#$1 filename $2 expriry
cache_get() {

  local cacheFileName="$deployCacheFolderPath/${cachePrefix}${1}"

  #logger "DEBUG: Looking  cache for file $cacheFileName expiry $2" "" "log to file"

  if [ -f "$cacheFileName" ] ; then
    local lastModified="$(expr 1 + $(date +%s) - $(stat --printf='%Y' "$cacheFileName"))"

    if [[ "$2" -gt "$lastModified" ]] ; then
      #logger "DEBUG: Cache found for $1" "" "log to file"
      #output cache contents
      cat "$cacheFileName"
    else
      : #logger "DEBUG: Cache not found for $cacheFileName with $2 secs timeout Last modified: $lastModified" "" "log to file"
    fi
  else
      : #logger "DEBUG: Cache file not found $cacheFileName Last modified: $lastModified" "" "log to file"
  fi
}

cache_delete(){
  local cacheFileName="$deployCacheFolderPath/${cachePrefix}${1}"
  rm -f "$cacheFileName"
}


# Save env and global vars to file
# $1 file path
save_env() {
  local path="$1"
  # save all exept for passwords andd SHS info
  ( set -o posix ; set ) | grep -i -v "password" | grep -i -v "SSH" > "$path"
}

# Function to dynamically construct function names
# $1 function name to try to call
# $2 severy of error in case function doesn't exists (optional) (INFO, ERROR, etc)
function_call() {
  local function_name="$1"
  local severity="$2"

  #check if function exists and call it
  if type "$function_name" &>/dev/null ; then
    eval "$function_name"
  # doesnt exists, now what...
  else
    if [ "$severity" ] ; then
      if [ "$severity" == "ERROR" ] ; then
        die "Function $function_name does not exists"
      else
        logger "${severity}: Function name $function_name is not defined or not necessary"
      fi
    else
      logger "DEBUG: Function name $function_name is not defined or not necessary"
    fi
  fi
}

# Checks if the command has been run inside the vagrant VM
inside_vagrant() {
  if [ -d  "/vagrant" ] ; then
    return 0
  else
    return 1
  fi
}
