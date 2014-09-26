#!/bin/bash

#load init and common functions
type="node"
source "azure_common.sh"

ssh -i "../secure/keys/myPrivateKey.key" -q -o connectTimeout=5 "$user"@"$dnsName".cloudapp.net -p "$vm_ssh_port"
