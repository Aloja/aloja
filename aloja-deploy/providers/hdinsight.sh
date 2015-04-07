#HDI specific functions

#### start $cloud_provider customizations

#$1 storage account name $2 redundancy type (LRS/ZRS/GRS/RAGRS/PLRS)
vm_create_storage_account() {
	if [ -z "$(azure storage account list "$1" | grep "$1")" ]; then
		logger "Creating storage account $1"
		azure storage account create "$1" -s "$subscriptionID" -l "South Central US" --type "$2"	
	else
		logger "WARNING: Storage account $1 already exists, skipping.."
	fi
	storageAccountKey=`azure storage account keys list $1 | grep Primary | cut -d" " -f6`
}

#$1 storage account name $2 container name $3 storage account key
vm_create_storage_container() {
	if [ -z "$(azure storage container list -a "$1" -k "$3" | grep "$2")" ]; then
		logger "Creating container $2 on storage $1"
		azure storage container create -a "$1" -k "$3" "$2"
	else
		logger "WARNING: Container $2 already exists on $1, skipping.."
	fi
}

#$1 cluster name
hdi_cluster_check_create() {
	if [ ! -z "$(azure hdinsight cluster list | grep "$1")" ] ; then
    	return 0
	 else
    	logger "ERROR: cluster name already exists!"
		exit
	 fi
}

#$1 cluster name
hdi_cluster_check_delete() {
	if [ -z "$(azure hdinsight cluster list | grep "$1")" ] ; then
    	return 0
	 else
    	logger "ERROR: cluster name doesn't exists!"
		exit
	 fi
}

#$1 cluster name
create_hdi_cluster() {
 vm_create_storage_account "$storageAccount" "GRS"
echo "$storageAccountKey"
exit
 vm_create_storage_container "$storageAccount" "$storageAccount" "$storageAccountKey"
  #check if the port was specified, for Windows this will be the RDP port
  if [ "$vmType" != "windows" ] ; then

    logger "Creating Linux HDI cluster $1"
    azure hdinsight cluster create "$1" "linux" "$storageAccount" "$storageAccountKey" "$storageAccount" "$numberOfNodes" "$vmSize" "$vmSize" "South Central US" "$userAloja" "$passwordAloja" "$userAloja" "$passwordAloja"
        -s "$subscriptionID" \
        --ssh-cert "$sshCert" 
  else
    logger "Creating Windows HDI cluster $1"
    azure hdinsight cluster create "$1" "windows" "$storageAccount" "$storageAccountKey" "$storageAccount" "$numberOfNodes" "$vmSize" "$vmSize" "South Central US" "$userAloja" "$passwordAloja" "$userAloja" "$passwordAloja"
        -s "$subscriptionID" \
	    --ssh-cert "$sshCert"
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

#$1 cluster name
vm_final_bootstrap() {

  logger "Checking if setting a static host file for cluster"
}

#$1 cluster name
node_delete() {
	hdi_cluster_check_delete $1
	azure hdinsight cluster delete "$1" "South Central US" "$vmType"
}