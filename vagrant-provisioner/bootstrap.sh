#!/bin/bash

#use closest mirror
sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list


#install puppet if not present
if [ -d $(puppet --version >/dev/null 2>&1) ] ; then
  apt-get update && apt-get install -y wget
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
      dpkg -i /tmp/puppetlabs-release-stable.deb && \
      apt-get update && \
      apt-get install puppet puppet-common hiera facter virt-what lsb-release  -y --force-yes && \
      rm -f /tmp/*.deb
fi

#install puppet modules in case necessary
[ -d /etc/puppet/modules ] || mkdir -p /etc/puppet/modules
for module in "" ; do
  (puppet module list | grep "$module") || puppet module install "$module"
done

