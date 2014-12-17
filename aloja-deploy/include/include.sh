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
trap 'echo "RUNNING TRAP "; sleep 1 && [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM #EXIT


logger "Starting ALOJA deploy tools"

#2) load cluter/node config to get the default provider

#test and load cluster config
clusterConfigFile="${type}_${1}.conf"
configFolderPath="$CONF_DIR/../conf"

[ ! -f "$configFolderPath/$clusterConfigFile" ] && { logger "$configFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
logger "INFO: Loading $clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"

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
logger "INFO: Loading $securedProviderFile"
source "$securedProviderFile"

logger " for Provider: $cloud_provider"

#3) Re-load cluster config file (for overrides)

#logger "INFO: Re-Loading $clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"



#4) Load the common cluster functions

#logger "INFO: Loading $CONF_DIR/cluster_functions.sh"
source "$CONF_DIR/cluster_functions.sh"


#5) load the provider functions

if [ ! -z "defaultProvider" ] && [ -z "$2" ] ; then
  providerFunctionsFile="providers/${defaultProvider}.sh"
else
  providerFunctionsFile="providers/${2}.sh"
  defaultProvider="$2"
fi



#check if provider file exists
if [ ! -f "$providerFunctionsFile" ] ; then
  echo "ERROR: cannot find providers function file in $providerFunctionsFile"
  exit 1
fi

if [ "$defaultProvider" == "rackspace" ] || [ "$defaultProvider" == "openstack" ] ; then

  #check if azure command is installed
  if ! nova --version 2>&1 > /dev/null ; then
    echo -e "ERROR: nova command not instaled. Run:\nrun apt-get install install python-pip;\nsudo pip install rackspace-novaclient"
    exit 1
  fi

elif [ "$defaultProvider" == "azure" ] ; then
  #check if azure command is installed
  if ! azure --version 2>&1 > /dev/null ; then
    echo "azure command not instaled. Run: sudo npm install azure-cli"
    exit 1
  fi
fi

#logger "INFO: Loading $providerFunctionsFile"
source "$providerFunctionsFile"