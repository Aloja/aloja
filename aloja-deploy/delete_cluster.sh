#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

if [ "$defaultProvider" != "hdinsight" ]; then
 #Sequential Node deploy
 for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"

  logger "Atempting to delete node $vm_name..."
  node_delete "$vm_name"

 done
else
  node_delete "$clusterName"
fi

logger "All done, took $(getElapsedTime startTime) seconds."
