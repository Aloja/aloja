#!/bin/bash

startTime="$(date +%s)"

#check if azure command is installed
if ! azure --version 2>&1 > /dev/null ; then
  echo "azure command not instaled."
  exit 1
fi

#load common functions
source "common.sh"

#load non versioned conf
source "../secure/azure_settings.conf"

#load cluster config
source "cluster_04.conf"


#Sequential Node deploy
for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"
  vm_ssh_port="2${clusterID}${vm_id}"

  #check storage account

  vm_check_create "$vm_name" "$vm_ssh_port"
  wait_vm_ready "$vm_name"

  #TODO not need for master
  vm_check_attach_disks "$vm_name"

  #bootstrap VM
  vm_set_ssh
  vm_install_base_packages
  vm_set_dsh

done

#parallel Node config
cluster_initialize_disks

#master config
vm_set_master_crontab


elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."