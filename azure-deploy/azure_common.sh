#common functions, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

#check if azure command is installed
#if ! azure --version 2>&1 > /dev/null ; then
#  echo "azure command not instaled. Run: sudo npm install azure-cli"
#  exit 1
#fi

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [conf_file]"; exit 1;}

if [ -z $2 ]; then
	confFile="../secure/azure_settings.conf"
else
	confFile="../secure/$2"
	if [ ! -e "$confFile" ]; then
		echo "ERROR: Conf file $confFile doesn't exists!"
		exit
	fi
fi

#load non versioned conf first (order is important for overrides)
source "$confFile"

clusterConfigFile="${type}_${1}.conf"

source "../shell/common/cluster_functions.sh"


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

    #sleep 1
  done
}

#"$vm_name" "$vm_ssh_port" must be set before
#1 number of tries
wait_vm_ssh_ready() {
  logger "Checking SSH status of VM $vm_name"
  waitStartTime="$(date +%s)"
  for tries in {1..150}; do

    test_action="$(vm_execute " [ \"\$\(ls\)\" ] && echo '$testKey'")"
    #in case we get a welcome banner we need to grep
    test_action="$(echo -e "$test_action"|grep "$testKey")"

    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ ! -z "$test_action" ] ; then
      logger " VM $vm_name is ready!"
      return 0
      break #just in case
    else
      logger " VM $vm_name is down. Waiting for: $waitElapsedTime s. $tries attempts. Output: $test_action"
    fi

    #stop if max number of tries has been specified
    [ ! -z "$1" ] && [[ "$tries" -ge "$1" ]] && break

    sleep 1
  done

  return 1
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

chmod 0600 "../secure/keys/myPrivateKey.key"

  #echo to print special chars;
  if [ -z "$2" ] ; then
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q -o connectTimeout=5 "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
  else
    echo "$1" |ssh -i "../secure/keys/myPrivateKey.key" -q -o connectTimeout=5 "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port" &
  fi

#chmod 0644 "../secure/keys/myPrivateKey.key"

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

  if check_bootstraped "vm_set_master_crontab" "set"; then
    logger "Setting ALOJA crontab to master"

    crontab="# m h  dom mon dow   command
* * * * * export USER=$user && bash /home/$user/share/shell/exeq.sh $clusterName
#backup data
#0 * * * * cp -ru share/jobs_$clusterName local >> /home/$user/cron.log 2>&1"

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

  if check_bootstraped "vm_set_ssh" ""; then
    logger "Setting SSH keys to VM $vm_name "

    vm_execute "mkdir -p ~/.ssh/;
                echo -e \"Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet\" > ~/.ssh/config;
                echo '${insecureKey}' >> ~/.ssh/authorized_keys;" "parallel"

    scp -i "../secure/keys/myPrivateKey.key" -P "$vm_ssh_port"  \
           ../secure/keys/{id_rsa,id_rsa.pub,myPrivateKey.key} \
           "$user@$dnsName.cloudapp.net:.ssh/"

    vm_execute "chmod -R 0600 ~/.ssh/*;"

    test_set_ssh="$(vm_execute "cat ~/.ssh/config |grep 'UserKnownHostsFile'")"
    #logger "TEST SSH $test_set_ssh"

    if [ ! -z "$test_set_ssh" ] ; then
      #set the lock
      check_bootstraped "vm_set_ssh" "set"
    else
      logger "ERROR setting SSH for $vm_name. Test output: $test_set_ssh"
    fi
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
  if check_bootstraped "vm_install_packages" ""; then
    logger "Installing packages for for VM $vm_name "

    vm_execute "sudo sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list;
                sudo apt-get update && sudo apt-get install -y -f dsh sshfs sysstat gawk;"

    test_install_base_packages="$(vm_execute "dsh --version |grep 'Junichi'")"
    if [ ! -z "$test_install_base_packages" ] ; then
      #set the lock
      check_bootstraped "vm_install_packages" "set"
    else
      logger "ERROR installing base packages for $vm_name. Test output: $test_install_base_packages"
    fi

  else
    logger "Packages already initialized"
  fi
}

vm_set_dsh() {
  bootstrap_file="vm_set_dsh"
  if check_bootstraped "$bootstrap_file" ""; then
    logger "Setting up DSH for VM $vm_name "

    node_names="$(get_node_names)"
    vm_execute "mkdir -p ~/.dsh/group; echo -e \"$node_names\" > ~/.dsh/group/a;"
    slave_names="$(get_slaves_names)"
    vm_execute "mkdir -p ~/.dsh/group; echo -e \"$slave_names\" > ~/.dsh/group/s;"

    test_action="$(vm_execute " [ -f ~/.dsh/group/a ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR setting DSH for $vm_name. Test output: $test_action"
    fi

  else
    logger "DSH already configured"
  fi
}

vm_set_dot_files() {
  function_name="Dotfiles"
  bootstrap_file="vm_set_dot_files"
  if check_bootstraped "$bootstrap_file" ""; then
    logger "Setting up $function_name for VM $vm_name "

    vm_execute "echo -e \"
export HISTSIZE=50000
alias a='dsh -g a -M -c'
alias s='dsh -g s -M -c'\" >> ~/.bashrc;" "paralell"

    test_action="$(vm_execute " [ \"\$\(grep sdc1 /etc/fstab\)\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR setting $function_name for $vm_name. Test output: $test_action"
    fi

  else
    logger "$function_name already configured"
  fi
}


#1 command to execute in master (as a gateway to DSH)
cluster_execute() {
  vm_execute_master "dsh -g a -M -c \"$1\""
}

vm_initialize_disks() {
  if check_bootstraped "vm_initialize_disks" ""; then
    logger "Initializing disks for VM $vm_name "

    create_string=""
    get_initizalize_disks

    vm_execute "$create_string"

    test_action="$(vm_execute " [ \"\$\(lsblk|grep sdc1\)\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "vm_initialize_disks" "set"
    else
      logger "ERROR initializing disks for $vm_name. Test output: $test_action"
    fi

  else
    logger "Disks already initialized for VM $vm_name "
  fi

  vm_mount_disks
}

cluster_initialize_disks() {

  bootstrap_file="~/bootstrap_cluster_initialize_disks"

  create_string=""
  get_initizalize_disks

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already initialized';
  else
    echo 'Initializing disks';
    touch $bootstrap_file;
    $create_string
  fi"

  cluster_mount_disks
}

vm_mount_disks() {
  if check_bootstraped "vm_mount_disks" ""; then
    logger "Mounting disks for VM $vm_name "

    create_string="$(get_mount_disks)"

    vm_execute "$create_string"

    test_action="$(vm_execute " [ \"\$\(grep sdc1 /etc/fstab\)\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "vm_mount_disks" "set"
    else
      logger "ERROR mounting disks for $vm_name. Test output: $test_action"
    fi

  else
    logger "Disks already mounted for VM $vm_name "
  fi
}

cluster_mount_disks() {

  bootstrap_file="~/bootstrap_cluster_mount_disk"

#UUID=8ba50808-9dc7-4d4d-b87a-52c2340ec372	/	 ext4	defaults,discard	0 0
#/dev/sdb1	/mnt	auto	defaults,nobootwait,comment=cloudconfig	0	2

  create_string="$(get_mount_disks)"

  mounts="$create_string"

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already mounted';
  else
    echo 'Mounting disks';
    touch $bootstrap_file;

    $create_string

  fi"
}

#$1 filename $2 set lock
check_bootstraped() {
  fileExists="$(vm_execute "[[ -f ~/bootstrap_$1 ]] && echo '$testKey'")"

  #set lock
  if [ ! -z "$2" ] ; then
    vm_execute "touch ~/bootstrap_$1;"
  fi

  if [ ! -z "$fileExists" ] && [ "$fileExists" != "$testKey" ] ; then
    logger " Avoiding subsequent welcome banners"
    vm_execute "touch ~/.hushlogin; #avoid subsequent banners"
    fileExists="$(vm_execute "[[ -f ~/bootstrap_$1 ]] && echo '$testKey'")"
  fi
#TODO fix return codes should be the opposite
  if [ "$fileExists" == "$testKey" ] ; then
    return 1
  elif [ ! -z "$fileExists" ] ; then
    logger "Error checking bootstrap locks, LOCKING anyhow. Check manually. FileExists=$fileExists"
    return 0
  else
    return 0
  fi
}

#Puppet apply
vm_puppet_apply() {

		logger "Transfering puppet to VM"
		scp -i "../secure/keys/myPrivateKey.key" -P "$vm_ssh_port" -rp \
	           ../secure/keys/{id_rsa,id_rsa.pub,myPrivateKey.key} \
				$puppet "$user@$dnsName.cloudapp.net:~/"
		logger "Puppet install modules and apply"
		
	vm_execute "cd $(basename $puppet) && sudo ./$puppetBootFile"
	if [ ! -z "$puppetPostScript" ]; then
	 vm_execute "cd $(basename $puppet) && sudo ./$puppetPostScript"
	fi
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