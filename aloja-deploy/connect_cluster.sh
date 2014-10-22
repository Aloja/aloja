#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

logger "Connecting to MASTER node"

vm_name="$(get_master_name)"
vm_ssh_port="$(get_vm_ssh_port)"
node_connect "$vm_name"