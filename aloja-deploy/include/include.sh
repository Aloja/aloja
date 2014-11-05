#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [If no default provider then: <provider:azure|openstack|rackspace|on-premise|pedraforca>]  [Optional non-default conf_file]"; exit 1;}

#1) load common functions and global variables
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../shell/common"
source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
trap 'echo "RUNNING TRAP "; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM #EXIT

#2) load cluter/node config to get the default provider

#test and load cluster config
clusterConfigFile="${type}_${1}.conf"
ConfigFolderPath="$CONF_DIR/../conf"

[ ! -f "$ConfigFolderPath/$clusterConfigFile" ] && { logger "$ConfigFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
source "$ConfigFolderPath/$clusterConfigFile"

#3) Load the secured provider settings

# load defaultProvider
if [ -z $2 ]; then
  securedProviderFile="../secure/${defaultProvider}_settings.conf"
#load user specified provider conf file
elif [ -z $3 ]; then
  securedProviderFile="../secure/${2}_settings.conf"
#load user specified conf file
else
	securedProviderFile="../secure/$3"
fi

#check for secured conf file
if [ ! -f "$securedProviderFile" ]; then
  echo "ERROR: Conf file $securedProviderFile doesn't exists! defaultProvider=$defaultProvider"
  exit
fi

#load non versioned conf first (order is important for overrides)
source "$securedProviderFile"

#3) Re-load cluster config file (for overrides)

source "$ConfigFolderPath/$clusterConfigFile"

logger "Starting ALOJA deploy tools for Provider: $cloud_provider"

#4) Load the common cluster functions

source "$CONF_DIR/cluster_functions.sh"


#5) load the provider functions

if [ ! -z "defaultProvider" ] ; then
  providerFunctionsFile="providers/${defaultProvider}.sh"
else
  providerFunctionsFile="providers/${2}.sh"
fi

#check if provider file exists
if [ ! -f "$providerFunctionsFile" ] ; then
  echo "ERROR: cannot find providers function file in $providerFunctionsFile"
  exit 1
fi

if [ "$2" == "rackspace" ] || [ "$2" == "openstack" ] ; then

  #check if azure command is installed
  if ! nova --version 2>&1 > /dev/null ; then
    echo "ERROR: nova command not instaled. Run: sudo pip install install rackspace-novaclient"
    exit 1
  fi

elif [ "$2" == "azure" ] ; then
  #check if azure command is installed
  if ! azure --version 2>&1 > /dev/null ; then
    echo "azure command not instaled. Run: sudo npm install azure-cli"
    exit 1
  fi
fi

source "$providerFunctionsFile"