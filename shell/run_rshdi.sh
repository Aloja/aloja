#!/bin/bash

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONF_DIR="$CUR_DIR_TMP/common/"
source "$CUR_DIR_TMP/common/include_benchmarks.sh"

if [ "$#" -ne 1 ]; then
	echo "Usage: run_rshdi.sh clustername"
	exit	
fi

clusterName=$1

HDD="/home/pristine"

DSH="dsh -aM -c"


if [ ! -d /logs ]; then
	sudo mkdir /logs
fi

installIfNotInstalled() {
 if $DSH "yum list installed \"$@\"" > /dev/null 2>&1; then
     echo "Package $@ already installed"
  else
    $DSH "sudo yum install \"$@\""
    echo "Package $@ installed"
  fi
}

installDsh() {
  if [ ! -e /usr/local/bin/dsh ]; then
    echo "Installing DSH"
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
 fi
}

restart_monit(){
  logger "Restart Monit"

  stop_monit
 $DSH "rm $HDD/vmstat.log $HDD/bwm.log $HDD/sar-output.sar"

  $DSH "vmstat -n 1 >> $HDD/vmstat-`hostname`.log &" 2>&1 |tee -a $LOG_PATH
  $DSH "bwm-ng -o csv -I eth1 -u bytes -t 1000 >> $HDD/bwm-`hostname`.log &" 2>&1 |tee -a $LOG_PATH
  $DSH "sar -o $HDD/sar-output-`hostname`.sar 1 > /dev/null 2>&1 &" 2>&1 |tee -a $LOG_PATH

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
	mkdir "/logs/$1"
	sudo su hdfs -c "hdfs dfs -copyToLocal /mr-history /logs/$1"
	$DSH "scp -r $HDD/vmstat-* localhost:/logs/$1" 2>&1 | tee -a $LOG_PATH
	$DSH "scp -r $HDD/bwm-* localhost:/logs/$1" 2>&1 | tee -a $LOG_PATH
	$DSH "scp -r $HDD/sar-output-* localhost:/logs/$1" 2>&1 | tee -a $LOG_PATH	
}

installIfNotInstalled "sysstat"
installIfNotInstalled "bwm-ng"
installDsh

restart_monit
hadoop dfs -rmr 100GB-terasort-input
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar teragen 1000000000 100GB-terasort-input
hadoop dfs -rmr 100GB-terasort-output
hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar terasort 100GB-terasort-input 100GB-terasort-output
stop_monit

collect_logs "$clusterName-terasort-`date +%s`"
