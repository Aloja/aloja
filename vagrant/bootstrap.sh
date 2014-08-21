#!/usr/bin/env bash

#rm -rf /var/www
#ln -fs /vagrant/workspace /var/www
#
if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
    dpkg -i /tmp/puppetlabs-release-stable.deb && \
    apt-get update && \
    apt-get install puppet puppet-common hiera facter virt-what lsb-release -y --force-yes
fi

if ! which zip > /dev/null; then
  apt-get install zip -y --force-yes
fi

if ! which git > /dev/null; then
  apt-get install git -y --force-yes
fi

if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
     dpkg -i /tmp/puppetlabs-release-stable.deb && \
     apt-get update && \
     apt-get install puppet puppet-common hiera facter virt-what lsb-release  -y --force-yes
fi

if ! which git > /dev/null; then
  apt-get install git -y --force-yes
fi

#install puppet modules
[ -d /etc/puppet/modules ] || mkdir -p /etc/puppet/modules
for module in "puppetlabs-apt" "puppetlabs-mysql" "puppetlabs-vcsrepo" "maxchk-varnish" "rodjek-logrotate"; do
  (puppet module list | grep "$module") || puppet module install "$module"
done
#php 5.5 fpm
#apt-get install -y python-software-properties
#add-apt-repository -y ppa:ondrej/php5
#apt-get update

#upgrade without prompts
#DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

#apt-get install -y mysql-client
# apache2
#touch ~/bootstraped.txt

