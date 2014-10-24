#make sure we cleanup subprocesses
trap 'echo "RUNNING TRAP"; [ $(jobs -p) ] && kill $(jobs -p); exit;' SIGINT SIGTERM #EXIT

#common initialization, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [If no default provider then: <provider:azure|openstack|rackspace|on-premise|pedraforca>]  [Optional non-default conf_file]"; exit 1;}

clusterConfigFile="${type}_${1}.conf"

source "../shell/common/cluster_functions.sh"

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

#load the provider file
source "$providerFunctionsFile"

#load defaultProvider
if [ -z $2 ]; then
  confFile="../secure/${defaultProvider}_settings.conf"
#load user specified provider conf file
elif [ -z $3 ]; then
    confFile="../secure/${2}_settings.conf"
#load user specified conf file
else
	confFile="../secure/$3"
fi

#check for secured conf file
if [ ! -f "$confFile" ]; then
  echo "ERROR: Conf file $confFile doesn't exists! defaultProvider=$defaultProvider"
  exit
fi

#load non versioned conf first (order is important for overrides)
source "$confFile"

#re-load the provider file (for overwrites)
#TODO fix double sourcing this later
source "$providerFunctionsFile"



