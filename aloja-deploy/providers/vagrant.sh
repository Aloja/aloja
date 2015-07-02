#the default SSH host override to avoid using hosts file, we translate aloja-web to the internal IP
get_ssh_host() {
 echo "127.0.0.1"
}

#the default key override
get_ssh_key() {
 echo "$CONF_DIR/../../aloja-deploy/providers/vagrant_insecure_key"
}

#default port, override to change i.e. in Azure
get_ssh_port() {
  if [ -d  "/vagrant" ] ; then
    echo "22" #from inside the vagrant box
  else
    echo "$vm_ssh_port" #default port for the vagrant vm
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