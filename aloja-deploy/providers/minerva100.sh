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
    vm_update_template "/etc/fstab" "/dev/md/minerva-101:0	/scratch/attached/1	ext4	defaults	0	0" "secured_file"

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

vm_install_IB() {

  local bootstrap_file="vm_install_IB"

  if check_bootstraped "$bootstrap_file" ""; then

    #since the installation is quite slow we first test if it is working
    test_action="$(vm_execute " [ \"\$(ping -c 1 $(get_vm_IB_hostname $vm_name))\" ] && echo '$testKey'")"

    if [ "$test_action" != "$testKey" ] ; then

      local work_dir="/tmp"
      local driver_name="MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz"

      logger "INFO: Installing InfiniBand drivers"
      logger "INFO: uninstalling conflicting packages (if needed)"
      vm_execute "sudo apt-get -y remove libopenmpi1.6 openmpi-doc libopenmpi-dev openmpi-common mpi-default-bin openmpi-bin;"

      logger "INFO: Downloading drivers (if needed)"

      vm_execute "[ ! -f "$work_dir/$driver_name" ] && wget 'https://www.dropbox.com/s/d8u924cuiurhy3v/$driver_name?dl=1' -O '$work_dir/$driver_name'"
      #cp /home/dcarrera/MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz .

      logger "INFO: Untaring drivers"
      vm_execute "cd $work_dir; tar -xzf '$driver_name'"

      logger "INFO: Installing drivers"
      vm_execute "
cd $work_dir/${driver_name%.*}
sudo ./mlnxofedinstall --without-fw-update --hpc -q
sudo /etc/init.d/openibd restart
sudo /usr/bin/hca_self_test.ofed
"

      logger "INFO: Checking if installation was succesfull"
      if [ "$(grep IB /etc/network/interfaces 2> /dev/null)" ] ; then
        logger "INFO: IB interface already created"
      else
        logger "INFO: IB interface NOT created, intalling..."
        local IP_suffix="$(vm_execute 'ifconfig eth0 |grep Mask | cut -d "." -f 4 |cut -d " " -f 1')"
        logger "INFO: Updating /etc/network/interfaces with IP_suffix: $IP_suffix"
        vm_update_template "/etc/network/interfaces" "
#IB Interface
iface ib0 inet static
address 10.0.1.$IP_suffix
netmask 255.255.0.0" "secured_file"

        logger "INFO: bringing up interface"
        vm_execute "sudo ifdown ib0; sudo ifup ib0;"

      fi

      logger "INFO: Recreating /etc/hosts with IB names for $(get_vm_IB_hostname $vm_name)"
      vm_update_template "/etc/hosts" "$(get_IB_hostnames)" "secured_file"

      test_action="$(vm_execute " [ \"\$(ping -c 1 $(get_vm_IB_hostname $vm_name))\" ] && echo '$testKey'")"

      if [ "$test_action" == "$testKey" ] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
      fi
    else
      logger "$bootstrap_file already configured"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    fi
  else
    logger "$bootstrap_file already configured"
  fi
}

#$1 vm_name
get_vm_IB_hostname() {
  #TODO improve for other possible clusters and namings
  echo "minerva-ib-${1:(-3)}"
}

get_IB_hostnames() {

  echo -e "
10.0.1.1	minerva-ib-101
10.0.1.2	minerva-ib-102
10.0.1.3	minerva-ib-103
10.0.1.4	minerva-ib-104
10.0.1.5	minerva-ib-105
10.0.1.6	minerva-ib-106
10.0.1.7	minerva-ib-107
10.0.1.8	minerva-ib-108
10.0.1.9	minerva-ib-109
10.0.1.10	minerva-ib-110
10.0.1.11	minerva-ib-111
10.0.1.12	minerva-ib-112
10.0.1.13	minerva-ib-113
10.0.1.14	minerva-ib-114
10.0.1.15	minerva-ib-115
10.0.1.16	minerva-ib-116
10.0.1.17	minerva-ib-117
10.0.1.18	minerva-ib-118
"

}