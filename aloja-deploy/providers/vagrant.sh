#the default SSH host override to avoid using hosts file, we translate aloja-web to the internal IP
get_ssh_host() {
 echo "127.0.0.1"
}

#the default key override
get_ssh_key() {
  if [ "$vm_name" == "aloja-web" ] ; then
    echo "$CONF_DIR/../../aloja-deploy/providers/vagrant_insecure_key_new" #TODO make the same
  else
    echo "$CONF_DIR/../../aloja-deploy/providers/vagrant_insecure_key"
  fi
}

#vm_name must be set, override when needed ie., azure,...
get_vm_ssh_port() {
  local node_ssh_port=""
  local vagrant_cluster_prefix="2222"

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

  if [ -d  "/vagrant" ] ; then
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

#overwrite if different in your provider
get_repo_path(){
  echo "/vagrant"
}

vm_set_ssh() {
  : #not needed
}

#$1 vm_name
wait_vm_ready() {
  : #not needed
}

#wait_vm_ssh_ready() {
#  : #not needed
#}

vm_initialize_disks() {
  : #not needed
}

vm_mount_disks() {
  : #not needed
}