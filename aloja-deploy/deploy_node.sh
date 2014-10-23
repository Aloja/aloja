#!/bin/bash

#load init and common functions
type="node"
source "include/include.sh"

vm_create_node

wait $! #wait for the provisioning to be ready

logger "All done, took $(getElapsedTime startTime) seconds."