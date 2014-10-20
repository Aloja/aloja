#!/bin/bash

#load init and common functions
type="node"
source "include/include.sh"

vm_create_node

logger "All done, took $(getElapsedTime) seconds."