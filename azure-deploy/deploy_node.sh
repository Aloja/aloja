#!/bin/bash

#load init and common functions
type="node"
source "azure_common.sh"

vm_check_create "$vm_name" "$vm_ssh_port"
wait_vm_ready "$vm_name"

vm_check_attach_disks "$vm_name"

#bootstrap VM

#TODO fix ssh takes some time to appear need to test for it
sleep 3

vm_set_ssh
vm_initialize_disks


[ ! -z "$extraCommands" ] && vm_execute "$extraCommands"

elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."