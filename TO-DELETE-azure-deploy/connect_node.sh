#!/bin/bash

#load init and common functions
type="node"
source "azure_common.sh"

echo "Connecting to subscription $subscriptionID, with details: ${user}@${dnsName}.cloudapp.net -p $vm_ssh_port -i ../secure/keys/myPrivateKey.key"
ssh -i "../secure/keys/myPrivateKey.key" "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
