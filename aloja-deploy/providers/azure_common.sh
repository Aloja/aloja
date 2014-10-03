#AZURE specific functions



#global vars
bootStraped="true" #azure doens't need bootstraping

#### start $cloud_provider customizations

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
vm_get_status(){
 echo "$(azure vm show "$1" -s "$subscriptionID"|grep "InstanceStatus"|awk '{print substr($3,2,(length($3)-2));}')"
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

###for executables

#1 $node_name
node_connect() {
  logger "Connecting to subscription $subscriptionID, with details: ${user}@${dnsName}.cloudapp.net -p $vm_ssh_port -i ../secure/keys/myPrivateKey.key"
  ssh -i "../secure/keys/myPrivateKey.key" "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
}

#1 $node_name
node_delete() {
  logger "About to delete node $1 and its associated attached volumes. Continue?"
  pause
  azure vm delete -b -q "$1"
}