#HDI specific functions

#### start $cloud_provider customizations

#$1 storage account name $2 redundancy type (LRS/ZRS/GRS/RAGRS/PLRS)
vm_create_storage_account() {
    if [ -z "$(azure storage account list "$1" | grep "$1")" ]; then
        logger "Creating storage account $1"
        azure storage account create "$1" -g "$resourceGroup" -s "$subscriptionID" -l "$3" --sku-name "$2" --kind "Storage"
    else
        logger "WARNING: Storage account $1 already exists, skipping.."
    fi
    logger "INFO: retrieving storage account key"
    storageAccountKey="$(azure storage account keys list -g "$resourceGroup" $1 | grep 'key1' | awk '{print $3}')"

    [ ! "$storageAccountKey" ] && logger "WARNING: Empty storage account key"
}

#$1 storage account name $2 container name $3 storage account key
vm_create_storage_container() {
    if [ -z "$(azure storage container list -a "$1" -k "$3" | grep "$2")" ]; then
        logger "Creating container $2 on storage $1 with key $3"
        azure storage container create -a "$1" -k "$3" "$2"
    else
        logger "WARNING: Container $2 already exists on $1, skipping.."
    fi
}

#$1 storage account name $2 resource group
vm_delete_storage_account() {
    azure storage account delete -q -g "$2" "$1"
}

#$1 cluster name
hdi_cluster_check_create() {
    if [ -z "$(azure hdinsight cluster list | grep "$1")" ] ; then
        echo 0
     else
        echo 1
     fi
}

#$1 cluster name $2 resource group
hdi_cluster_check_delete() {
    if [ ! -z "$(azure hdinsight cluster list -g "$2" | grep "$1")" ] ; then
        return 0
     else
        logger "ERROR: cluster name doesn't exists!"
        exit
     fi
}

#$1 cluster name  $2 resourceGroup
get_cluster_status() {
   echo $(azure hdinsight cluster show -g "$2" "$1" | grep State | cut -d: -f3 | sed 's/\ //g')
  # if [ ! -z "$(azure hdinsight cluster show "$1" "$2" | grep Running)" ]; then
   #  echo "Running"
  # else
  #   echo "Deploying"
  # fi
}

#$1 cluster name
wait_hdi_cluster() {
  for tries in {1..900}; do
    currentStatus="$(get_cluster_status "$1" "$resourceGroup" )"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "Running" ] ; then
      logger " Cluster $1 is ready!"
      break
    else
      logger " Cluster $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempt(s)."
    fi
  done
}

#$1 mode to be in
azure_cli_switch_mode() {
 output=$(azure config list | grep mode | grep $1)
 exitCode=$?
 if [ "$exitCode"  = 1 ]; then
     logger "INFO: Switching azure cli to $1"
     azure config mode $1
 else
     logger "DEBUG: Azure cli in mode $1"
 fi
}

#$1 cluster name
create_hdi_cluster() {

 azure_cli_switch_mode "arm"

 if [ -z "$storageAccount" ]; then
    vm_size=$vmSize
    if [[ $vmSize == *"Standard_"* ]]; then
      vm_size="$(echo $vmSize | cut -d_ -f2)"
    fi

    storageAccount="$(echo $vm_size | awk '{print tolower($0)}')`echo $clusterName | cut -d- -f1`"
 fi
 if [ -z "$location" ]; then
    location="$azureLocation"
#    location="South Central US"
 fi

 [ ! "$azureStorageType" ] && die "azureStorageType is not set!"

 vm_create_storage_account "$storageAccount" "$azureStorageType" "$location"
 vm_create_storage_container "$storageAccount" "$storageAccount" "$storageAccountKey"
 logger "Creating Linux HDI cluster $1"

     azure hdinsight cluster create --clusterName "$1" --osType "$vmType"  --clusterType "$hdiType" \
     --version "$hdiVersion" --defaultStorageAccountName "${storageAccount}.blob.core.windows.net" \
     --defaultStorageAccountKey "$storageAccountKey" --defaultStorageContainer "$storageAccount" \
     --workerNodeCount "$numberOfNodes" --headNodeSize "$headnodeSize" --workerNodeSize "$vmSize" \
     --location "$location" --resource-group "$resourceGroup" \
     --userName "ambari" --password "$passwordAloja" \
     --sshUserName "$userAloja" --sshPublicKey "$(get_ssh_public_key)" --sshPassword "$passwordAloja" \
     --subscription "$subscriptionID"

 # wait_hdi_cluster $1
  ssh-keygen -f "~/.ssh/known_hosts" -R $(get_ssh_host)
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
 echo "$CONF_DIR/../../secure/keys/id_rsa"
}

get_ssh_public_key() {
 cat "$CONF_DIR/../../secure/keys/id_rsa.pub"
}

get_ssh_host() {
    echo "${clusterName}-ssh.azurehdinsight.net"
}

#construct the port number from vm_name
get_ssh_port() {
  echo "22"
}

#1 $vm_name
node_connect() {
  logger "INFO: Connecting to azure subscription $subscriptionID"
  if [ "$vmType" != "windows" ] ; then
    vm_connect
  else
    vm_connect_RDP
  fi
}

#$1 cluster name $2 use password
vm_final_bootstrap() {
 logger "INFO: Configuring nodes..."
#vm_set_ssh
 vm_execute "cp /etc/hadoop/conf/slaves slaves; cp slaves machines && echo \"$(get_master_name)\" >> machines"
 install_packages "sshpass dsh pssh git"
 if [ ! -z $2 ]; then
  vm_execute "parallel-scp -h slaves .ssh/{id_rsa,id_rsa.pub} /home/$userAloja/.ssh/"
 else
  vm_execute "while read i; do echo \$i; sshpass -p '$passwordAloja' scp -o StrictHostKeyChecking=no .ssh/{config,id_rsa,id_rsa.pub,myPrivateKey.key,authorized_keys} $userAloja@\$i:/home/$userAloja/.ssh; done</home/$userAloja/slaves"
 fi

 vm_execute "parallel-scp -h slaves ~/machines ~/slaves /home/$userAloja/"
 vm_execute "dsh -M -f machines -Mc -- 'mkdir -p ~/.dsh/group; rm ~/.dsh/group/{a,s}; cp ~/{machines,slaves} ~/.dsh/group/; mv ~/.dsh/group/machines ~/.dsh/group/a; mv ~/.dsh/group/slaves ~/.dsh/group/s;'"

 vm_execute "dsh -M -f machines -Mc -- sudo DEBIAN_FRONTEND=noninteractive apt-get install bwm-ng rsync sshfs sysstat gawk libxml2-utils ntp -y -qqq"
 vm_execute "dsh -f slaves -Mc -- 'mkdir -p share'"

  local fstab_sshfs
  if [ ! "$dont_mount_share_master" ] ; then
    fstab_sshfs="$(get_share_location)"
  else
    fstab_sshfs="$(get_share_location "$userAloja@$(get_master_name):$homePrefixAloja/$userAloja/share/")"
  fi
 vm_execute "dsh -f slaves -cM -- 'echo -e \"$fstab_sshfs\" | sudo tee -a /etc/fstab > /dev/null'"
 vm_execute "dsh -f slaves -cM -- 'sudo mount -a'"

 vm_execute "dsh -M -f machines -Mc -- 'sudo chmod 775 /mnt'"
 vm_execute "dsh -M -f machines -Mc -- 'sudo chown root.$userAloja /mnt'"
 vm_execute "dsh -M -f machines -Mc -- 'mkdir /mnt/aloja'"
}

#$1 cluster name
node_delete() {
  if [ -z "$storageAccount" ]; then
      storageAccount="$(echo $vmSize | awk '{print tolower($0)}')`echo $clusterName | cut -d- -f1`"
  fi

  hdi_cluster_check_delete $1 "$resourceGroup"
  azure hdinsight cluster delete -g "$resourceGroup" "$1"
  ssh-keygen -f "/home/acall/.ssh/known_hosts" -R "$1"-ssh.azurehdinsight.net
  vm_delete_storage_account "$storageAccount" "$resourceGroup"
}

get_master_name() {
  nameCluster="$(echo $clusterName | cut -d- -f1)"
  echo "hn0-$nameCluster"
}

get_node_names() {
  cat /home/$userAloja/machines
}

get_slaves_names() {
  local nodes="$((numberOfNodes - 1))"
  local node_names
  for i in $(seq 0 $nodes) ; do
      node_names="${node_names}\nworkernode${i}"
  done
  echo -e "$node_names"
}

#$1 node_name, expects workernode{id}
get_vm_id() {
  local id="$(echo "$1" | grep -oP "[0-9]+"|head -n +1)" #head is used as grep can return more than one line
  id="$((id + 1))"
  printf %02d "$id"
}
