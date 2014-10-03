#common functions, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

echo "WARNING: using deprecated deployer"

#check if azure command is installed
if ! azure --version 2>&1 > /dev/null ; then
  echo "azure command not instaled. Run: sudo npm install azure-cli"
  exit 1
fi

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [conf_file]"; exit 1;}

if [ -z $2 ]; then
	confFile="../secure/azure_settings.conf"
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


vm_exists() {
  logger "Checking if VM $1 exists..."

if [ ! -z "$(azure vm list -s "$subscriptionID"|grep " $1 " | grep " $dnsName.cloudapp.net ")" ] ; then
    return 0
  else
    return 1
  fi
}

# $1 vm name $2 ssh port
vm_create() {

  #check if the port was specified
  if [ ! -z "$2" ] ; then
    ssh_port="$2"
  else
    ssh_port=$(( ( RANDOM % 65535 )  + 1024 ))
  fi

  logger "Creating VM $1 with SSH port $ssh_port..."

  azure vm create \
        -s "$subscriptionID" \
        --connect "$dnsName" `#Deployment name` \
        --vm-name "$1" \
        --vm-size "$vmSize" \
        `#--location 'West Europe'` \
        --affinity-group "$affinityGroup" \
        --virtual-network-name "$virtualNetworkName" \
        --subnet-names "$subnetNames" \
        --ssh "$ssh_port" \
        --ssh-cert "$sshCert" \
        `#-v` \
        `#'test-11'` `#DNS name` \
        "$vmImage" \
        "$user" "$password"

#--location 'West Europe' \

}

#$1 vm_name
wait_vm_ready() {
  logger "Checking status of VM $1"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do
    currentStatus="$(azure vm show "$1" -s "$subscriptionID"|grep "InstanceStatus"|awk '{print substr($3,2,(length($3)-2));}')"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "ReadyRole" ] ; then
      logger " VM $1 is ready!"
      break
    else
      logger " VM $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempts."
    fi

    #sleep 1
  done
}

#"$vm_name" "$vm_ssh_port" must be set before
#1 number of tries
wait_vm_ssh_ready() {
  logger "Checking SSH status of VM $vm_name"
  waitStartTime="$(date +%s)"
  for tries in {1..150}; do

    test_action="$(vm_execute " [ \"\$\(ls\)\" ] && echo '$testKey'")"
    #in case we get a welcome banner we need to grep
    test_action="$(echo -e "$test_action"|grep "$testKey")"

    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ ! -z "$test_action" ] ; then
      logger " VM $vm_name is ready!"
      return 0
      break #just in case
    else
      logger " VM $vm_name is down. Waiting for: $waitElapsedTime s. $tries attempts. Output: $test_action"
    fi

    #stop if max number of tries has been specified
    [ ! -z "$1" ] && [[ "$tries" -ge "$1" ]] && break

    sleep 1
  done

  return 1
}

#$1 vm_name
number_of_attached_disks() {
  numberOfDisks="$(azure vm disk list " $1 " |grep " $1 "|wc -l)"
  #substract the system volume
  numberOfDisks="$(( numberOfDisks - 1 ))"
  echo "$numberOfDisks"
}

#$1 vm_name $2 disk size in MB $3 disk number
vm_attach_new_disk() {
  logger " Attaching a new disk #$3 to VM $1 of size ${2}MB"
  azure vm disk attach-new "$1" "$2" -s "$subscriptionID"
}

#$1 commands to execute $2 set in parallel (&)
#$vm_ssh_port must be set before
vm_execute() {
  #logger "Executing in VM $vm_name command(s): $1"

  chmod 0600 "../secure/keys/myPrivateKey.key"

  #echo to print special chars;
  if [ -z "$2" ] ; then
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q -o connectTimeout=5 "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
  else
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q -o connectTimeout=5 "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port" &
  fi
}

#$1 source files $2 destination $3 extra options
#$vm_ssh_port must be set first
vm_local_scp() {
    logger "SCPing files"
    #eval is for parameter expansion
    scp -i "../secure/keys/myPrivateKey.key" -P "$vm_ssh_port" $(eval echo "$3") $(eval echo "$1") "$user"@"${dnsName}.cloudapp.net:$2"
}

#$1 $endpoints list $2 end1 $3 end2
vm_check_endpoint_exists() {
	echo $1 | grep $2 | grep $3
	if [ "$?" -ne "0" ]; then
	 return 0
	else
 	 return 1
	fi
}

vm_endpoints_create() {
	endpointList=$(azure vm endpoint list $vm_name)
	for endpoint in "${endpoints[@]}"
	do
		end1=$(echo $endpoint | cut -d: -f1)
		end2=$(echo $endpoint | cut -d: -f2)
		if vm_check_endpoint_exists "$endpointList" "$end1" "$end2"; then
			echo "Adding endpoint $endpoint to $vm_name"	
			azure vm endpoint create "$vm_name" $end1 $end2
		else
			echo "Endpoint $end1:$end2 already exists"
		fi
	done
	azure vm endpoint list "$vm_name"
}