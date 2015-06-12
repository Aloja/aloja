#!/bin/bash

#load init and common functions
type="node"
source include/include_deploy.sh

vm_finalize

wait #wait for the provisioning to be ready

logger "All done, took $(getElapsedTime startTime) seconds."