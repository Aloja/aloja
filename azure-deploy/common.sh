#common functions, non-executable, must be sourced

logger() {
  dateTime="$(date +%Y%m%d_%H%M%S)"
  echo "$dateTime: $1"
}

vm_exists() {
  logger "Checking if VM $1 exists..."

  if [ ! -z "$(azure vm list -s "$subscriptionID"|grep "$1")" ] ; then
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

#$1 vm_name $2 ssh_port
vm_check_create() {
  #create VM
  if ! vm_exists "$1"  ; then
    vm_create "$1" "$2"
  else
    logger "VM $1 already exists. Skipping creation..."
  fi

}
#$1 vm_name
wait_vm_ready() {
  logger "Checking status of VM $1"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do
    currentStatus="$(azure vm show "$1" -s "$subscriptionID"|grep "InstanceStatus"|awk '{print substr($3,2,(length($3)-2));}')"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "ReadyRole" ] ; then
      logger " VM $1 is ready!"
      break
    else
      logger " VM $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempts."
    fi

    sleep 1
  done
}

#$1 vm_name
number_of_attached_disks() {
  #total number
  logger " getting number of attached disks to VM $1"
  numberOfDisks="$(azure vm disk list $1 |grep $1|wc -l)"
  #substract the system volume
  numberOfDisks="$(( numberOfDisks - 1 ))"
  logger " $numberOfDisks attached disks to VM $1"
}

#$1 vm_name $2 disk size in MB
vm_attach_new_disk() {
  logger " Attaching a new disk to VM $1 of size ${2}MB"
  azure vm disk attach-new "$1" "$2" -s "$subscriptionID"
}

#$1 vm_name
vm_check_attach_disks() {
  #attach required volumes
  if [ ! -z $attachedVolumes ] ; then
    numberOfDisks=""
    number_of_attached_disks "$1"

    if [ "$attachedVolumes" -gt "$numberOfDisks" ] ; then
      missingDisks="$(( attachedVolumes - numberOfDisks ))"
      logger " need to attach $missingDisks disk(s) to VM $1"
      for ((disk=0; disk<missingDisks; disk++ )) ; do
        vm_attach_new_disk "$1" "$diskSize"
      done
    else
      logger " no need to attach new disks to VM $1"
    fi
  fi
}

#$1 commands to execute $2 set in parallel (&)
#$vm_ssh_port must be set before
vm_execute() {
  #logger "Executing in VM $vm_name command(s): $1"

  #echo to print special chars;
  if [ -z "$2" ] ; then
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
  else
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port" &
  fi
}

#$1 command to execute in master
vm_execute_master() {
  #save current ssh_port
  vm_ssh_port_save="$vm_ssh_port"

  master_ssh_port=""
  get_master_ssh_port
  vm_ssh_port="$master_ssh_port"

  vm_execute "$1"

  #restore port
  vm_ssh_post="$vm_ssh_port_save"
}

vm_set_master_crontab() {

  if check_bootstraped "vm_set_master_crontab6" "set"; then
    logger "Setting ALOJA crontab to master"

    crontab="# m h  dom mon dow   command
* * * * * export USER=$user && bash /home/$user/share/shell/exeq.sh $clusterName
#backup data
0 * * * * cp -ru share/jobs_$clusterName . >> /home/$user/cron.log 2>&1
30 * * * * cp -ru share/jobs_$clusterName /scratch/local/share/safe_store/ >> /home/$user/cron.log 2>&1"

    vm_execute_master "echo '$crontab' |crontab"

    #start the queue so dirs are created
    vm_execute_master "export USER=$user && bash /home/$user/share/shell/exeq.sh $clusterName"

  else
    logger "Crontab already installed in master"
  fi
}

vm_set_master_forer() {

  if check_bootstraped "vm_set_master_forer" "set"; then
    logger "Generating jobs (forer)"

    vm_execute_master "bash /home/$user/share/shell/forer_az.sh $clusterName"

  else
    logger "Jobs generated and queued"
  fi
}


vm_set_ssh() {

  if check_bootstraped "vm_set_ssh" "set"; then
    logger "Setting SSH keys to VM $vm_name "

    vm_execute "mkdir -p ~/.ssh/;
                echo -e \"Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet\" > ~/.ssh/config;
                echo '${insecureKey}' >> ~/.ssh/authorized_keys;" "parallel"

    scp -i "../secure/keys/myPrivateKey.key" -P "$vm_ssh_port"  \
           ../secure/keys/{id_rsa,id_rsa.pub,myPrivateKey.key} \
           "$user@$dnsName.cloudapp.net:.ssh/"

    vm_execute "chmod -R 0600 ~/.ssh/*;"
  else
    logger "SSH already initialized"
  fi
}

vm_format_disks() {
  if check_bootstraped "vm_format_disks" "set"; then
    logger "Formating disks for VM $vm_name "

    vm_execute ";"
  else
    logger "Disks initialized"
  fi
}

vm_install_base_packages() {
  if check_bootstraped "vm_install_packages" "set"; then
    logger "Installing packages for for VM $vm_name "

    vm_execute "sudo sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list;
                sudo apt-get update && sudo apt-get install -y -f dsh sshfs sysstat;"
  else
    logger "Packages already initialized"
  fi
}

vm_set_dsh() {
  if check_bootstraped "vm_set_dsh2" ""; then
    logger "Setting up DSH for VM $vm_name "

    node_names=''
    get_node_names

    vm_execute "mkdir -p ~/.dsh/group; echo -e \"$node_names\" > ~/.dsh/group/m;" "parallel"
  else
    logger "DSH already configured"
  fi
}

#1 command to execute in master (as a gateway to DSH)
cluster_execute() {
  vm_execute_master "dsh -g m -M \"$1\""
}

cluster_initialize_disks() {
  #TODO make dyanmic number of volumes
  if [ "$attachedVolumes" != "3" ] ; then
    logger "ERROR, function only supports 3 volumes"
    exit 1;
  fi

  bootstrap_file="~/bootstrap_cluster_initialize_disks2"

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already initialized';
  else
    echo 'Initializing disks';
    touch $bootstrap_file;

    sudo parted -s /dev/sdc -- mklabel gpt mkpart primary 0% 100%;
    sudo parted -s /dev/sdd -- mklabel gpt mkpart primary 0% 100%;
    sudo parted -s /dev/sde -- mklabel gpt mkpart primary 0% 100%;
    sudo mkfs.ext4 -F /dev/sdc1;
    sudo mkfs.ext4 -F /dev/sdd1;
    sudo mkfs.ext4 -F /dev/sde1;

  fi"

  cluster_mount_disks

}

cluster_mount_disks() {
  #TODO make dyanmic number of volumes
  if [ "$attachedVolumes" != "3" ] ; then
    logger "ERROR, function only supports 3 volumes"
    exit 1;
  fi

  bootstrap_file="~/bootstrap_cluster_mount_disk19"

#UUID=8ba50808-9dc7-4d4d-b87a-52c2340ec372	/	 ext4	defaults,discard	0 0
#/dev/sdb1	/mnt	auto	defaults,nobootwait,comment=cloudconfig	0	2

  mounts="
/dev/sdc1       /scratch/attached/1  auto    defaults,nobootwait 0       2
/dev/sdd1       /scratch/attached/2  auto    defaults,nobootwait 0       2
/dev/sde1       /scratch/attached/3  auto    defaults,nobootwait 0       2
$user@al-1001:/home/$user/share/ /home/$user/share fuse.sshfs _netdev,users,IdentityFile=/home/$user/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0
npoggi@minerva.bsc.es:/home/npoggi/tmp/ /home/$user/minerva fuse.sshfs noauto,_netdev,users,IdentityFile=/home/$user/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"


  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already mounted';
  else
    echo 'Mounting disks';
    touch $bootstrap_file;

    mkdir -p ~/{share,minerva};
    sudo mkdir -p /scratch/local/share/{jobs,safe_store};
    sudo mkdir -p /scratch/attached/{1,2,3};
    sudo chown -R $user: /scratch;

    sudo chmod 0777 /etc/fstab;

    sudo echo '$mounts' >> /etc/fstab;

    sudo chmod 0644 /etc/fstab;
    sudo mount -a;

  fi"
}


get_node_names() {
  node_names=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    node_names="${node_names}\n${clusterName}-${vm_id}"
  done
}

get_master_name() {
  master_name=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_name="${clusterName}-${vm_id}"
    break #just return one
  done
}

get_master_ssh_port() {
  master_ssh_port=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_ssh_port="2${clusterID}${vm_id}"
    break #just return one
  done
}

#$1 filename $2 set lock
check_bootstraped() {
  fileExists="$(vm_execute "[[ -f ~/bootstrap_$1 ]] && echo 'ok'")"

  #set lock
  if [ ! -z "$2" ] ; then
    vm_execute "touch ~/bootstrap_$1;"
  fi

  if [ ! -z "$fileExists" ] && [ "$fileExists" != "ok" ] ; then
    logger " Avoiding subsequent welcome banners"
    vm_execute "touch ~/.hushlogin; #avoid subsequent banners"
    fileExists="$(vm_execute "[[ -f ~/bootstrap_$1 ]] && echo 'ok'")"
  fi

  if [ "$fileExists" == "ok" ] ; then
    return 1
  elif [ ! -z "$fileExists" ] ; then
    logger "Error checking bootstrap locks, LOCKING anyhow. Check manually. FileExists=$fileExists"
    return 0
  else
    return 0
  fi
}
