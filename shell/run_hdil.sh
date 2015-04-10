#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Usage: run_rshdi.sh clustername numberOfNodes"
	exit	
fi

clusterName=$1
numberOfNodes=$2

HDD="/home/pristine/share"
DSH="dsh -f machines -cM"
JAR_LOCATION="/home/pristine/hadoop-mapreduce-examples.jar"


if [ ! -d $HDD/logs ]; then
	sudo mkdir $HDD/logs
	sudo chown -R pristine.pristine $HDD/logs
	chmod 777 $HDD/logs -R
fi

installIfNotInstalled() {
 if $DSH "yum list installed \"$@\"" > /dev/null 2>&1; then
    logger "Package $@ already installed"
  else
    $DSH "yum install -y -q \"$@\""
    logger "Package $@ installed"
  fi
}

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
		
	echo -e "Host *\nIdentityFile = /home/pristine/id_rsa" > .ssh/config
	
	logger "DSH successfully installed"
 fi
}

restart_monit(){
 
  logger "Restart Monit"

  stop_monit
 $DSH "rm $1/vmstat.log $1/bwm.log $1/sar-output.sar"

  $DSH "vmstat -n 1 >> $1/vmstat-`hostname`.log &" 2>&1
  $DSH "bwm-ng -o csv -I eth1 -u bytes -t 1000 >> $1/bwm-`hostname`.log &" 2>&1
  $DSH "sar -o $1/sar-output-`hostname`.sar 1 > /dev/null 2>&1 &" 2>&1

  logger "Monit ready"
}

stop_monit(){
  logger "Stop monit"

  $DSH "killall -9 vmstat" #2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 bwm-ng" #2>&1 |tee -a $LOG_PATH
  $DSH "killall -9 sar" #2>&1 >> $LOG_PATH

  logger "Stop monit ready"
}

collect_logs(){
	logger "Retrieving haddop logs"
	sudo su hdfs -c "hdfs dfs -copyToLocal /mr-history $1"
}

#installIfNotInstalled "sysstat"
#installIfNotInstalled "bwm-ng"
#installDsh

exec_dir="2014_alojahdil$numberOfNodes-terasort-`date %s`"
if [ ! -d $HDD/logs/$exec_dir ]; then
	mkdir $HDD/logs/$exec_dir
fi

restart_monit "${HDD}/logs/${exec_dir}"
logger "Starting run of teragen"
hdfs dfs -rm -r 100GB-terasort-input
hadoop jar $JAR_LOCATION teragen 1000 100GB-terasort-input | tee -a "${HDD}/logs/${exec_dir}"
logger "Starting run of terasort"
hdfs dfs -rm -r 100GB-terasort-output
hadoop jar $JAR_LOCATION terasort 100GB-terasort-input 100GB-terasort-output | tee -a "${HDD}/logs/${exec_dir}"
logger "Terasort ended"
stop_monit

collect_logs "${HDD}/logs/${exec_dir}"