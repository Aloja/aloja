#!/bin/bash

#load init and common functions
type="cluster"
source include/include_deploy.sh

#Sequential Node deploy
if [ "$clusterType" != "PaaS" ]; then
	for vm_name in $(get_node_names) ; do #pad the sequence with 0s
	
	  vm_ssh_port="$(get_ssh_port)" #for Azure
	
	  #if [ "$cloud_provider" != "azure" ] ; then #create hosts in paralell
	  #  vm_create_node &
	  #else
	    vm_create_node #one by one creation, provision in parallel
	  #fi
	
	done
	
	wait #wait for the last one in case we launch in parallel

	#parallel Node config
	cluster_parallel_config
	
else #If PaaS only run create node once
	vm_create_node
fi


#master config to execute benchmarks
[ ! -z "$queueJobs" ] && cluster_queue_jobs


logger "All done, took $(getElapsedTime startTime) seconds."
