#VAGRANT specific functions and globals

#global variables for vagrant, this need to coincide with the ones in Vagrantfile
#TODO, make the Vagrant file read these variables from node and cluster definitions

VAGRANT_HOST="127.0.0.1"
VAGRANT_WEB_IP="192.168.99.2" #do not use .1 to avoid some vagrant warnings
VAGRANT_ipAddrPrefix="192.168.99.1" # IP Address Base for private network
VAGRANT_sshPortPrefix=2222 #prefix port for the different VMs


#checks if the command has been run inside the vagrant VM
inside_vagrant() {
  if [ -d  "/vagrant" ] ; then
    return 0
  else
    return 1
  fi
}

#### start provider customizations

# $1 vm name
vm_exists() {
  logger "INFO: Checking if VM $1 exists..."

  if inside_vagrant || [ ! -z "$(vagrant global-status |grep " $1 ")" ] ; then
    logger "INFO: vagrant $vm_name exists."
    return 0
  else
    return 1
  fi
}

# $1 vm name
vm_start() {
  if ! inside_vagrant ; then
    logger "Starting vagrant VM $1"
    cd $CONF_DIR/../../; vagrant up "$1"; cd -;
  else
    logger "INFO: vagrant VM already started"
  fi
}

# $1 vm name $2 ssh port
vm_create() {
  if ! inside_vagrant ; then
    logger "Starting vagrant VM $1"
    cd $CONF_DIR/../../; vagrant up "$1" --provision; cd -;
  else
    die "called vm_create from inside vagrant box"
  fi
}

# $1 vm name
vm_reboot() {
  if ! inside_vagrant ; then
    logger "INFO: Reloading vagrant VM $1"
    cd $CONF_DIR/../../; vagrant reload "$1"; cd -;
  else
    die "ERROR: cannot reboot/reload vagrant VM $1 from inside the VM"
  fi
}

#1 $vm_name
node_delete() {
  if ! inside_vagrant ; then
    logger "WARNING: Forcing delete of vagrant VM $1"
    cd $CONF_DIR/../../; vagrant destroy -f "$1"; cd -;
  else
    die "ERROR: cannot destroy vagrant VM $1 from inside the VM"
  fi
}

#1 $vm_name
node_stop() {
  if ! inside_vagrant ; then
    logger "INFO: Suspending vagrant VM $1"
    cd $CONF_DIR/../../; vagrant suspend "$1"; cd -;
  else
    die "ERROR: cannot suspend vagrant VM $1 from inside the VM"
  fi
}

#1 $vm_name
node_start() {
  if ! inside_vagrant ; then
    logger "INFO: Starting vagrant VM $1"
    cd $CONF_DIR/../../; vagrant up "$1"; cd -;
  else
    die "ERROR: cannot start vagrant VM $1 from inside the VM"
  fi
}

#$1 vm_name
vm_get_status(){
  if ! inside_vagrant ; then
    echo "$(vagrant global-status |grep " $1 "|cut -d " " -f 5 )"
  else
    die "ERROR: cannot start vagrant VM $1 from inside the VM"
  fi
}

get_OK_status() {
  echo "running"
}


#the default SSH host override to avoid using hosts file, we translate aloja-web to the internal IP
get_ssh_host() {
 echo "$VAGRANT_HOST"
}

#overwrite for vagrant
get_repo_path(){
  echo "/vagrant"
}

#vm_name must be set, override when needed ie., azure,...
get_vm_ssh_port() {
  local node_ssh_port=""
  local vagrant_cluster_prefix="$VAGRANT_sshPortPrefix"

  #for nodes
  if [ "$type" == "node" ] ; then
      local node_ssh_port="$vm_ssh_port"
  #for clusters
  else
    for vm_id in $(seq -f '%02g' 0 "$numberOfNodes") ; do #pad the sequence with 0s
      local vm_name_tmp="${clusterName}-${vm_id}"

      if [ ! -z "$vm_name" ] && [ "$vm_name" == "$vm_name_tmp" ] ; then
        local node_ssh_port="$vagrant_cluster_prefix${vm_id:1}"
        break #just return on match
      fi
    done
  fi

  echo "$node_ssh_port"
}

#default port, override to change i.e. in Azure
get_ssh_port() {
  local vm_ssh_port_tmp=""

  if inside_vagrant ; then
    local vm_ssh_port_tmp="22" #from inside the vagrant box
  else
    local vm_ssh_port_tmp="$(get_vm_ssh_port)" #default port for the vagrant vm
  fi

  if [ "$vm_ssh_port_tmp" ] ; then
    echo "$vm_ssh_port_tmp"
  else
    die "cannot get SSH port for VM $vm_name"
  fi
}

vagrant_link_repo(){
  logger "INFO: Making sure /var/www is linked for the vagrant VM"
  vm_execute "
if [ ! -d '/var/www/aloja-web' ] ; then
  sudo ln -fs /vagrant /var/www
fi"
}

make_hosts_file() {

  local hosts_file="$VAGRANT_WEB_IP\taloja-web"

  #for the aloja-web to know about the cluster IPs
  # TODO needs to be dynamic
  if [ "$type" == "node" ] ; then
    for vm_id in $(seq -f '%02g' 0 "1") ; do #pad the sequence with 0s
      local vm_name_tmp="vagrant-99-${vm_id}"

      local hosts_file="$hosts_file
${VAGRANT_ipAddrPrefix}${vm_id}\t${vm_name_tmp}"
    done
  #for clusters (from config file)
  else
    for vm_id in $(seq -f '%02g' 0 "$numberOfNodes") ; do #pad the sequence with 0s
      local vm_name_tmp="${clusterName}-${vm_id}"

      local hosts_file="$hosts_file
${VAGRANT_ipAddrPrefix}${vm_id}\t${vm_name_tmp}"
    done
  fi

  echo -e "$hosts_file"
}

vm_final_bootstrap() {
  logger "INFO: Finalizing VM $vm_name bootstrap"

  logger "INFO: Checking if to install/update aloja-web/vendor dir"
  install_PHP_vendors

  #currently is run everytime it is executed
  vm_update_hosts_file
}


vm_initialize_disks() {
  : #not needed
}

vm_mount_disks() {
  : #not needed
}

### cluster functions

cluster_final_boostrap() {
  : #not necessary for vagrant (yet)
}


