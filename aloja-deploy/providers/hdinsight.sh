#HDI specific functions

#### start $cloud_provider customizations

#$1 storage account name $2 redundancy type (LRS/ZRS/GRS/RAGRS/PLRS)
vm_create_storage_account() {
    if [ -z "$(azure storage account list "$1" | grep "$1")" ]; then
        logger "Creating storage account $1"
        azure storage account create "$1" -s "$subscriptionID" -l "$3" --type "$2"  
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
        echo 0
     else
        echo 1
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

#$1 cluster name  $2 vm OS
get_cluster_status() {
   echo $(azure hdinsight cluster show "$1" "$2" | grep State | cut -d: -f3 | sed 's/\ //g')
  # if [ ! -z "$(azure hdinsight cluster show "$1" "$2" | grep Running)" ]; then
   #  echo "Running"
  # else
  #   echo "Deploying"
  # fi
}

#$1 cluster name
wait_hdi_cluster() {
  for tries in {1..900}; do
    currentStatus="$(get_cluster_status "$1" "$vmType" )"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "Running" ] ; then
      logger " Cluster $1 is ready!"
      break
    else
      logger " Cluster $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempt(s)."
    fi
  done
}

#$1 cluster name
create_hdi_cluster() {
 if [ -z "$storageAccount" ]; then
    storageAccount="$(echo $vmSize | awk '{print tolower($0)}')`echo $clusterName | cut -d- -f1`"
 fi
 if [ -z "$location" ]; then
    location="South Central US"
 fi

 vm_create_storage_account "$storageAccount" "LRS" "$location"
 vm_create_storage_container "$storageAccount" "$storageAccount" "$storageAccountKey"
 logger "Creating Linux HDI cluster $1"
     azure hdinsight cluster create --clusterName "$1" --osType "$vmType" --storageAccountName "${storageAccount}.blob.core.windows.net" \
    --storageAccountKey "$storageAccountKey" --storageContainer "$storageAccount" --dataNodeCount "$numberOfNodes" \
    --location "$location" --userName "$userAloja" --password "$passwordAloja" --sshUserName "$userAloja" \
    --sshPassword "$passwordAloja" -s "$subscriptionID"

  wait_hdi_cluster $1
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

get_ssh_host() {
    echo "${clusterName}-ssh.azurehdinsight.net"
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

#$1 cluster name $2 use password
vm_final_bootstrap() {
 logger "Configuring nodes..."
#vm_set_ssh
 vm_execute "cp /etc/hadoop/conf/slaves slaves; cp slaves machines && echo \"$(get_master_name)\" >> machines"
 install_packages "sshpass dsh pssh git"
 if [ ! -z $2 ]; then
  vm_execute "parallel-scp -h slaves .ssh/{id_rsa,id_rsa.pub} /home/pristine/.ssh/"
 else
  vm_execute "while read i; do echo \$i; sshpass -p '$passwordAloja' scp -o StrictHostKeyChecking=no .ssh/{config,id_rsa,id_rsa.pub,myPrivateKey.key,authorized_keys} $userAloja@\$i:/home/pristine/.ssh; done</home/pristine/slaves"
 fi
 vm_execute "dsh -M -f machines -Mc -- sudo DEBIAN_FRONTEND=noninteractive apt-get install bwm-ng rsync sshfs sysstat gawk libxml2-utils ntp -y -qqq"
 vm_execute "dsh -f slaves -Mc -- 'mkdir -p share'"
 vm_execute "dsh -f slaves -cM -- echo \"'\`cat /etc/fstab | grep aloja-us.cloudapp\`' | sudo tee -a /etc/fstab > /dev/null\""
 vm_execute "dsh -f slaves -cM -- sudo mount -a"
 vm_execute "dsh -M -f machines -Mc -- 'sudo chmod 775 /mnt'"
 vm_execute "dsh -M -f machines -Mc -- 'sudo chown root.pristine /mnt'"
 vm_execute "dsh -M -f machines -Mc -- 'mkdir /mnt/aloja'"
}

#$1 cluster name
node_delete() {
    hdi_cluster_check_delete $1
    azure hdinsight cluster delete "$1" "South Central US" "$vmType"
    ssh-keygen -f "/home/acall/.ssh/known_hosts" -R "$1"-ssh.azurehdinsight.net
}

get_master_name() {
    nameCluster="$(echo $clusterName | cut -d- -f1)"
    echo "hn0-$nameCluster"
}

get_node_names() {
    cat /home/pristine/machines 
}

get_slaves_names() {
    local nodes=`expr $numberOfNodes - 1`
    local node_names
    for i in `seq 0 $nodes` ; do
        node_names="${node_names}\nworkernode${i}"
    done
    echo -e "$node_names"
}

#$1 node_name, expects workernode{id}
get_vm_id() {
    local id=$(echo "$1" | grep -oP "[0-9]+")
    id=`expr ${id} + 1`
    printf %02d "$id"
}
