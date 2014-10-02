#!/bin/bash

#load init and common functions
type="node"
source "openstack_common.sh"

if [ -z "${nodeIP[$vm_name]}" ] ; then
  nodeIP[$vm_name]="$(vm_get_IP)"
fi

echo "Connecting to Rackspace, with details: ${user}@${nodeIP[$vm_name]}"
ssh -i "../secure/keys/id_rsa" "$user"@"${nodeIP[$vm_name]}"
