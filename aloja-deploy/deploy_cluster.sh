#!/bin/bash

#############################################################
#Read options, currently only selecting one vm from a cluster
OPTIND=1 #A POSIX variable, reset in case getopts has been used previously in the shell.
while getopts "n:" opt; do
    case "$opt" in
    n)
      vm_name=$OPTARG
      ;;
    esac
done
shift $((OPTIND-1))
[ "$1" = "--" ] && shift
#############################################################

#load init and common functions
type="cluster"
deploy_include_path="include/include_deploy.sh"

#Vagrant requires a different path
if [ -d "/vagrant" ] ; then
  deploy_include_path="/vagrant/aloja-deploy/include/include_deploy.sh"
fi

#load init and common functions
source "$deploy_include_path"

#All cluster nodes sequentially
if [ "$defaultProvider" == "splicemachine" ] || [[ "$clusterType" != "PaaS" || "$defaultProvider" == "google" || "$defaultProvider" == "amazonemr" ]] && [ ! "$vm_name" ]; then

  cluster_do_pre

  for vm_name in $(get_node_names) ; do #pad the sequence with 0s

    vm_ssh_port="$(get_ssh_port)"
	
    #if [ "$cloud_provider" != "azure" ] ; then #create hosts in paralell
    #  vm_create_node &
    #else

      vm_create_node   #one by one creation, provision in parallel
    #fi

  done
	
  wait #wait for the last one in case we launch in parallel

  #parallel Node config
  cluster_parallel_config
else
  #If PaaS or only one node is selected
  vm_create_node
fi

wait #for background processes

#master config to execute benchmarks
[ ! -z "$queueJobs" ] && cluster_queue_jobs


logger "All done, took $(getElapsedTime startTime) seconds."
