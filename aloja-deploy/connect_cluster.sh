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
source include/include_deploy.sh

logger "Connecting to MASTER node"

[ ! "$vm_name" ] && vm_name="$(get_master_name)" #edit to connect to a different node
vm_ssh_port="$(get_vm_ssh_port)"
logger "VM $vm_name"
node_connect "$vm_name"