#OPENSTACK specific functions

#openstack specific globals

#associative arrays (one key per node)
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

# $1 vm name
vm_start() {
  logger "Starting VM $1"
  nova start "$1"
}

# $1 vm name
vm_reboot() {
  logger "Rebooting VM $1"
  nova reboot "$1"
}

#get openstack machine details
#$vm_name required
vm_set_details() {

  if [ -z "${nodeIP[$vm_name]}" ] || [ -z "${serverId[$vm_name]}"  ]  ; then
    #get machine details
    local cacheFileName="rackspace_vm_details_${vm_name}"
    local vm_details="$(cache_get "$cacheFileName" "60")"

    if [ ! "$vm_details" ] ; then
      local vm_details="$(nova show --minimal "$vm_name")"
      cache_put "$cacheFileName" "$vm_details"
    fi

    #set IP
    nodeIP["$vm_name"]="$(echo -e "$vm_details"|grep ' accessIPv4 '|awk '{print $4}')"
    #set serverId
    serverId["$vm_name"]="$(echo -e "$vm_details"|grep ' id '|awk '{print $4}')"

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

get_OK_status() {
  echo "active"
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

get_ssh_port() {
  echo "22" #default port when empty or not overwriten
}

#Openstack needs to use root first
get_ssh_user() {

  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
    #"WARNINIG: connecting as root"
    echo "root"
  else
    echo "$userAloja"
  fi
}

vm_initial_bootstrap() {

  local bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

#bash -c 'BASH_ENV=/etc/profile exec bash' &&

    vm_execute "
useradd --create-home -s /bin/bash $userAloja &&
adduser $userAloja sudo &&
echo -n '$userAloja:$passwordAloja' | chpasswd &&
sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers &&
mkdir -p $homePrefixAloja/$userAloja/.ssh ;

echo '${insecureKey}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys &&
chown -R $userAloja: $homePrefixAloja/$userAloja/.ssh ;
cp $homePrefixAloja/$userAloja/.profile $homePrefixAloja/$userAloja/.bashrc /root/ ;

adduser $userAloja adm;
ufw disable;
"

#chmod 777 /etc/security/limits.conf;
#echo -e '* soft nproc 450756
#* hard nproc 450756
#* soft nofile 65535
#* hard nofile 65535' >> /etc/security/limits.conf;
#chmod 644 /etc/security/limits.conf;
#chmod 777 /etc/pam.d/common-session;
#echo 'session required  pam_limits.so' >> /etc/pam.d/common-session;
#chmod 644 /etc/pam.d/common-session;

    test_action="$(vm_execute " [ -d $homePrefixAloja/$userAloja/.ssh ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi
  else
    logger "$bootstrap_file already configured"
  fi

}

#make_hosts_file_command() {
#  local hosts_file="$(nova list|tee hosts.txt|tail -n +4|head -n -1|awk '{start=index($0,"private")+8; print substr($0,start, index(substr($0,start), " ")) "\t" $4}'|tr ";" " ")"
#
#  #here we are missing the ip6 address
#  local default_header="# The following lines are desirable for IPv6 capable hosts
##::1     ip6-localhost ip6-loopback
##fe00::0 ip6-localnet
##ff00::0 ip6-mcastprefix
##ff02::1 ip6-allnodes
##ff02::2 ip6-allrouters
##127.0.0.1 localhost
#"
#
#  local hosts_file="${default_header}
#${hosts_file}"
#
#  echo "sudo chmod 777 /etc/hosts;
#echo -e '$hosts_file' |grep -v \$(hostname) > /etc/hosts;
#sudo chmod 644 /etc/hosts;
#
#[ \"\$\(cat /etc/hosts\)\" == \"$hosts_file\" ] && echo ' Hosts succesfully updated' || echo ' Error updating hosts file';
#"
#
#}

make_hosts_file() {
  local cacheFileName="${cloud_provider}_hosts"

  #first try the cache
  local hosts_file="$(cache_get "$cacheFileName" "60")"

  if [ ! "$hosts_file" ] ; then
    local hosts_file="$(nova list|tee hosts.txt|tail -n +4|head -n -1|awk '{start=index($0,"private")+8; print substr($0,start, index(substr($0,start), " ")) "\t" $4}'|tr ";" " ")"
    cache_put "$cacheFileName" "$hosts_file"
  fi

  echo -e "$hosts_file"
}

vm_update_hosts_file() {
  logger "Getting list of hostnames for hosts file for VM $vm_name"
  #local hosts_file_command="$(make_hosts_file_command)"
  local hosts_file="$(make_hosts_file)"

  #remove the same machine
  #local hosts_file="$(echo -e "$hosts_file" |grep -v "$vm_name")"

  logger "Updating hosts file for VM $vm_name"
  #logger "DEBUG: $hosts_file $hosts_file_command"

  #vm_execute "$hosts_file_command"
  vm_update_host_template "/etc/hosts" "$hosts_file" "secured_file"

#  vm_update_host_template "/etc/hosts" "$hosts_file
#162.209.77.102 	aloja-fs
#" "secured_file"


}

#$1 filename on remote machine $2 template part content $3 change permissions
vm_update_host_template() {

  #logger "DEBUG: TEMPLATE getting $1 contents"
  local fileCurrentContent="$(vm_get_file_contents "$1")"

  #remove the same machine
  local fileCurrentContent="$(echo -e "$fileCurrentContent" |grep -v "$vm_name")"

  #logger "DEBUG: TEMPLATE $1 GOT contents"
  local fileNewContent="$(template_update_stream "$fileCurrentContent" "$2")"
  #logger "DEBUG: TEMPLATE GOT NEW contents"
  vm_put_file_contents "$1" "$fileNewContent" "$3"
  #logger "DEBUG: TEMPLATE UPDATED $1 with template"
}

vm_final_bootstrap() {
  logger "Finalizing VM $vm_name bootstrap"

  #currently is ran everytime it is executed
  vm_update_hosts_file
}

### cluster functions

#cluster_final_boostrap() {
#  logger "Finalizing Cluster $cluster_name bootstrap"
##  logger "Getting list of hostnames for hosts file for the cluster"
##  local hosts_file_command="$(make_hosts_file_command)"
##
##  logger "Updating hosts file for cluster"
##  logger "DEBUG: $hosts_file_command"
##  cluster_execute "$hosts_file_command"
#}


###for executables

node_connect() {

  vm_set_details

  logger "Connecting to Rackspace"
  vm_connect
}

#1 $vm_name
node_delete() {
  vm_set_details

  if [ "$type" == "cluster" ] ; then
    logger "Paralellizing node deletions"
    node_delete_helper &
  else
    node_delete_helper
  fi
}

#to alow parallel deletion above
node_delete_helper() {
  logger "Getting attached disks"
  local attached_volumes="$(nova volume-list|grep "${serverId["$vm_name"]}")"
  logger "$attached_volumes"

  logger "De-Ataching node volumes"
  for volumeID in $(echo $attached_volumes|awk '{print $2}') ; do
    nova volume-detach "${serverId["$vm_name"]}" "$volumeID"
  done

  sleep 60 #TODO improve

  logger "Deleting node volumes"
  for volumeID in $(echo $attached_volumes|awk '{print $2}') ; do
    nova volume-delete "$volumeID"
  done

  logger "Deleting node $1"
  nova delete "$vm_name"
  sleep 120 #TODO improve

  logger "Deleting node volumes"
  for volumeID in $(echo $attached_volumes|awk '{print $2}') ; do
    nova volume-delete "$volumeID"
  done
}


#1 $vm_name
node_stop() {
  vm_set_details

  logger "Stopping vm $1"
  nova stop "${serverId["$vm_name"]}"
}

#1 $vm_name
node_start() {
  vm_set_details

  logger "Starting VM $1"
  nova start "$1"
  logger "Starting (rebooting --hard) VM $1"
  sleep 1 #just in case the previous command takes a second to be effective
  nova reboot --hard "$1"
}