#!/bin/bash

if [ "$#" -ne 1 ]; then
	echo "Usage: run_rshdi.sh clustername"
	exit	
fi

clusterName=$1

HDD="/home/pristine"
DSH="dsh -aM -c"


if [ ! -d /logs ]; then
	sudo mkdir /logs
	sudo chown -R pristine.pristine /logs
	chmod 777 /logs -R
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
 $DSH "rm $HDD/vmstat.log $HDD/bwm.log $HDD/sar-output.sar"

  $DSH "vmstat -n 1 >> $HDD/vmstat-`hostname`.log &" 2>&1
  $DSH "bwm-ng -o csv -I eth1 -u bytes -t 1000 >> $HDD/bwm-`hostname`.log &" 2>&1
  $DSH "sar -o $HDD/sar-output-`hostname`.sar 1 > /dev/null 2>&1 &" 2>&1

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
	logger "Retrieving logs"
	mkdir -m 777 "/logs/$1"
	sudo su hdfs -c "hdfs dfs -copyToLocal /mr-history /logs/$1"
	$DSH "scp -r $HDD/vmstat-* localhost:/logs/$1" 2>&1
	$DSH "scp -r $HDD/bwm-* localhost:/logs/$1" 2>&1
	$DSH "scp -r $HDD/sar-output-* localhost:/logs/$1" 2>&1
}

installIfNotInstalled "sysstat"
installIfNotInstalled "bwm-ng"
installDsh

restart_monit
logger "Starting run of teragen"
hdfs dfs -rm -r 100GB-terasort-input
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar teragen 1000 100GB-terasort-input
logger "Starting run of terasort"
hdfs dfs -rm -r 100GB-terasort-output
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar terasort 100GB-terasort-input 100GB-terasort-output
logger "Terasort ended"
stop_monit

collect_logs "$clusterName-terasort-`date +%s`"
