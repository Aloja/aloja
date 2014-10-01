#common functions, non-executable, must be sourced
startTime="$(date +%s)"
self_name="$(basename $0)"

#check if azure command is installed
if ! nova --version 2>&1 > /dev/null ; then
  echo "nova command not instaled. Run: sudo pip install install rackspace-novaclient"
  exit 1
fi

[ -z "$type" ] && type="cluster"

[ -z $1 ] && { echo "Usage: $self_name ${type}_name [conf_file]"; exit 1;}

if [ -z $2 ]; then
	confFile="../secure/rackspace_settings.conf"
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

#global vars
nodeIP[$vm_name]=""
bootStraped="false"

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


#$1 vm_name
wait_vm_ready() {
  logger "Checking status of VM $1"
  waitStartTime="$(date +%s)"
  for tries in {1..300}; do
    currentStatus="$(nova show "$1" |grep "OS-EXT-STS:vm_state"|awk '{print $4}')"
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


vm_get_IP() {
  echo "$(nova show --minimal "$vm_name"|grep accessIPv4|awk '{print $4}')"
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

  if [ -z "${nodeIP[$vm_name]}" ] ; then
    nodeIP[$vm_name]="$(vm_get_IP)"
  fi

  if [ ! -z "${nodeIP[$vm_name]}" ] ; then

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
  else
    logger "ERROR: IP could not be obtained for VM $vm_name! ${nodeIP[$vm_name]}"
  fi
}

#$1 source files $2 destination $3 extra options
vm_local_scp() {
  logger "SCPing files"

  if [ -z "${nodeIP[$vm_name]}" ] ; then
    nodeIP[$vm_name]="$(vm_get_IP)"
  fi

  if [ ! -z "${nodeIP[$vm_name]}" ] ; then

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
  else
    logger "ERROR: IP could not be obtained for VM $vm_name! ${nodeIP[$vm_name]}"
  fi
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
