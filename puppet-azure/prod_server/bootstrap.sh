#!/usr/bin/env bash

#rm -rf /var/www
#ln -fs /vagrant/workspace /var/www
#

#passwordless login to localhost
if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
    dpkg -i /tmp/puppetlabs-release-stable.deb && \
    apt-get update && \
    apt-get install puppet puppet-common hiera facter virt-what lsb-release -y --force-yes
fi

cp -R modules/* /etc/puppet/modules

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
  puppet module install "$module"
done

puppet apply --modulepath=/etc/puppet/modules manifests/init.pp --environment=prod

if [ ! -z $1 ]; then
	if [ "$1" == "execs" ]; then
		tar -xvf execs.sql.tar.gz
		mysql -uroot -p aloja2 < execs.sql
	else
		/bin/bash updategitbranch.sh $1
		retcode=$?
		if [ "$retcode" -ne "0" ]; then
			exit	
		fi
		if [ ! -z $2 ] && [ "$2" == "execs" ]; then
			tar -xvf execs.sql.tar.gz
			mysqlshow -uroot aloja2
			retcode=$?
			if [ "$retcode" -ne "0" ]; then
				mysql -uroot -e "create database aloja2;"
			fi
			mysql -uroot aloja2 < execs.sql
		fi
	fi
fi

echo "Chaning /var/www permissions"
chown -R www-data.www-data /var/www
chmod -R 755 /var/www
