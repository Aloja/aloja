#common initialization, non-executable, must be sourced
self_name="$(basename $0)"

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [If no default provider then: <provider:azure|openstack|rackspace|on-premise|carma|vagrant>]  [Optional non-default conf_file]"; exit 1;}

#0) find the directory root

if [ -d  "/vagrant" ] ; then
  ROOT_DIR_INCLUDE="/vagrant"
else
  ROOT_DIR_INCLUDE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."
fi

CONF_DIR="$ROOT_DIR_INCLUDE/shell/common"
ALOJA_REPO_PATH="$ROOT_DIR_INCLUDE"

#1) load common functions and global variables

source "$CONF_DIR/common.sh"
#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }

#make sure we cleanup subprocesses on abnormal exit (ie ctrl+c)
setup_traps

logger "Starting ALOJA deploy tools"

#2) load cluter/node config to get the default provider

#test and load cluster config
clusterConfigFile="${type}_${1}.conf"
configFolderPath="$ROOT_DIR_INCLUDE/shell/conf"

[ ! -f "$configFolderPath/$clusterConfigFile" ] && { logger "$configFolderPath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config
logger "DEBUG: Loading $clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"

#3) Load the secured provider settings

# load defaultProvider
if [ -z $2 ]; then
  securedProviderFile="$ROOT_DIR_INCLUDE/secure/${defaultProvider}_settings.conf"
#load user specified provider conf file
elif [ -z $3 ]; then
  securedProviderFile="$ROOT_DIR_INCLUDE/secure/${2}_settings.conf"
#load user specified conf file
else
	securedProviderFile="$ROOT_DIR_INCLUDE/secure/$3"
fi

##OLD for loading unsecured files
#if [ ! -f "$securedProviderFile" ]; then
#  logger "WARNING: SECURED Conf file $securedProviderFile doesn't exists! defaultProvider=$defaultProvider"
#
#  #try non secured files (in git)
#  # load defaultProvider
#  if [ -z $2 ]; then
#    securedProviderFile="$ROOT_DIR_INCLUDE/aloja-deploy/providers/${defaultProvider}_settings.conf"
#  #load user specified provider conf file
#  elif [ -z $3 ]; then
#    securedProviderFile="$ROOT_DIR_INCLUDE/aloja-deploy/providers/${2}_settings.conf"
#  #load user specified conf file
#  else
#    securedProviderFile="$ROOT_DIR_INCLUDE/aloja-deploy/providers/$3"
#  fi
#
#  if [ ! -f "$securedProviderFile" ]; then
#    logger "ERROR: either secured or non-secured provider config files exists.  Exiting... DEBUG data: file=$securedProviderFile doesn't exists! defaultProvider=$defaultProvider"
#    exit 1
#  fi
#
#fi


#load non versioned conf first (order is important for overrides)
logger "DEBUG: Loading $securedProviderFile"
source "$securedProviderFile"

logger " for Provider: $cloud_provider"

#3) Re-load cluster config file (for overrides)

#logger "INFO: Re-Loading $clusterConfigFile"
source "$configFolderPath/$clusterConfigFile"


#4) Load the common cluster functions

#logger "DEBUG: Loading $CONF_DIR/cluster_functions.sh"
source "$CONF_DIR/cluster_functions.sh"


#5) load the provider functions

if [ ! -z "defaultProvider" ] && [ -z "$2" ] ; then
  providerFunctionsFile="$ROOT_DIR_INCLUDE/aloja-deploy/providers/${defaultProvider}.sh"
else
  providerFunctionsFile="$ROOT_DIR_INCLUDE/aloja-deploy/providers/${2}.sh"
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
    echo -e "ERROR: nova command not instaled, you can use the vagrant VM. Or run:\nrun apt-get install install python-pip;\nsudo pip install rackspace-novaclient"
    exit 1
  fi

elif [ "$defaultProvider" == "azure" ] ; then
  #check if azure command is installed
  if ! azure --version 2>&1 > /dev/null ; then
    echo "azure command not instaled. Run: sudo npm install azure-cli"
    exit 1
  fi
fi

#logger "DEBUG: Loading $providerFunctionsFile"
source "$providerFunctionsFile"