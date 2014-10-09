#AZURE specific functions

#global vars
bootStrapped="false"

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

get_OK_status() {
  echo "ReadyRole"
}

#$1 vm_name
number_of_attached_disks() {
  numberOfDisks="$(azure vm disk list " $1 " |grep " $1"|wc -l)"
  #substract the system volume
  numberOfDisks="$(( numberOfDisks - 1 ))"
  echo "$numberOfDisks"
}

#$1 vm_name $2 disk size in MB $3 disk number
vm_attach_new_disk() {
  logger " Attaching a new disk #$3 to VM $1 of size ${2}MB"
  azure vm disk attach-new "$1" "$2" -s "$subscriptionID"
}

#Azure uses a different key
get_ssh_key() {
 echo "../secure/keys/myPrivateKey.key"
}

get_ssh_host() {
 echo "${dnsName}.cloudapp.net"
}

#Azure changes ports
get_ssh_port() {
  if [ -z "$vm_ssh_port" ] ; then
    logger "ERROR: $vm_ssh_port not set! for VM $vm_name";
    exit 1
  fi

  echo "$vm_ssh_port"
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

vm_final_bootstratp() {
  : #not necessary for Azure (yet)
}

### cluster functions

cluster_final_boostrap() {
  : #not necessary for Azure (yet)
}


###for executables

#1 $node_name
node_connect() {
  logger "Connecting to subscription $subscriptionID, with details: ${user}@${dnsName}.cloudapp.net -p $vm_ssh_port -i ../secure/keys/myPrivateKey.key"
  ssh -i "../secure/keys/myPrivateKey.key" -o StrictHostKeyChecking=no "$user"@"$dnsName".cloudapp.net -p  "$vm_ssh_port"
}

#1 $node_name
node_delete() {
  logger "Deleting node $1 and its associated attached volumes"
  azure vm delete -b -q "$1"
}

#1 $node_name
node_stop() {
  logger "Stopping vm $1"
  azure vm shutdown "$1"
}