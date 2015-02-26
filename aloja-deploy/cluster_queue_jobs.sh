#!/bin/bash

#load init and common functions
type="cluster"
source "include/include.sh"

#get cluster master details
vm_name="$(get_master_name)"
vm_ssh_port="$(get_vm_ssh_port)"
cluster_queue_jobs

logger "All done, took $(getElapsedTime startTime) seconds."