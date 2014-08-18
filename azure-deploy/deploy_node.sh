#!/bin/bash

startTime="$(date +%s)"

#load init and common functions
type="node"
source "common.sh"

vm_check_create "$vm_name" "$vm_ssh_port"
wait_vm_ready "$vm_name"

vm_check_attach_disks "$vm_name"

#bootstrap VM
vm_set_ssh



#parallel Node config
#cluster_initialize_disks

#master config
#vm_set_master_crontab
#vm_set_master_forer


elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."