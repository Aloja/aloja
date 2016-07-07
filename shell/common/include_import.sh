#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

#1) load common functions and global variables
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
#trap 'echo "RUNNING TRAP "; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM #EXIT

#2) load cluster/node config to get the default provider

#test and load cluster config
clusterConfigFile="cluster_defaults.conf"

configFolderPath="$CONF_DIR/../conf"

[ ! -f "$configFolderPath/$clusterConfigFile" ] && { logger "$configFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
source_file "$configFolderPath/$clusterConfigFile"


logger "Starting ALOJA import2db tool"

#4) Load the common cluster functions
[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"
source_file "$ALOJA_REPO_PATH/shell/common/cluster_functions.sh"
source_file "$ALOJA_REPO_PATH/shell/common/import_functions.sh"
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
source_file "$ALOJA_REPO_PATH/shell/common/common_benchmarks.sh"


#Check if to use a special version of sar or the system one
#nico pc
if [[ ! -z $(uname -a|grep "\-ARCH") ]] ; then
  sadf="$CUR_DIR/sar/archlinux/sadf"
  DEV_PC="true"
#ubuntu
#elif [[ ! -z $(lsb_release -a|grep Ubuntu) ]] ; then
#  sadf="$CUR_DIR/sar/ubuntu/sadf"
#aaron's machines
elif [ "$(hostname)" == "acall" ] || [ "$(hostname)" == "belkar" ] ; then
   DEV_PC="true"
#vagrant
#elif [ "$(hostname)" == "vagrant" ] ; then
#  DEV_PC="true"
#default
else
  sadf="/usr/bin/sadf"
fi

#TABLE MANIPULATION
#MYSQL_ARGS="-uroot --local-infile -f -b --show-warnings " #--show-warnings -B

if [ ! "$DEV_PC" ] ; then
  MYSQL_CREDENTIALS="" #using sudo if from same machine
else
  MYSQL_CREDENTIALS="-uvagrant -pvagrant -h127.0.0.1 -P4306"
fi

MYSQL_ARGS="$MYSQL_CREDENTIALS --local-infile -f -b --show-warnings -B" #--show-warnings -B
DB="aloja2"
MYSQL_CREATE="sudo mysql $MYSQL_ARGS -e " #do not include DB name in case it doesn't exist yet
MYSQL="sudo mysql $MYSQL_ARGS $DB -e "
