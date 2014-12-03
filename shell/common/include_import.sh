#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

#1) load common functions and global variables
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
#trap 'echo "RUNNING TRAP "; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM #EXIT

#2) load cluter/node config to get the default provider

#test and load cluster config
clusterConfigFile="cluster_defaults.conf"

ConfigFolderPath="$CONF_DIR/../conf"

[ ! -f "$ConfigFolderPath/$clusterConfigFile" ] && { logger "$ConfigFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
source "$ConfigFolderPath/$clusterConfigFile"


logger "Starting ALOJA import2db tool"

#4) Load the common cluster functions

source "$CONF_DIR/cluster_functions.sh"