#AZURE specific functions

#### start $cloud_provider customizations

# $1 vm name $2 ssh port
vm_create() {

  #check if the port was specified, for Windows this will be the RDP port
  if [ "$vmType" != "windows" ] ; then

    logger "Creating Linux VM $1 with SSH port $ssh_port..."
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
}

#$1 vm_name
vm_get_status(){
 echo "$(azure vm show "$1" -s "$subscriptionID"|grep "InstanceStatus"|awk '{print substr($3,2,(length($3)-2));}')"
}

get_OK_status() {
  echo "ReadyRole"
}

#Azure uses a different key
get_ssh_key() {
 echo "../secure/keys/id_rsa"
}

get_ssh_host() {
    echo "${vmName}-ssh.azurehdinsight.net"
}

#construct the port number from vm_name
get_ssh_port() {
  echo "22"
}

#1 $vm_name
node_connect() {
  logger "Connecting to azure subscription $subscriptionID"
  if [ "$vmType" != "windows" ] ; then
    vm_connect
  else
    vm_connect_RDP
  fi
}

vm_final_bootstrap() {

  logger "Checking if setting a static host file for cluster"
  vm_set_statics_hosts

}

vm_set_statics_hosts() {

  if [ "$clusterName" == "al-26" ] || [ "$clusterName" == "al-29" ] ; then
    logger "WARN: Setting statics hosts file for cluster"
    vm_update_template "/etc/hosts" "$(get_static_hostnames)" "secured_file"
  else
    logger "INFO: no need to set static host file for cluster"
  fi
}
