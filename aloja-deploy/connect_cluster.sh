#!/bin/bash

#load init and common functions
type="cluster"
source include/include_deploy.sh

logger "Connecting to MASTER node"

vm_name="$(get_master_name)" #edit to connect to a different node
vm_ssh_port="$(get_vm_ssh_port)"
node_connect "$vm_name"