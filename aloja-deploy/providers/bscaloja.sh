CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

#overrides and custom minerva100 functions
#TODO move to another place, this right now is in secure but it cannot be read when executing benchs
homePrefixAloja="/home" #/home is not on the default location on minerva100


#minerva needs *real* user first
get_ssh_user() {

  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
    #"WARNINIG: connecting as root"
    echo "${userAlojaPre}"
  else
    echo "${userAloja}"
  fi
}

get_ssh_pass() {

  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
    #"WARNINIG: connecting as root"
    echo "${passwordAlojaPre}"
  else
    echo "${passwordAloja}"
  fi

}

vm_initial_bootstrap() {

  local bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

    echo "lllllllllllll"; exit 1

    vm_execute "
sudo useradd --create-home --home $homePrefixAloja/$userAloja -s /bin/bash $userAloja;
sudo echo -n '$userAloja:$passwordAloja' |sudo chpasswd;
sudo adduser $userAloja sudo;
sudo adduser $userAloja adm;

sudo bash -c \"echo '%sudo ALL=NOPASSWD:ALL' >> /etc/sudoers\";

sudo mkdir -p $homePrefixAloja/$userAloja/.ssh;
sudo bash -c \"echo '${insecureKey}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys\";
sudo chown -R $userAloja: $homePrefixAloja/$userAloja/.ssh;
sudo cp $homePrefixAloja/$userAloja/.profile $homePrefixAloja/$userAloja/.bashrc /root/;
"

    test_action="$(vm_execute " [ -f $homePrefixAloja/$userAloja/.ssh/authorized_keys ] && echo '$testKey'")"

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

#$1 vm_name
get_vm_id() {
  echo "${1:(-3)}" #echo the last 3 digits for minerva100
}

vm_create_RAID0() {

  local bootstrap_file="vm_create_RAID0"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    local num_drives="6"
    vm_execute "
sudo umount /dev/sdb{b..g}1;
yes | sudo mdadm -C /dev/md0 -l raid0 -n $num_drives /dev/sd{b..g}1;
sudo mkfs.ext4 /dev/md0;
"
#mount done by fstab
#sudo mount /dev/md0 /scratch/attached/1;
#not necessary to mark partition as raid auto apparently
#parted -s /dev/sdf -- mklabel gpt mkpart primary 0% 100% set 1 raid on

    logger "INFO: Updating /etc/fstab template"
    vm_update_template "/etc/fstab" "/dev/md0	/scratch/attached/1	ext4	defaults	0	0" "secured_file"

    logger "INFO: remounting disks according to fstab"
    vm_execute "
sudo mount -a;
sudo chown -R pristine: /scratch/attached/1;
"

    test_action="$(vm_execute " [ \"\$(sudo mdadm --examine /dev/sdb1 |grep 'Raid Devices : $num_drives')\" ] && echo '$testKey'")"

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

vm_final_bootstrap() {

  logger "Checking if to install Infiniband on node"
  vm_install_IB

#  logger "INFO: removing security packages and configs from Ubuntu 14.04"
#  vm_execute "
#sudo service apparmor stop
#sudo update-rc.d -f apparmor remove
#sudo apt-get purge -y apparmor apparmor-utils -y
#sudo ufw disable;
#"

  logger "INFO: making sure minerva-100 config is up to date"
  vm_execute "
sudo apt-get -y purge hadoop
"


}

#$1 vm_name

get_extra_fstab() {

  local minerva100_tmp="$homePrefixAloja/$userAloja/tmp"
  vm_execute "mkdir -p $minerva100_tmp"
  local create_string="$minerva100_tmp       /scratch/local    none bind,nobootwait 0 0"

  if [ "$clusterName" == "minerva100-10-18-21" ] ; then
    local create_string="$create_string
/scratch/attached/6       /scratch/ssd/1    none bind,nobootwait 0 0
/scratch/attached/7       /scratch/ssd/2    none bind,nobootwait 0 0"

  elif [ "$clusterName" == "minerva100-02-18-22" ] ; then
    local create_string="$create_string
/scratch/attached/7       /scratch/ssd/1    none bind,nobootwait 0 0"
  fi

  echo -e "$create_string"
}

get_extra_mount_disks() {
  if [ "$clusterName" == "minerva100-10-18-21" ] ; then
    echo -e "sudo mkdir -p /scratch/ssd/{1..2};"
  elif [ "$clusterName" == "minerva100-02-18-22" ] ; then
    echo -e "sudo mkdir -p /scratch/ssd/1;"
  fi
}

