#!/bin/bash

#load init and common functions
type="node"
source "include/include.sh"

vm_create_node

elapsedTime="$(( $(date +%s) - startTime ))"
logger "All done, took $elapsedTime seconds."