#common initialization, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

[ -z "$type" ] && type="cluster"

[ -z $1 ] || [ -z $2 ] && { echo "Usage: $self_name ${type}_name <provider:azure|openstack|rackspace> [conf_file]"; exit 1;}


if [ -z $3 ]; then
	confFile="../secure/${2}_settings.conf"
else
	confFile="../secure/$2"
	if [ ! -e "$confFile" ]; then
		echo "ERROR: Conf file $confFile doesn't exists!"
		exit
	fi
fi

#load non versioned conf first (order is important for overrides)
source "$confFile"

clusterConfigFile="${type}_${1}.conf"

source "../shell/common/cluster_functions.sh"


if [ "$2" == "rackspace" ] || [ "$2" == "openstack" ] ; then

  #check if azure command is installed
  if ! nova --version 2>&1 > /dev/null ; then
    echo "nova command not instaled. Run: sudo pip install install rackspace-novaclient"
    exit 1
  fi

  source "providers/openstack_common.sh"

fi



