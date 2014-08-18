#!/bin/bash

startTime="$(date +%s)"

#load init and common functions
source "common.sh"


#Sequential Node deploy
for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"
  vm_ssh_port="2${clusterID}${vm_id}"

  #check storage account

  #vm_check_create "$vm_name" "$vm_ssh_port"
  #wait_vm_ready "$vm_name"

  #TODO not need for master
  #vm_check_attach_disks "$vm_name"

  #bootstrap VM
  #vm_set_ssh
  #vm_install_base_packages
  #vm_set_dsh

done

#parallel Node config
cluster_initialize_disks

#master config
vm_set_master_crontab
vm_set_master_forer


elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."