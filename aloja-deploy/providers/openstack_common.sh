#OPENSTACK specific functions

#global vars
bootStraped="false"

#openstack specific globals
nodeIP["$vm_name"]=""
serverId["$vm_name"]=""

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
  if [ -z "${nodeIP[$vm_name]}" ] || [ -z "${serverId[$vm_name]}"  ] ; then
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

#$1 commands to execute $2 set in parallel (&)
#$vm_ssh_port must be set before
vm_execute() {

  vm_set_details

  #check if we can change from root user
  if [ "$bootStraped" == "false" ] ; then
    #"WARNINIG: connecting as root"
    ssh_user="root"
  else
    ssh_user="$user"
  fi

  chmod 0600 "../secure/keys/id_rsa"

  #echo to print special chars;
  if [ -z "$2" ] ; then
    echo "$1" |ssh -i "../secure/keys/id_rsa" -q -o connectTimeout=5 "$ssh_user"@"${nodeIP[$vm_name]}"
  else
    echo "$1" |ssh -i "../secure/keys/id_rsa" -q -o connectTimeout=5 "$ssh_user"@"${nodeIP[$vm_name]}" &
  fi

  #chmod 0644 "../secure/keys/id_rsa"
}

#$1 source files $2 destination $3 extra options
vm_local_scp() {
  logger "SCPing files"

  vm_set_details

  #check if we can change from root user
  if [ "$bootStraped" == "false" ] ; then
    #"WARNINIG: connecting as root"
    ssh_user="root"
  else
    ssh_user="$user"
  fi

  chmod 0600 "../secure/keys/id_rsa"

  #eval is for parameter expansion
  scp -i "../secure/keys/id_rsa" $(eval echo "$3") $(eval echo "$1") "$ssh_user"@"${nodeIP[$vm_name]}:$2"

  #chmod 0644 "../secure/keys/id_rsa"
}

vm_initial_bootstrap() {

  bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

    vm_execute "
echo '[ -z \"$PS1\" ] && return' >> /root/.bashrc &&
useradd --create-home -s /bin/bash $user &&
adduser $user sudo &&
echo -n '$user:$password' | chpasswd &&
sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers &&
mkdir -p /home/$user/.ssh &&
echo '${insecureKey}' >> /home/$user/.ssh/authorized_keys &&
chown -R $user: /home/$user/.ssh;
"

    test_action="$(vm_execute " [ -d /home/$user/.ssh ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
      #change the user
      bootStraped="true"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    bootStraped="true"
    logger "$bootstrap_file already configured"
  fi
}

###for executables

#1 $node_name
node_connect() {

  vm_set_details

  echo "Connecting to Rackspace, with details: ${user}@${nodeIP[$vm_name]}"
  ssh -i "../secure/keys/id_rsa" "$user"@"${nodeIP[$vm_name]}"
}

#1 $node_name
node_delete() {
  logger "About to delete node $1 and its associated attached volumes. Continue?"
  pause
  nova delete "$vm_name"

  logger "listing server volumes"
  nova volume-list|grep " DISK_$vm_name"

  logger "Remember to manually delete non-used volumes, functionallity not implemented yet"
}