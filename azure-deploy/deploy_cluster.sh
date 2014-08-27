#!/bin/bash

#load init and common functions
source "azure_common.sh"

Sequential Node deploy
for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"
  vm_ssh_port="2${clusterID}${vm_id}"

  #test first if machines accessible via SSH
  if ! wait_vm_ssh_ready "1" ; then
    vm_check_create "$vm_name" "$vm_ssh_port"
    wait_vm_ready "$vm_name"

    vm_check_attach_disks "$vm_name"

    #wait for ssh to be ready
    wait_vm_ssh_ready

  #make sure the correct number of disks is innitialized
  elif ! vm_test_initiallize_disks ; then
    vm_check_attach_disks "$vm_name"
  fi

  #bootstrap the VM
  vm_set_ssh
  vm_install_base_packages
  vm_set_dsh
  vm_set_dot_files &

done

#parallel Node config
cluster_initialize_disks

#master config
vm_set_master_crontab
vm_set_master_forer &

#extra command in case any
[ ! -z "$extraCommands" ] && vm_execute "$extraCommands"

elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."