#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

#Sequential Node deploy
for vm_id in $(seq -f "%02g" 0 "$numberOfNodes") ; do #pad the sequence with 0s

  vm_name="${clusterName}-${vm_id}"
  vm_ssh_port="2${clusterID}${vm_id}" #for Azure

  #if [ "$cloud_provider" != "azure" ] ; then #create hosts in paralell
  #  vm_create_node &
  #else
    vm_create_node #one by one
  #fi

done

#wait $! #wait for the last one in case we launch in parallel


#parallel Node config
cluster_parallel_config

#master config to execute benchmarks
cluster_queue_jobs


elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."