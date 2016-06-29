#!/bin/bash

#load init and common functions
type="cluster"
source include/include_deploy.sh

if [ "$clusterType" != "PaaS" ]; then
 #Sequential Node deploy

 for vm_name in $(get_node_names) ; do

  logger "Atempting to delete node $vm_name..."
  node_delete "$vm_name"

 done
else
  node_delete "$clusterName"
fi

wait #wait for background processes
logger "All done, took $(getElapsedTime startTime) seconds."
