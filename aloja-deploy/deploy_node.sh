#!/bin/bash

type="node"
deploy_include_path="include/include_deploy.sh"

#Vagrant requires a different path
if [ -d "/vagrant" ] ; then
  deploy_include_path="/vagrant/aloja-deploy/include/include_deploy.sh"
fi

#load init and common functions
source "$deploy_include_path"


vm_create_node

wait #wait for the provisioning to be ready

logger "All done, took $(getElapsedTime startTime) seconds."
