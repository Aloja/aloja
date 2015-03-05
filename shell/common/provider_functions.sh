###These are just a function list that should be implemented if necessary in the provider

vm_exists() {
  logger "WARNING: Function vm_exists not implemented or not necessary for provider"
}

# $1 vm name
vm_create() {
  logger "WARNING: Function vm_create not implemented or not necessary for provider"
}

# $1 vm name
vm_start() {
  logger "WARNING: Function vm_start not implemented or not necessary for provider"
}

# $1 vm name
vm_reboot() {
  logger "WARNING: Function vm_reboot not implemented or not necessary for provider"
}

vm_set_details() {
  logger "WARNING: Function vm_set_details not implemented or not necessary for provider"
}

vm_get_status() {
  logger "WARNING: Function vm_get_status not implemented or not necessary for provider"
}

number_of_attached_disks() {
  logger "WARNING: Function number_of_attached_disks not implemented or not necessary for provider"
}

vm_attach_new_disk() {
  logger "WARNING: Function vm_attach_new_disk not implemented or not necessary for provider"
}

vm_execute() {
  logger "WARNING: Function vm_execute not implemented or not necessary for provider"
}

vm_local_scp() {
  logger "WARNING: Function vm_local_scp not implemented or not necessary for provider"
}

vm_rsync() {
  logger "WARNING: Function vm_local_scp not implemented or not necessary for provider"
}

vm_initial_bootstrap() {
  logger "WARNING: Function vm_initial_bootstrap not implemented or not necessary for provider"
}

#$1 $endpoints list $2 end1 $3 end2
vm_check_endpoint_exists() {
	logger "WARNING: Function vm_check_endpoint_exists not implemented or not necessary for provider"
}

vm_endpoints_create() {
	logger "WARNING: Function vm_endpoints_create not implemented or not necessary for provider"
}

vm_final_bootstrap() {
  logger "WARNING: Function vm_final_bootstrap not implemented or not necessary for provider"
}

###cluster functions
cluster_final_boostrap() {
  logger "WARNING: Function cluster_final_boostrap not implemented or not necessary for provider"
}

###for executables

node_connect() {

  logger "Connecting to $vm_name using SSH keys"
  vm_connect

  if [ ! -z "$failed_ssh_keys" ] ; then
    logger "Connecting to $vm_name using password"
    vm_connect "use_password"
  fi
}

#1 $node_name
node_delete() {
  logger "WARNING: Function node_delete not implemented or not necessary for provider"
}

#1 $node_name
node_stop() {
  logger "WARNING: Function node_stop not implemented or not necessary for provider"
}

#1 $node_name
node_start() {
  logger "WARNING: Function node_start not implemented or not necessary for provider"
}


### gets

get_extra_fstab() {
  : # not needed by default and no warning
}

get_extra_mount_disks() {
  : # not needed by default and no warning
}