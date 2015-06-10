#!/usr/bin/env bash

# local DNS
cat /vagrant/files/vagrant_cluster/hosts > /etc/hosts

# passwordless SSH
cp /vagrant/files/vagrant_cluster/{id_rsa,id_rsa.pub} /home/vagrant/.ssh/
chmod 600 /home/vagrant/.ssh/id_rsa
chown vagrant:vagrant /home/vagrant/.ssh/{id_rsa,id_rsa.pub}
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

# packages
packages=("bc" "dsh" "sysstat" "wamerican" "build-essential" "curl")
apt-get update
for package in "${packages[@]}"; do
	if ! which $package > /dev/null; then
	  apt-get install $package -y --force-yes
	fi
done

# folders
mkdir -p /scratch/local
chmod 777 /scratch/local
su vagrant <<EOF
mkdir -p /vagrant/workspace/blobs/share
ln -s -f -n /vagrant/workspace/blobs/share /home/vagrant/share
ln -s -f -n /vagrant/workspace /home/vagrant/workspace
EOF

# download external files
su vagrant <<EOF
if [ ! -f /vagrant/workspace/blobs/aplic.tar.bz2 ]; then
	wget -nv -O /vagrant/workspace/blobs/aplic.tar.bz2 https://www.dropbox.com/s/ywxqsfs784sk3e4/aplic.tar.bz2
fi
if [ ! -d /vagrant/workspace/blobs/share/aplic ]; then
	tar -xf /vagrant/workspace/blobs/aplic.tar.bz2 -C /vagrant/workspace/blobs/share
fi
EOF