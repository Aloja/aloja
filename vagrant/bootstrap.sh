#!/usr/bin/env bash

#rm -rf /var/www
#ln -fs /vagrant/workspace /var/www
#

#install puppet modules
[ -d /etc/puppet/modules ] || mkdir -p /etc/puppet/modules
for module in "puppetlabs-apt" "puppetlabs-mysql" ; do
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

