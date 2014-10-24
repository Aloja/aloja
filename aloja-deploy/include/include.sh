#common initialization, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

[ -z "$type" ] && type="cluster"

[ -z $1 ] || [ -z $2 ] && { logger "Usage: $self_name ${type}_name <provider:azure|openstack|rackspace|on-premise|pedraforca> [conf_file]"; exit 1;}


if [ -z $3 ]; then
	confFile="../secure/${2}_settings.conf"
else
	confFile="../secure/$3"
	if [ ! -e "$confFile" ]; then
		logger "ERROR: Conf file $confFile doesn't exists!"
		exit
	fi
fi

#load non versioned conf first (order is important for overrides)
source "$confFile"

clusterConfigFile="${type}_${1}.conf"

source "../shell/common/cluster_functions.sh"


providerFunctionsFile="providers/${2}.sh"

#check if azure command is installed
if [ ! -f "$providerFunctionsFile" ] ; then
  logger "ERROR: cannot find providers function file in $providerFunctionsFile"
  exit 1
fi

if [ "$2" == "rackspace" ] || [ "$2" == "openstack" ] ; then

  #check if azure command is installed
  if ! nova --version 2>&1 > /dev/null ; then
    logger "ERROR: nova command not instaled. Run: sudo pip install install rackspace-novaclient"
    exit 1
  fi

elif [ "$2" == "azure" ] ; then
  #check if azure command is installed
  if ! azure --version 2>&1 > /dev/null ; then
    logger "azure command not instaled. Run: sudo npm install azure-cli"
    exit 1
  fi

fi

#load the provider file
source "$providerFunctionsFile"



