#!/bin/bash

#load init and common functions
type="node"
source "providers/openstack_common.sh"

nova delete "$vm_name"

logger "listing server volumes"
nova volume-list|grep " DISK_$vm_name"

logger "Remember to manually delete non-used volumes"