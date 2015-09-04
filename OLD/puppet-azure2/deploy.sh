#!/bin/bash

#gem install azure net-ssh net-scp winrm highline tilt

#install puppet modules in case necessary
[ -d /etc/puppet/modules ] || mkdir -p /etc/puppet/modules
for module in "msopentech-windowsazure" ; do
  (puppet module list | grep "$module") || puppet module install "$module"
done

puppet azure_vm images --management-certificate=/home/npoggi/workspace/aloja/vagrant-provisioner/keys/aloja-hadoop/management.pem \
                       --azure-subscription-id=8869e7b1-1d63-4c82-ad1e-a4eace52a8b4
#--image b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-13_04-amd64-server-20130501-en-us-30GB --location 'west us' \
#--vm-name vmname --vm-user username --password ComplexPassword

