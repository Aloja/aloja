#!/bin/bash
CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CONF_DIR/common/common.sh"

installDsh() {
  if [ ! -e /usr/local/bin/dsh ]; then
    logger "Installing DSH"
    wget http://www.netfort.gr.jp/~dancer/software/downloads/libdshconfig-0.20.10.cvs.1.tar.gz
    tar xfz libdshconfig*.tar.gz 
	cd libdshconfig-*
	./configure ; make
	sudo make install
		
	wget http://www.netfort.gr.jp/~dancer/software/downloads/dsh-0.22.0.tar.gz
	tar xfz dsh-0.22.0.tar.gz
	 cd dsh-*
	./configure ; make 
	sudo make install
		
	sudo sed -i 's/remoteshell\ \=rsh/remoteshell\ \=ssh/' /usr/local/etc/dsh.conf
		
	sudo echo 'remoteshellopt=-oStrictHostKeyChecking=no' >> /usr/local/etc/dsh.conf
		
	#echo -e "Host *\nIdentityFile = /home/pristine/.ssh/id_rsa" > .ssh/config
	
	logger "DSH successfully installed"
 fi
}

sudo sed -i.bak 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers
installDsh
cp /etc/hadoop/conf/slaves /home/pristine/slaves; cp /home/pristine/slaves /home/pristine/machines && echo master-1 >> /home/pristine/machines
wget http://pagesperso-orange.fr/sebastien.godard/sysstat-10.0.3.tar.bz2
tar -jxf sysstat-10.0.3.tar.bz2
cd sysstat-10.0.3
./configure
make
sudo make install
sudo mv sadf /usr/bin
sudo mv sar /usr/bin
sudo mv sadc /usr/bin
sudo mv iostat /usr/bin
cd ..

#sudo yum -y -q install pdsh pssh git
#pscp.pssh -h slaves .ssh/{config,id_rsa,id_rsa.pub,myPrivateKey.key} /home/pristine/.ssh/
#dsh -M -f machines -Mc -- sudo yum -y -q install bwm-ng sshfs sysstat ntp
#dsh -f slaves -Mc -- 'mkdir -p share'
#dsh -f slaves -cM -- echo \"'\`cat /etc/fstab | grep aloja-us.cloudapp\`' | sudo tee -a /etc/fstab > /dev/null\"
#dsh -f slaves -cM -- sudo mount -a
#dsh -f slaves -cM -- \"sshfs 'pristine@aloja.cloudapp.net:/home/pristine/share' '/home/pristine/share'\"
#cd share; git clone https://github.com/Aloja/aloja.git .
#dsh -f slaves -cM -- \"sudo echo $(hostname -i) headnode0 | sudo tee --append /etc/hosts > /dev/null\"
#hdfs dfs -copyToLocal /example/jars/hadoop-mapreduce-examples.jar hadoop-mapreduce-examples.jar
#dsh -M -f machines -Mc -- 'sudo chmod 775 /mnt'
#dsh -M -f machines -Mc -- 'sudo chown root.pristine /mnt'
