#Check that CONF_DIR is correctly set before starting
[ -z "$CONF_DIR" ] || [ ! -f "$CONF_DIR/provider_functions.sh" ] && {
  echo "ERROR: CONF_DIR not set correctly" ; exit 1;
}

#load provider functions
source "$CONF_DIR/provider_functions.sh"

#test variables
[ -z "$testKey" ] && { logger "testKey not set! Exiting"; exit 1; }


#global vars
bootStrapped="false" #not needed for Azure

if [ "$cloud_provider" == "azure" ] ; then
   devicePrefix="sd"
   cloud_drive_letters="$(echo {c..z})"
elif [ "$cloud_provider" == "rackspace" ] ; then
   devicePrefix="xvd"
   cloud_drive_letters="$(echo {b..z})"
else
  logger "WARNING: Provider $cloud_provider has no devices definition."
  #exit 1
fi


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

  if [ "$vmType" != 'windows' ] ; then

    #check if machine has been already created or creates it
    vm_create_connect "$vm_name"
    #boostrap and provision VM with base packages in parallel

    if [ -z "$noParallelProvision" ] && [ "$type" != "node" ] ; then
      vm_provision & #in parallel
    else
      vm_provision
    fi

  elif [ "$vmType" == 'windows' ] ; then
    vm_check_create "$vm_name" "$vm_ssh_port"
    wait_vm_ready "$vm_name"
    vm_check_attach_disks "$vm_name"
    [ ! -z "$endpoints" ] && vm_endpoints_create

  else
    logger "ERROR: Invalid VM OS type. Type $type"
    exit 1
  fi
}

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
  elif [ "$attachedVolumes" != "0" ] && ! vm_test_initiallize_disks ; then
    vm_check_attach_disks "$1"
  fi

  [ ! -z "$endpoints" ] && vm_endpoints_create
}

#requires $vm_name and $type to be set
vm_provision() {
  vm_initial_bootstrap
  vm_set_ssh

  #[ "$type" != "cluster" ] && {
    if [ -z "$noSudo" ] ; then
      vm_initialize_disks #cluster is in parallel later
      vm_mount_disks
    else
      logger "WARNING: Not mounting disk, sudo is not present or disabled for VM $vm_name"
    fi
  #}

  vm_install_base_packages
  vm_set_dot_files &

  [ "$type" == "cluster" ] && vm_set_dsh

  [ "$type" != "cluster" ] && vm_final_bootstrap #cluster is in parallel later

  #logger "Waiting for VM $vm_name deployment"
  #wait $! #wait for the provisioning to be ready

  logger "Provisioning for VM $vm_name ready, finalizing deployment"
  #check if extra commands are specified once VMs are provisioned
  vm_finalize &
}

vm_finalize() {
  #extra commands to exectute (if defined)
  [ ! -z "$extraLocalCommands" ] && eval $extraLocalCommands #eval is to support multiple commands
  [ ! -z "$extraCommands" ] && vm_execute "$extraCommands"
  [ ! -z "$puppet" ] && vm_puppet_apply
}

get_node_names() {
  local node_names=''
  if [ ! -z "$nodeNames" ] ; then
    local node_names="$nodeNames"
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
      if [ ! -z "$node_names" ] ; then
        local node_names="${node_names}\n${clusterName}-${vm_id}"
      else
        local node_names="${clusterName}-${vm_id}"
      fi
    done
  fi

  echo -e "$node_names"
}

get_slaves_names() {
  local node_names=""
  if [ ! -z "$nodeNames" ] ; then #remove the master
    local node_number=""
    for node_name in $nodeNames ; do
      [[ "$node_number" -gt "1" ]] && node_names+="\n" #add new line, but no to the first or last one
      [[ "$node_number" -gt "0" ]] && node_names+="$node_name"
      local node_number="$((node_number+1))"
    done
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 1 "$numberOfNodes") ; do #pad the sequence with 0s
      if [ ! -z "$node_names" ] ; then
        node_names="${node_names}\n${clusterName}-${vm_id}"
      else
        node_names="${clusterName}-${vm_id}"
      fi
    done
  fi
  echo -e "$node_names"
}

#the default SSH host override if necessary i.e. in Azure, Openstack
get_ssh_host() {
 echo "$vm_name"
}

#the default key override if necessary i.e. in Azure
get_ssh_key() {
 echo "../secure/keys/id_rsa"
}

#default port, override to change i.e. in Azure
get_ssh_port() {
  if [ ! -z "$vm_ssh_port" ] ; then
    echo "$vm_ssh_port"
  else
    echo "22" #default port when empty or not overwriten
  fi
}

#default port, override to change i.e. Openstack might need first root
get_ssh_user() {
  echo "$userAloja"
}

vm_initial_bootstrap() {
  bootStrapped="true" #not necesarry by default
}

check_sudo() {

#  test_action="$(vm_execute " sudo test && echo '$testKey'" 2> /dev/null)"
#  #in case SSH is not yet configured, a welcome message will be appended
#
#  test_action="$(echo "$test_action"|grep "$testKey")"

  if [ -z "$noSudo" ] ; then
    #logger "sudo permission OK"
    return 0
  else
    logger "WARNING: cannot sudo or disabled"
    return 1
  fi
}

check_sshpass() {
  if ! which sshpass > /dev/null; then
    logger "WARNING: sshpass is not installed, attempting install for Debian based systems"
    sudo apt-get install -y sshpass
    if ! which sshpass > /dev/null; then
      logger "ERROR: sshpass could not be installed or not found"
      exit 1
    fi
  fi
}

#$1 commands to execute $2 set in parallel (&) $3 use password
#$vm_ssh_port must be set before
vm_execute() {
  #logger "Executing in VM $vm_name command(s): $1"
  logger "DEBUG: executing as $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port) command:\n $1" "" "log to file"

  set_shh_proxy

  #Use SSH keys
  if [ -z "$3" ] ; then
    chmod 0600 $(get_ssh_key)
    #echo to print special chars;
    if [ -z "$2" ] ; then
      echo "$1" |ssh -i "$(get_ssh_key)" -q -o connectTimeout=5 -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
    else
      echo "$1" |ssh -i "$(get_ssh_key)" -q -o connectTimeout=5 -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)" &
    fi
    #chmod 0644 $(get_ssh_key)
  #Use password
  else
    check_sshpass

    if [ -z "$2" ] ; then
      echo "$1" |sshpass -p "$passwordAloja" ssh -q -o connectTimeout=5 -o StrictHostKeyChecking=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
    else
      echo "$1" |sshpass -p "$passwordAloja" ssh -q -o connectTimeout=5 -o StrictHostKeyChecking=no -o "$proxyDetails" "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)" &
    fi
  fi
}

set_shh_proxy() {
  if [ ! -z "$useProxy" ] ; then
    proxyDetails="ProxyCommand $useProxy"
  else
    proxyDetails="ProxyCommand none"
  fi

}
#interactive SSH $1 use password
vm_connect() {

  set_shh_proxy

  #Use SSH keys
  if [ -z "$1" ] ; then
    chmod 0600 $(get_ssh_key)
    logger "Connecting to VM $vm_name, with details: ssh -i $(get_ssh_key) -o '$proxyDetails' $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port)"
    ssh -i "$(get_ssh_key)" -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o "$proxyDetails" -t "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"

    if [ "$?" != "0" ] ; then
      logger "WARNING: Falied SSH connecting using keys.  Retuned code: $?"
      failed_ssh_keys="true"
    fi
    #chmod 0644 $(get_ssh_key)
  #Use password
  else
    check_sshpass
    logger "Connecting to VM $vm_name (using PASS), with details: ssh -o '$proxyDetails' $(get_ssh_user)@$(get_ssh_host) -p $(get_ssh_port)"
    sshpass -p "$passwordAloja" ssh -o StrictHostKeyChecking=no -o "$proxyDetails" -t "$(get_ssh_user)"@"$(get_ssh_host)" -p "$(get_ssh_port)"
  fi
}

#$1 source files $2 destination $3 extra options $4 use password
vm_local_scp() {
  logger "SCPing files"

  set_shh_proxy

  #Use SSH keys
  if [ -z "$4" ] ; then
    #eval is for parameter expansion
    scp -i "$(get_ssh_key)" -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o "$proxyDetails" -P  "$(get_ssh_port)" $(eval echo "$3") $(eval echo "$1") "$(get_ssh_user)"@"$(get_ssh_host):$2"
  #Use password
  else
    check_sshpass

    sshpass -p "$passwordAloja" scp -o StrictHostKeyChecking=no -o "$proxyDetails" -P  "$(get_ssh_port)" $(eval echo "$3") $(eval echo "$1") "$(get_ssh_user)"@"$(get_ssh_host):$2"
  fi
}

#$1 source files $2 destination $3 extra options
#$vm_ssh_port must be set first
vm_rsync() {
    logger "RSynching: $1 To: $2"
    #eval is for parameter expansion  --progress
    rsync -aur --partial  -e "ssh -i $(get_ssh_key) -o StrictHostKeyChecking=no -p "$(get_ssh_port)" " $(eval echo "$3") $(eval echo "$1") "$(get_ssh_user)"@"$(get_ssh_host):$2"
}

get_master_name() {
  local master_name=''

  if [ ! -z "$nodeNames" ] ; then
    for node in $nodeNames ; do #pad the sequence with 0s
      local master_name="$node"
      break #just return one
    done
  else #generate them from standard naming
    for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
      local master_name="${clusterName}-${vm_id}"
      break #just return one
    done
  fi
  echo "$master_name"
}

#vm_name must be set
get_vm_ssh_port() {
  local node_ssh_port=''
  for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s
    local vm_name_tmp="${clusterName}-${vm_id}"
    local vm_ssh_port_tmp="2${clusterID}${vm_id}"

    if [ ! -z "$vm_name" ] && [ "$vm_name" == "$vm_name_tmp" ] ; then
      local node_ssh_port="2${clusterID}${vm_id}"
      break #just return one
    fi
  done
  echo "$node_ssh_port"
}

#requires $create_string to be defined
get_initizalize_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

logger "DEBUG: devicePrefix ${devicePrefix} cloud_drive_letters $cloud_drive_letters  " "" "to_file_"

  local create_string=""
  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    local create_string="$create_string
sudo parted -s /dev/${devicePrefix}${drive_letter} -- mklabel gpt mkpart primary 0% 100%;
sudo mkfs -t ext4 -m 1 -O dir_index,extent,sparse_super -F /dev/${devicePrefix}${drive_letter}1;"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done

  echo -e "$create_string"
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

get_share_location() {

  local minerva_mount="npoggi@minerva.bsc.es:/home/npoggi/tmp/ /home/$userAloja/minerva fuse.sshfs noauto,_netdev,users,IdentityFile=/home/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"

  if [ "$cloud_provider" == "pedraforca" ] ; then
    local fs_mount="$userAloja@minerva.bsc.es:/home/$userAloja/aloja/ /home/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=/home/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"
  elif [ "$subscriptionID" == "8869e7b1-1d63-4c82-ad1e-a4eace52a8b4" ] && [ "$virtualNetworkName" == "west-europe-net" ] || [ "$cloud_provider" != "azure" ] ; then
    #internal network
    local fs_mount="$minerva_mount
$userAloja@aloja-fs:/home/$userAloja/share/ /home/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=/home/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no 0 0"
  else
    #external network
    local fs_mount="$minerva_mount
$userAloja@al-1001.cloudapp.net:/home/$userAloja/share/ /home/$userAloja/share fuse.sshfs _netdev,users,IdentityFile=/home/$userAloja/.ssh/id_rsa,allow_other,nonempty,StrictHostKeyChecking=no,Port=222 0 0"
  fi

  echo -e "$fs_mount"
}

#requires $create_string to be defined
get_mount_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  fs_mount="$(get_share_location)"

  if [ -z "$dont_mount_share" ] ; then
    create_string="$fs_mount"
  fi

  num_drives="1"
  for drive_letter in $cloud_drive_letters ; do
    create_string="$create_string
/dev/${devicePrefix}${drive_letter}1       /scratch/attached/$num_drives  auto    defaults,nobootwait,noatime,nodiratime 0       2"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done

  if [ "$cloud_provider" == "azure" ] ; then
  create_string="$create_string
/mnt       /scratch/local    none bind 0 0"
  fi

#sudo chmod 777 /etc/fstab; sudo echo -e '# <file system> <mount point>   <type>  <options>       <dump>  <pass>
#/dev/xvda1	/               ext4    errors=remount-ro,noatime,barrier=0 0       1
##/dev/xvdc1	none            swap    sw              0       0' > /etc/fstab;


  create_string="
    mkdir -p ~/{share,minerva};
    sudo mkdir -p /scratch/attached/{1,2,3} /scratch/local;
    sudo chown -R $userAloja: /scratch;

    sudo chmod 0777 /etc/fstab;



    sudo echo '$create_string' >> /etc/fstab;

    sudo chmod 0644 /etc/fstab;
    sudo mount -a;
    sudo chown -R $userAloja /scratch
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
    if [ "$currentStatus" == "$(get_OK_status)" ] ; then
      logger " VM $1 is ready!"
      break
    else
      logger " VM $1 is in $currentStatus status. Waiting for: $waitElapsedTime s. $tries attempt(s)."
    fi

    #sleep 1
  done
}

#"$vm_name" "$vm_ssh_port" must be set before
#1 number of tries
wait_vm_ssh_ready() {
  logger "Checking SSH status of VM $vm_name"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do

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
      if [ "$tries" == "2" ] ; then
        vm_start "$vm_name"
      elif [ "$tries" == "100" ] ; then
        vm_reboot "$vm_name"
      fi

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

  #TODO check if disks are formated

  test_action="$(vm_execute "$create_string")"
  #in case SSH is not yet configured, a welcome message will be appended

  test_action="$(echo "$test_action"|grep "$testKey")"

  if [ ! -z "$test_action" ] ; then
    logger " disks OK for VM $vm_name"
    return 0
  else
    logger " disks KO for $vm_name Test output: $test_action"
    return 1
  fi
}

#$1 use password based auth
vm_set_ssh() {

  local bootstrap_file="vm_set_ssh"
  if check_bootstraped "$bootstrap_file" ""; then
    logger "Setting SSH keys to VM $vm_name "

    if [ -z "$1" ] ; then
      local use_password="" #use SSH keys
    else
      local use_password="true" #use password
    fi

    vm_execute "mkdir -p ~/.ssh/;
                echo -e \"Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet\" > ~/.ssh/config;
                echo '${insecureKey}' >> ~/.ssh/authorized_keys;" "parallel" "$use_password"

    vm_local_scp "../secure/keys/{id_rsa,id_rsa.pub,myPrivateKey.key}" "~/.ssh/" "" "$use_password"
    vm_execute "chmod -R 0600 ~/.ssh/*;" "" "$use_password"

    test_set_ssh="$(vm_execute "cat ~/.ssh/config |grep 'UserKnownHostsFile' && ls ~/.ssh/id_rsa")"
    #logger "TEST SSH $test_set_ssh"

    if [ ! -z "$test_set_ssh" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
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

#vm_format_disks() {
#  if check_bootstraped "vm_format_disks" "set"; then
#    logger "Formating disks for VM $vm_name "
#
#    vm_execute ";"
#  else
#    logger "Disks initialized"
#  fi
#}

vm_install_base_packages() {
  if check_sudo ; then
    if check_bootstraped "vm_install_packages" ""; then
      logger "Installing packages for for VM $vm_name "

      #sudo sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list;

#only update apt when is 1 week old (600000) to save time
      vm_execute '
if [ ! -f "/var/lib/apt/periodic/update-success-stamp" ] || [ "$[$(date +%s) - $(stat -c %Y /var/lib/apt/periodic/update-success-stamp)]" -ge 600000 ]; then
  sudo apt-get update -m;
fi

sudo apt-get install -y -f dsh rsync sshfs sysstat gawk libxml2-utils ntp;'

      logger "Checking if extra packages defined to install them"
      vm_install_extra_packages

      test_install_base_packages="$(vm_execute "sar -V |grep 'Sebastien Godard' && dsh --version |grep 'Junichi'")"
      if [ ! -z "$test_install_base_packages" ] ; then
        #set the lock
        check_bootstraped "vm_install_packages" "set"
      else
        logger "ERROR: installing base packages for $vm_name. Test output: $test_install_base_packages"
      fi

    else
      logger "Packages already initialized"
    fi
  else
    logger "WARNING: no sudo access or disabled, no packages installed"
  fi
}

#override to install aditional packages
vm_install_extra_packages() {
  logger " no extra packages defined for cluster"
}

vm_set_dsh() {
  local bootstrap_file="vm_set_dsh"
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
  local function_name="Dotfiles"
  local bootstrap_file="vm_set_dot_files"
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
  if [[ "$attachedVolumes" -gt "0" ]] ; then

    if check_bootstraped "vm_initialize_disks" ""; then
      logger "Initializing disks for VM $vm_name "

      create_string="$(get_initizalize_disks)"

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

  else
    logger " no need to attach disks for VM $vm_name"
  fi
}

cluster_initialize_disks() {

  local bootstrap_file="~/bootstrap_cluster_initialize_disks"

  create_string="echo 'yeah'; $(get_initizalize_disks)"

  cluster_execute "
  if [[ -f $bootstrap_file ]] ; then
    echo 'Disks already initialized';
  else
    echo 'Initializing disks';

    $create_string
    echo 'Here';

    test_action=\"\$(lsblk|grep ${devicePrefix}c1\) ] && echo '$testKey')\"
    if [ \"\$test_action\" == \"$testKey\" ] ; then
      touch $bootstrap_file;
    else
      echo  'ERROR initializing disks for $vm_name. Test output: \$test_action'
    fi
  fi"
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

  local bootstrap_file="~/bootstrap_cluster_mount_disk"

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

#parallel Node config
function cluster_parallel_config() {
  if [ "$vmType" != 'windows' ] && [ -z "$dont_mount_share" ] && check_sudo; then

#    logger "Checking if to initilize cluster disks"
#    cluster_initialize_disks
#    logger "Checking if to mount cluster disks"
#    cluster_mount_disks

    cluster_final_boostrap
  else
    logger "Disks initialization and mounting disabled"
  fi
}

#master config to execute benchmarks
function cluster_queue_jobs() {
  if [ "$vmType" != 'windows' ] ; then
    vm_set_master_crontab
    vm_set_master_forer &
  fi
}

#$1 filename $2 set lock $3 execute on master
check_bootstraped() {

  local bootstrap_filename="bootstrap_${1}_${vm_name}"

  if [ -z "$3" ] ; then
    fileExists="$(vm_execute "[[ -f ~/$bootstrap_filename ]] && echo '$testKey'")"
  else
    fileExists="$(vm_execute_master "[[ -f ~/$bootstrap_filename ]] && echo '$testKey'")"
  fi

  #set lock
  if [ ! -z "$2" ] ; then
    vm_execute "touch ~/$bootstrap_filename;"
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
  #save current ssh_port and vm_name
  local vm_ssh_port_save="$vm_ssh_port"
  local vm_name_save="$vm_name"

  vm_ssh_port="$(get_vm_ssh_port)"
  vm_name="$(get_master_name)"

  vm_execute "$1"

  #restore port and vm_name
  vm_ssh_port="$vm_ssh_port_save"
  vm_name="$vm_name_save"
}

vm_set_master_crontab() {

  if check_bootstraped "vm_set_master_crontab" "set" "master"; then
    logger "Setting ALOJA crontab to master"

    crontab="# m h  dom mon dow   command
* * * * * export USER=$userAloja && bash /home/$userAloja/share/shell/exeq.sh $clusterName
#backup data
#0 * * * * cp -ru share/jobs_$clusterName local >> /home/$userAloja/cron.log 2>&1"

    vm_execute_master "echo '$crontab' |crontab"

    #start the queue so dirs are created
    vm_execute_master "export USER=$userAloja && bash /home/$userAloja/share/shell/exeq.sh $clusterName"

  else
    logger "Crontab already installed in master"
  fi
}

vm_set_master_forer() {

  if check_bootstraped "vm_set_master_forer" "set" "master"; then

  logger "Checking if queues already setup"
  test_action="$(vm_execute "ls ~/local/queue_${clusterName}/conf/counter && echo '$testKey'")"
  #in case we get a welcome banner we need to grep
  test_action="$(echo -e "$test_action"|grep "$testKey")"

  if [ -z "$test_action" ] ; then
    #TODO shouldn't be necessary but...
    logger "DEBUG: Re-mounting disks"
    cluster_execute "sudo mount -a"
    cluster_execute "ls -lah ~/share/safe_store"

    logger "Generating jobs (forer)"

    vm_execute_master "bash /home/$userAloja/share/shell/forer_az.sh $clusterName"
  else
    logger " queues already setup"
  fi

  else
    logger "Jobs already generated and queued"
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

#Initialized the shared file system
#$1 share location
vm_make_fs() {

  logger "Initializing the shared file system for VM $vm_name"

  if [ -z "$1" ] ; then
    local share_disk_path="/scratch/attached/1"
  else
    local share_disk_path="$1"
  fi

  shared_dir="/home/$userAloja/share"

  if [ -z "$homeIsShared" ] ; then
    logger "Checking if $shared_dir is correctly linked"
    test_action="$(vm_execute "[ -d $shared_dir ] && [ -L $shared_dir ] && ls $shared_dir/safe_store && echo '$testKey'")"
    #in case we get a welcome banner we need to grep
    test_action="$(echo -e "$test_action"|grep "$testKey")"

    if [ -z "$test_action" ] ; then
      logger " Linking $shared_dir"
      vm_execute "sudo chown -R ${user} /scratch;
[ -d $shared_dir ] && [ ! -L $shared_dir ] && mv $shared_dir ~/share_backup && echo 'WARNING: share dir moved to ~/share_backup';
ln -sf $share_disk_path $shared_dir;
touch $shared_dir/safe_store;
    "
    else
      logger " $shared_dir is correctly mounted"
    fi

  else
    logger "NOTICE: /home is marked as shared, creating the dir if necessary"
    vm_execute "mkdir -p $shared_dir; touch $shared_dir/safe_store"
  fi

  vm_rsync "../shell" "$shared_dir"
  vm_rsync "../aloja-deploy" "$shared_dir"

  logger "Checking if aplic exits to redownload or rsync for changes"
  test_action="$(vm_execute "ls $shared_dir/aplic/aplic_version && echo '$testKey'")"
  #in case we get a welcome banner we need to grep
  test_action="$(echo -e "$test_action"|grep "$testKey")"

  if [ -z "$test_action" ] ; then
    logger "Downloading aplic"
    vm_execute "cd $shared_dir; wget -nv https://www.dropbox.com/s/ywxqsfs784sk3e4/aplic.tar.bz2"

    logger "Uncompressing aplic"
    vm_execute "cd $shared_dir; tar -jxf aplic.tar.bz2"
  fi

  logger "RSynching aplic for possible updates"
  vm_rsync "../blobs/aplic" "$shared_dir"

}