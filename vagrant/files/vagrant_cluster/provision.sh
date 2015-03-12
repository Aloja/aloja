#!/usr/bin/env bash

# local DNS
cat /vagrant/files/vagrant_cluster/hosts > /etc/hosts

# passwordless SSH
cp /vagrant/files/vagrant_cluster/{id_rsa,id_rsa.pub} /home/vagrant/.ssh/
chmod 600 /home/vagrant/.ssh/id_rsa
chown vagrant:vagrant /home/vagrant/.ssh/{id_rsa,id_rsa.pub}
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

# packages
packages=("bc" "dsh" "sysstat")
apt-get update
for package in "${packages[@]}"; do
	if ! which $package > /dev/null; then
	  apt-get install $package -y --force-yes
	fi
done

# folders
su vagrant <<EOF
mkdir -p /vagrant/workspace/blobs/share
mkdir -p /vagrant/workspace/blobs/share/jobs_vagrant
ln -s -f -n /vagrant/workspace/blobs/share /home/vagrant/share
mkdir -p /home/vagrant/scratch
ln -s -f -n /vagrant/workspace /home/vagrant/workspace
EOF