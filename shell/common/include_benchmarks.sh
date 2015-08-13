#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

#1) load common functions and global variables
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
trap 'echo "RUNNING TRAP "; sleep 1 && [ $(jobs -p) ] && kill $(jobs -p); exit 1;' SIGINT SIGTERM
PARENT_PID=$$ #for killing the process from subshells

###################

#test and load cluster config
clusterConfigFile="cluster_${clusterName}.conf"

configFolderPath="$CONF_DIR/../conf"

[ ! -f "$configFolderPath/$clusterConfigFile" ] && { logger "$configFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
logger "INFO: loading $configFolderPath/$clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"

# load defaultProvider
logger "INFO: attempting to load secured account configs if present"
securedProviderFile="$CONF_DIR/../../secure/${defaultProvider}_settings.conf"

if [ -f "$securedProviderFile" ] ; then
  logger "INFO: loading $securedProviderFile"
  source "$securedProviderFile"
else
  logger "INFO: no secured accounts file present"
fi

logger "INFO: loading benchmarks_defaults.conf"
source "$CONF_DIR/../conf/benchmarks_defaults.conf"



##check for secured conf file
#if [ ! -f "$securedProviderFile" ]; then
#  echo "WARNING: Conf file $securedProviderFile doesn't exists! defaultProvider=$defaultProvider"
#  #exit
#else
#  #load non versioned conf first (order is important for overrides)
#  logger "INFO: loading $securedProviderFile"
#  source "$securedProviderFile"
#fi

#source "$configFolderPath/$clusterConfigFile"

logger "Starting ALOJA benchamking tools for Provider: $defaultProvider"

source "$CONF_DIR/cluster_functions.sh"

if [ ! -z "defaultProvider" ] ; then
  providerFunctionsFile="$CONF_DIR/../../aloja-deploy/providers/${defaultProvider}.sh"
else
  providerFunctionsFile="$CONF_DIR/../../aloja-deploy/providers/${2}.sh"
fi

#check if provider file exists
if [ ! -f "$providerFunctionsFile" ] ; then
  echo "ERROR: cannot find providers function file in $providerFunctionsFile"
  exit 1
fi

#if [ "$2" == "rackspace" ] || [ "$2" == "openstack" ] ; then
#
#  #check if azure command is installed
#  if ! nova --version 2>&1 > /dev/null ; then
#    echo "ERROR: nova command not instaled. Run: sudo pip install install rackspace-novaclient"
#    exit 1
#  fi
#
#elif [ "$2" == "azure" ] ; then
#  #check if azure command is installed
#  if ! azure --version 2>&1 > /dev/null ; then
#    echo "azure command not instaled. Run: sudo npm install azure-cli"
#    exit 1
#  fi
#fi

logger "INFO: loading $providerFunctionsFile"
source "$providerFunctionsFile"

#bencmark sources
logger "INFO: loading $CONF_DIR/common_benchmarks.sh"
source "$CONF_DIR/common_benchmarks.sh"

logger "INFO: loading $CONF_DIR/benchmark_${BENCH}.sh"
source "$CONF_DIR/benchmark_${BENCH}.sh"

#load cluster or node config
logger "INFO: Re-loading $configFolderPath/$clusterConfigFile for overrides"
source "$configFolderPath/$clusterConfigFile"