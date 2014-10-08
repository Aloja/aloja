#OPENSTACK specific functions

#global vars
bootStrapped="false"

#openstack specific globals
declare -A nodeIP
declare -A serverId

#### start $cloud_provider customizations

vm_exists() {
  logger "Checking if VM $1 exists..."

  if [ ! -z "$(nova list |grep " $1 ")" ] ; then
    return 0
  else
    return 1
  fi
}

# $1 vm name
vm_create() {
  logger "Creating VM $1"
  nova boot "$1" --image "$vmImage" --flavor "$vmSize" --key-name "$keyName"
}

#get openstack machine details
#$vm_name required
vm_set_details() {

  if [ -z "${nodeIP[$vm_name]}" ] || [ -z "${serverId[$vm_name]}"  ]  ; then
    #get machine details
    local vm_details="$(nova show --minimal "$vm_name")"
    #set IP
    nodeIP["$vm_name"]="$(echo "$vm_details"|grep ' accessIPv4 '|awk '{print $4}')"
    #set serverId
    serverId["$vm_name"]="$(echo "$vm_details"|grep ' id '|awk '{print $4}')"
  fi

  #if empty, we cannot continue
  if [ -z "${nodeIP[$vm_name]}" ] || [ -z "${serverId[$vm_name]}"  ] ; then
    logger "ERROR: could not get VM $vm_name details. Server returned: $vm_details"
    exit 1
  fi
}

#$1 vm_name
vm_get_status(){
 echo "$(nova show "$1" |grep "OS-EXT-STS:vm_state"|awk '{print $4}')"
}

#$1 vm_name
number_of_attached_disks() {

  vm_set_details

  numberOfDisks="$(nova volume-list |grep ${serverId["$vm_name"]}|wc -l)"
  echo "$numberOfDisks"
}

#$1 vm_name $2 disk size in MB $3 disk number
vm_attach_new_disk() {

  vm_set_details #make sure server details are loaded

  local disk_name="DISK_${vm_name}_$3"
  logger " Creating a new disk #$3 to VM $1 of size ${2}MB with display name $disk_name"
  local disk_create_output="$(nova volume-create --display-name "$disk_name" "$2")"

  local disk_id="$(echo "$disk_create_output"|grep ' id '|awk '{print $4}')"

  logger " Attaching diskId $disk_id to VM $1"
  nova volume-attach "${serverId["$vm_name"]}" "$disk_id"
}

get_ssh_host() {
 vm_set_details

 echo "${nodeIP[$vm_name]}"
}

#Openstack needs to use root first
get_ssh_user() {
  #check if we can change from root user
  if [ "$bootStrapped" == "false" ] ; then
    #"WARNINIG: connecting as root"
    echo "root"
  else
    echo "$user"
  fi
}

vm_initial_bootstrap() {

  bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

#bash -c 'BASH_ENV=/etc/profile exec bash' &&

    vm_execute "
useradd --create-home -s /bin/bash $user &&
adduser $user sudo &&
echo -n '$user:$password' | chpasswd &&
sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers &&
mkdir -p /home/$user/.ssh &&
echo '${insecureKey}' >> /home/$user/.ssh/authorized_keys &&
chown -R $user: /home/$user/.ssh ;
cp /home/$user/.profile /home/$user/.bashrc /root/ ;
"

    test_action="$(vm_execute " [ -d /home/$user/.ssh ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
      #change the user
      bootStrapped="true"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    bootStrapped="true"
    logger "$bootstrap_file already configured"
  fi
}

make_hosts_file_command() {
  hosts_file="$(nova list|tee hosts.txt|tail -n +4|head -n -1|awk '{start=index($0,"private")+8; print substr($0,start, index(substr($0,start), " ")) "\t" $4}'|tr ";" " ")"

  echo "sudo chmod 777 /etc/hosts; echo -e '$hosts_file' >> /etc/hosts; sudo chmod 644 /etc/hosts;"
}

vm_update_hosts_file() {
  logger "Getting list of hostnames for hosts file for VM $vm_name"
  local hosts_file_command="$(make_hosts_file_command)"

  logger "Updating hosts file for VM $vm_name"
  vm_execute "$hosts_file_command"
}

vm_final_bootstrap() {
  logger "Finalizing VM $vm_name bootstrap"

  #currently is ran everytime it is executed
  vm_update_hosts_file

}

### cluster functions

cluster_final_boostrap() {
  logger "Finalizing Cluster $cluster_name bootstrap"
  logger "Getting list of hostnames for hosts file for VM $vm_name"
  local hosts_file_command="$(make_hosts_file_command)"

  logger "Updating hosts file for VM $vm_name"
  cluster_execute "$hosts_file_command"
}


###for executables

node_connect() {

  vm_set_details

  logger "Connecting to Rackspace, with details: ${user}@${nodeIP[$vm_name]}"
  ssh -i "../secure/keys/id_rsa" -o StrictHostKeyChecking=no "$user"@"${nodeIP[$vm_name]}"
}

#1 $node_name
node_delete() {
  vm_set_details

  logger "Getting attached disks"
  attached_volumes="$(nova volume-list|grep "${serverId["$vm_name"]}")"
  logger "$attached_volumes"

  logger "De-Ataching node volumes"
  for volumeID in $(echo $attached_volumes|awk '{print $2}') ; do
    nova volume-detach "${serverId["$vm_name"]}" "$volumeID"
  done

  logger "Deleting node $1"
  nova delete "$vm_name"

  logger "Deleting node volumes"
  for volumeID in $(echo $attached_volumes|awk '{print $2}') ; do
    nova volume-delete "$volumeID"
  done
}

#1 $node_name
node_stop() {
  vm_set_details

  logger "Stopping vm $1"

  nova stop "${serverId["$vm_name"]}"
}