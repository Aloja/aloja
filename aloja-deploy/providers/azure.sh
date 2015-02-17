#AZURE specific functions

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

  #check if the port was specified, for Windows this will be the RDP port
  if [ ! -z "$2" ] ; then
    ssh_port="$2"
  else
    ssh_port=$(( ( RANDOM % 65535 )  + 1024 ))
  fi

  if [ "$vmType" != "windows" ] ; then

    logger "Creating Linux VM $1 with SSH port $ssh_port..."

    #if a virtual network is specified
    if [ "$virtualNetworkName" ] ; then
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
            "$userAloja" "$passwordAloja"
    #no virtual network preference
    else
      azure vm create \
            -s "$subscriptionID" \
            --connect "$dnsName" `#Deployment name` \
            --vm-name "$1" \
            --vm-size "$vmSize" \
            --location "$azureLocation" \
            --ssh "$ssh_port" \
            --ssh-cert "$sshCert" \
            "$vmImage" \
            "$userAloja" "$passwordAloja"
    fi
  else
    logger "Creating Windows VM $1 with RDP port $ssh_port..."

    azure vm create \
          -s "$subscriptionID" \
          --connect "$dnsName" `#Deployment name` \
          --vm-name "$1" \
          --vm-size "$vmSize" \
          `#--location 'West Europe'` \
          --affinity-group "$affinityGroup" \
          --virtual-network-name "$virtualNetworkName" \
          --subnet-names "$subnetNames" \
          --rdp "$ssh_port" \
          `#-v` \
          `#'test-11'` `#DNS name` \
          "$vmImage" \
          "$userAloja" "$passwordAloja"
  fi

#--location 'West Europe' \

}

# $1 vm name
vm_start() {
  logger "Starting VM $1"
  azure vm start "$1"
}

# $1 vm name
vm_reboot() {
  logger "Rebooting VM $1"
  azure vm restart "$1"
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
  if [ -z "$numberOfDisks" ] ; then
    numberOfDisks="$(( numberOfDisks - 1 ))"
  fi
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

#construct the port number from vm_name
get_ssh_port() {
  echo "$(get_vm_ssh_port)"
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

#interactive SSH
vm_connect_RDP() {
  logger "Connecting to VM $vm_name, with details: RDP rdesktop -u $(get_ssh_user) -p xxx $(get_ssh_host):$(get_ssh_port)"
  rdesktop -u "$(get_ssh_user)" -p "$passwordAloja" "$(get_ssh_host):$(get_ssh_port)"
}


###for executables

#1 $vm_name
node_connect() {
  logger "Connecting to azure subscription $subscriptionID"
  if [ "$vmType" != "windows" ] ; then
    vm_connect
  else
    vm_connect_RDP
  fi
}

#1 $vm_name
node_delete() {
  logger "Deleting node $1 and its associated attached volumes"
  azure vm delete -b -q "$1"
}

#1 $vm_name
node_stop() {
  logger "Stopping vm $1"
  azure vm shutdown "$1"
}

#1 $vm_name
node_start() {
  logger "Starting VM $1"
  azure vm start "$1"
}