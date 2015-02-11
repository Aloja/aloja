CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

#overrides and custom minerva100 functions

#minerva needs *real* user first
get_ssh_user() {

  #check if we can change from root user
  if [ "$requireRootFirst" ] ; then
    #"WARNINIG: connecting as root"
    echo "npoggi"
  else
    echo "$userAloja"
  fi
}

vm_initial_bootstrap() {

  local bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

    vm_execute "
sudo useradd --create-home --home $homePrefixAloja/$userAloja -s /bin/bash $userAloja;
sudo echo -n '$userAloja:$passwordAloja' |sudo chpasswd;
sudo adduser $userAloja sudo;
sudo adduser $userAloja adm;

sudo bash -c \"echo '%sudo ALL=NOPASSWD:ALL' >> /etc/sudoers\";

sudo mkdir -p $homePrefixAloja/$userAloja/.ssh;
sudo bash -c \"echo '${insecureKey}' >> sudo $homePrefixAloja/$userAloja/.ssh/authorized_keys\";
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
    vm_update_template "/dev/md0	/scratch/attached/1	ext4	defaults	0	0" "secured_file"

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
  #logger "INFO: Creating RAID0 on 6 disks"
  #vm_create_RAID0
  :
}