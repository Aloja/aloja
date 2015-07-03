CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/openstack.sh"

get_extra_fstab() {

  #for clusters with SSDs
  if [ "$vmSize" == "io1-15" ] || [ "$vmSize" == "io1-30" ] ; then

    local system_ssd="$homePrefixAloja/$userAloja/tmp"
    vm_execute "mkdir -p $system_ssd"

    vm_execute "
sudo parted -s /dev/xvde -- mklabel gpt mkpart primary 0% 100% > /dev/null 2>&1;
sudo mkfs -t ext4 -m 1 -O dir_index,extent,sparse_super -F /dev/xvde1 > /dev/null 2>&1;"  #avoid stdout

    local create_string="
/dev/xvde1       /scratch/ssd/1  auto    defaults,nobootwait,noatime,nodiratime 0       2
$system_ssd       /scratch/ssd/2    none bind,nobootwait 0 0

"
  fi

  echo -e "$create_string"
}

get_extra_mount_disks() {
  #for clusters with SSDs
  if [ "$vmSize" == "io1-15" ] || [ "$vmSize" == "io1-30" ] ; then
    echo -e "sudo mkdir -p /scratch/ssd/{1..2};"
  fi
}
