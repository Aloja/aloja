CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR/common.sh"

#test variables
[ -z "$testKey" ] && { echo "testKey not set! Exiting"; exit 1; }


#test and load cluster config

clusterConfigFilePath="$CUR_DIR/../conf"

[ ! -f "$clusterConfigFilePath/$clusterConfigFile" ] && { echo "$clusterConfigFilePath/$clusterConfigFile is not a file." ; exit 1;}

#load cluster or node config second
source "$clusterConfigFilePath/$clusterConfigFile"


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
  for drive_letter in "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" ; do
    create_string="$create_string
sudo parted -s /dev/sd${drive_letter} -- mklabel gpt mkpart primary 0% 100%;
sudo mkfs.ext4 -F /dev/sd${drive_letter}1;"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
}

#requires $create_string to be defined
get_initizalize_disks_test() {
  create_string="echo ''"
  num_drives="1"
  for drive_letter in "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" ; do
    create_string="$create_string && lsblk|grep sd${drive_letter}"
    #break when we have the required number
    [[ "$num_drives" -ge "$attachedVolumes" ]] && break
    num_drives="$((num_drives+1))"
  done
  create_string="$create_string && echo '$testKey'"
}

#requires $create_string to be defined
get_mount_disks() {
  if [[ "$attachedVolumes" -gt "12" ]] ; then
    logger "ERROR, function only supports up to 12 volumes"
    exit 1;
  fi

  if [ "$subscriptionID" == "8869e7b1-1d63-4c82-ad1e-a4eace52a8b4" ] && [ "$virtualNetworkName" == "west-europe-net" ] ; then
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
  for drive_letter in "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" ; do
    create_string="$create_string
/dev/sd${drive_letter}1       /scratch/attached/1  auto    defaults,nobootwait 0       2"
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


vm_test_initiallize_disks() {

  logger "Checking if the correct number of disks are atttached to VM $vm_name"

  create_string=""
  get_initizalize_disks_test

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