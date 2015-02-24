CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

#overrides and custom minerva100 functions
#TODO move to another place, this right now is in secure but it cannot be read when executing benchs
homePrefixAloja="/users/scratch" #/home is not on the default location on minerva100


#minerva needs *real* user first
get_ssh_user() {

  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
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
    vm_update_template "/dev/md/minerva-101:0	/scratch/attached/1	ext4	defaults	0	0" "secured_file"

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

  logger "INFO: removing security packages and configs from Ubuntu 14.04"
  vm_execute "
sudo service apparmor stop
sudo update-rc.d -f apparmor remove
sudo apt-get purge -y apparmor apparmor-utils -y
sudo ufw disable;
"

  logger "INFO: making sure minerva-100 config is up to date"
  vm_execute "
sudo apt-get -y purge hadoop
"

}

vm_install_IB() {

wget https://www.dropbox.com/s/d8u924cuiurhy3v/MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz?dl=0
#cp /home/dcarrera/MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz .
tar xzf MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz
apt-get -y remove libopenmpi1.6 openmpi-doc libopenmpi-dev openmpi-common mpi-default-bin openmpi-bin
cd MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64
./mlnxofedinstall --without-fw-update --hpc -q
/etc/init.d/openibd restart
/usr/bin/hca_self_test.ofed

}