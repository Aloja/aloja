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

##MySQL data to attached disk
if [ ! -d "/scratch/attached/1/mysql" ]; then
	cp /var/lib/mysql /scratch/attached/1/ -R
	cp usr.sbin.mysqld /etc/apparmor.d/usr.sbin.mysqld
	chown mysql.mysql /scratch/attached/1/mysql -R
	chmod 775 /scratch/attached/1/mysql -R
	service apparmor restart
	service mysql restart
		
	if [ "$?" -ne "0" ]; then
		echo "Moving MySQL data to attached disk failed!"
	fi
fi

add_execs() {
	tar -xvf execs.sql.tar.gz
	mysqlshow -uroot aloja2
	retcode=$?
	if [ "$retcode" -ne "0" ]; then
		mysql -uroot -e "create database aloja2;"
	fi
	mysql -uroot aloja2 < execs.sql	
}

##Add execs to MySQL AND/OR change default git branch
if [ ! -z $1 ]; then
	if [ "$1" == "execs" ]; then
		add_execs
	else
		/bin/bash updategitbranch.sh $1
		retcode=$?
		if [ "$retcode" -ne "0" ]; then
			exit	
		fi
		if [ ! -z $2 ] && [ "$2" == "execs" ]; then
			add_execs
		fi
	fi
fi

echo "Chaning /var/www permissions"
chown -R www-data.www-data /var/www
chmod -R 755 /var/www
