#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

#1) load common functions and global variables
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

###################

logger "INFO: loading benchmarks_defaults.conf"
source "$CONF_DIR/../conf/benchmarks_defaults.conf"

#test and load cluster config
clusterConfigFile="cluster_${clusterName}.conf"

configFolderPath="$CONF_DIR/../conf"

[ ! -f "$configFolderPath/$clusterConfigFile" ] && { logger "$configFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
logger "INFO: loading $configFolderPath/$clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"

## load defaultProvider
#if [ -z $2 ]; then
#  securedProviderFile="$CONF_DIR/../../secure/${defaultProvider}_settings.conf"
##load user specified provider conf file
#elif [ -z $3 ]; then
#  securedProviderFile="$CONF_DIR/../../secure/${2}_settings.conf"
##load user specified conf file
#else
#	securedProviderFile="$CONF_DIR/../../secure/$3"
#fi
#
##check for secured conf file
#if [ ! -f "$securedProviderFile" ]; then
#  echo "WARNING: Conf file $securedProviderFile doesn't exists! defaultProvider=$defaultProvider"
#  #exit
#else
#  #load non versioned conf first (order is important for overrides)
#  logger "INFO: loading $securedProviderFile"
#  source "$securedProviderFile"
#fi

source "$configFolderPath/$clusterConfigFile"

logger "Starting ALOJA deploy tools for Provider: $default_provider"

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