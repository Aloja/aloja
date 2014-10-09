#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

logger "Connecting to MASTER node"

for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"
  vm_ssh_port="2${clusterID}${vm_id}" #for Azure

  node_connect "$vm_name"
  break #just connect to the master node (first one)
done

