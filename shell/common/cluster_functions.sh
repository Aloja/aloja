CONF_DIF="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CONF_DIF/common.sh"
source "$CONF_DIF/provider_functions.sh"

#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }


#test and load cluster config

clusterConfigFilePath="$CONF_DIF/../conf"

[ ! -f "$clusterConfigFilePath/$clusterConfigFile" ] && { logger "$clusterConfigFilePath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config second
source "$clusterConfigFilePath/$clusterConfigFile"


#global vars
bootStrapped="true" #not needed for Azure

if [ "$cloud_provider" == "azure" ] ; then
   devicePrefix="sd"
   cloud_drive_letters="$(echo {c..z})"
   cloud_drive_letters_test="$(echo {b..z})"
elif [ "$cloud_provider" == "rackspace" ] ; then
   devicePrefix="xvd"
   cloud_drive_letters="$(echo {b..z})"
   cloud_drive_letters_test="$(echo {a..z})"
else
  logger "Cloud provider $cloud_provider not defined.  Exiting..."
  exit 1
fi

logger "Starting ALOJA deploy tools for Cloud provider: $cloud_provider"


#$1 vm_name
vm_create_connect() {

  #make sure we clean the variable
  bootStrapped="false"

  #test first if machines are accessible via SSH to save time
  if ! wait_vm_ssh_ready "1" ; then
    vm_check_create "$1" "$vm_ssh_port"
    wait_vm_ready "$1"

    vm_check_attach_disks "$1"

    #wait for ssh to be ready
    wait_vm_ssh_ready

  #make sure the correct number of disks is innitialized
  elif ! vm_test_initiallize_disks ; then
    vm_check_attach_disks "$1"
  fi
}

get_node_names() {
  local node_names=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    if [ ! -z "$node_names" ] ; then
      node_names="${node_names}\n${clusterName}-${vm_id}"
    else
      node_names="${clusterName}-${vm_id}"
    fi
  done
  echo -e "$node_names"
}

get_slaves_names() {
  local node_names=''
  for vm_id in $(seq -f "%02g" 1 "$numberOfNodes") ; do #pad the sequence with 0s
    if [ ! -z "$node_names" ] ; then
      node_names="${node_names}\n${clusterName}-${vm_id}"
    else
      node_names="${clusterName}-${vm_id}"
    fi
  done
  echo -e "$node_names"
}

get_master_name() {
  local master_name=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_name="${clusterName}-${vm_id}"
    break #just return one
  done
  echo "$master_name"
}

get_master_ssh_port() {
  master_ssh_port=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    master_ssh_port="2${clusterID}${vm_id}"
    break #just return one
  done
}

#requires $create_string to be defined
get_initizalize_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  create_string=""
  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    create_string="$create_string
sudo parted -s /dev/${devicePrefix}${drive_letter} -- mklabel gpt mkpart primary 0% 100%;
sudo mkfs.ext4 -F /dev/${devicePrefix}${drive_letter}1;"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
}

get_initizalize_disks_test() {
  create_string="echo ''"
  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    create_string="$create_string && lsblk|grep ${devicePrefix}${drive_letter}"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
  create_string="$create_string && echo '$testKey'"

  echo "$create_string"
}

#requires $create_string to be defined
get_mount_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  if [ "$subscriptionID" == "8869e7b1-1d63-4c82-ad1e-a4eace52a8b4" ] && [ "$virtualNetworkName" == "west-europe-net" ] || [ "$cloud_provider" != "azure" ] ; then
    #internal network
    fs_mount="$user@aloja-fs:/home/$user/share/ /home/$user/share fuse.sshfs _netdev,users,IdentityFile=/home/$user/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"
  else
    #external network
    fs_mount="$user@al-1001.cloudapp.net:/home/$user/share/ /home/$user/share fuse.sshfs _netdev,users,IdentityFile=/home/$user/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,Port=222 0 0"
  fi

  create_string="npoggi@minerva.bsc.es:/home/npoggi/tmp/ /home/$user/minerva fuse.sshfs noauto,_netdev,users,IdentityFile=/home/$user/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"

  if [ -z "$dont_mount_share" ] ; then
    create_string="$create_string
$fs_mount"
  fi

  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    create_string="$create_string
/dev/${devicePrefix}${drive_letter}1       /scratch/attached/1  auto    defaults,nobootwait 0       2"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done

  create_string="$create_string
/mnt       /scratch/local    none bind 0 0"

  create_string="
    mkdir -p ~/{share,minerva};
    sudo mkdir -p /scratch/attached/{1,2,3} /scratch/local;
    sudo chown -R $user: /scratch;

    sudo chmod 0777 /etc/fstab;

    sudo echo '$create_string' >> /etc/fstab;

    sudo chmod 0644 /etc/fstab;
    sudo mount -a;
    sudo chown -R $user /scratch
  "

  echo -e "$create_string"
}

#$1 vm_name
wait_vm_ready() {
  logger "Checking status of VM $1"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do
    currentStatus="$(vm_get_status "$1")"
    waitElapsedTime="$(( $(date +%s) - waitStartTime ))"
    if [ "$currentStatus" == "active" ] ; then
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

vm_test_initiallize_disks() {

  logger "Checking if the correct number of disks are atttached to VM $vm_name"

  create_string="$(get_initizalize_disks_test)"

  #logger "DEBUG: $create_string"

  test_action="$(vm_execute "$create_string")"
  #in case SSH is not yet configured, a welcome message will be appended

  test_action="$(echo "$test_action"|grep "$testKey")"

  if [ ! -z "$test_action" ] ; then
    logger " disks OK for VM $vm_name"
    return 0
  else
    logger " disks KO for $vm_name. Test output: $test_action"
    return 1
  fi
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

#requires $vm_name and $type to be set
vm_create_node() {

  #check if machine has been already created or creates it
  vm_create_connect "$vm_name"

  #boostrap VM
  vm_initial_bootstrap

  vm_set_ssh
  [ "$type" != "cluster" ] && vm_initialize_disks #cluster is in parallel later
  vm_install_base_packages
  vm_set_dot_files &

  [ "$type" != "cluster" ] && vm_final_bootstrap #cluster is in parallel later

  #extra commands to exectute (if defined)
  [ ! -z "$extraCommands" ] && vm_execute "$extraCommands"

  [ ! -z "$puppet" ] && vm_puppet_apply

  [ ! -z "$endpoints" ] && vm_endpoints_create
}

vm_set_ssh() {

  if check_bootstraped "vm_set_ssh" ""; then
    logger "Setting SSH keys to VM $vm_name "

    vm_execute "mkdir -p ~/.ssh/;
                echo -e \"Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet\" > ~/.ssh/config;
                echo '${insecureKey}' >> ~/.ssh/authorized_keys;" "parallel"

    vm_local_scp "../secure/keys/{id_rsa,id_rsa.pub,myPrivateKey.key}" "~/.ssh/"

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

#$1 vm_name
vm_check_attach_disks() {
  #attach required volumes
  if [ ! -z "$attachedVolumes" ] ; then

    logger " getting number of attached disks to VM $1"
    numberOfDisks="$(number_of_attached_disks "$1")"
    logger " $numberOfDisks attached disks to VM $1"

    if [ "$attachedVolumes" -gt "$numberOfDisks" ] ; then
      missingDisks="$(( attachedVolumes - numberOfDisks ))"
      logger " need to attach $missingDisks disk(s) to VM $1"
      for ((disk=0; disk<missingDisks; disk++ )) ; do
        vm_attach_new_disk "$1" "$diskSize" "$disk"
      done
    else
      logger " no need to attach new disks to VM $1"
    fi
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
                sudo apt-get update && sudo apt-get install -y -f dsh sshfs sysstat gawk libxml2-utils;"

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

    test_action="$(vm_execute " [ \"\$\(grep ${devicePrefix}c1 /etc/fstab\)\" ] && echo '$testKey'")"
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

    test_action="$(vm_execute " [ \"\$\(lsblk|grep ${devicePrefix}c1\)\" ] && echo '$testKey'")"
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

    test_action="$(vm_execute " [ \"\$\(grep ${devicePrefix}c1 /etc/fstab\)\" ] && echo '$testKey'")"
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

#Puppet apply
vm_puppet_apply() {

  logger "Transfering puppet to VM"
  vm_local_scp "$puppet" "~/" "-rp"
  logger "Puppet install modules and apply"

	vm_execute "cd $(basename $puppet) && sudo ./$puppetBootFile"
	if [ ! -z "$puppetPostScript" ]; then
	 vm_execute "cd $(basename $puppet) && sudo ./$puppetPostScript"
	fi
}