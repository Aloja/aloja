#!/bin/bash

#load init and common functions
type="node"
source "azure_common.sh"

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

#boostrap VM
vm_set_ssh
vm_initialize_disks

#extra command in case any
[ ! -z "$extraCommands" ] && vm_execute "$extraCommands"

[ ! -z "$puppet" ] && vm_puppet_apply

elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."