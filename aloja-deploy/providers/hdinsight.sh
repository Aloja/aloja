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
	if [ -z "$(azure hdinsight cluster list | grep "$1")" ] ; then
    	return 0
	 else
    	logger "ERROR: cluster name already exists!"
		exit
	 fi
}

#$1 cluster name
hdi_cluster_check_delete() {
	if [ ! -z "$(azure hdinsight cluster list | grep "$1")" ] ; then
    	return 0
	 else
    	logger "ERROR: cluster name doesn't exists!"
		exit
	 fi
}

#$1 cluster name
create_hdi_cluster() {
 vm_create_storage_account "$storageAccount" "GRS"
 vm_create_storage_container "$storageAccount" "$storageAccount" "$storageAccountKey"
 logger "Creating Linux HDI cluster $1"
 azure hdinsight cluster create --clusterName "$1" --osType "$vmType" --storageAccountName "$storageAccount" \
	--storageAccountKey "$storageAccountKey" --storageContainer "$storageAccount" --dataNodeCount "$numberOfNodes" \
	--location "South Central US" --userName "$userAloja" --password "$passwordAloja" --sshUserName "$userAloja" \
	--sshPassword "$passwordAloja" -s "$subscriptionID"
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
	vm_name="`echo ${clusterName} | cut -d- -f1`"
    echo "${vm_name}-ssh.azurehdinsight.net"
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
 logger "Configuring nodes..."
 vm_set_ssh
 vm_execute "cp /etc/hadoop/conf/slaves slaves; cp slaves machines && echo headnode0 >> machines"
 vm_execute "sudo DEBIAN_FRONTEND=noninteractive apt-get install dsh pssh git -y -qqq"
 vm_provision 
 vm_execute "dsh -M -f machines -Mc -- sudo DEBIAN_FRONTEND=noninteractive apt-get install bwm-ng rsync sshfs sysstat gawk libxml2-utils ntp -y -qqq"
 vm_execute "parallel-scp -h slaves .ssh/{config,id_rsa,id_rsa.pub,myPrivateKey.key} /home/pristine/.ssh/"
 vm_execute "mkdir -p share; dsh -f slaves -Mc -- 'mkdir -p share'"
 vm_execute "dsh -f slaves -cM -- \"sshfs 'pristine@$(hostname -i):/home/pristine/share' '/home/pristine/share'\""
 vm_execute "cd share; git clone https://github.com/Aloja/aloja.git ."
}

#$1 cluster name
node_delete() {
	vm_name="`echo $1 | cut -d- -f1`"
	hdi_cluster_check_delete $vm_name
	azure hdinsight cluster delete "$vm_name" "South Central US" "$vmType"
}