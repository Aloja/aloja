#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

logger "Connecting to MASTER node"

for vm_name in $(get_node_names) ; do #pad the sequence with 0s

  vm_ssh_port="$(get_vm_ssh_port)"

  node_connect "$vm_name"
  break #just connect to the master node (first one)
done

