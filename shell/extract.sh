#!/bin/bash
#echo "starting"

#on the devel machine
init_folder=${1:-.}

if [[ -z $1 ]] ; then
  DEV=1
  echo "Dev mode: init folder $init_folder"
  pwd
fi

if [[ -z $DEV ]] ; then
  #dont know why keeps changing
  #chmod  755  /data/hadoop/jobs
  sudo chown -R npoggi: /data/hadoop/jobs
  sudo chmod -R 777 /data/hadoop/jobs

  #sync jobs folder from minerva home share
  rsync -aP minerva.bsc.es:/home/npoggi/jobs/var/ /data/hadoop/jobs/
fi

cd "$init_folder"

#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386235848 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205102128&period=560'>wordcount conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 560 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386236655 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205103332&period=643'>sort conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 643 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386237990 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205104807&period=1103'>terasort conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 1103 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386239322 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205110933&period=1149'>kmeans conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 1149 s.


json="$(grep  --include=log*.log -r -e 'href'  201* |grep 8099 |grep -v -e 'prep_' -e 'b_min_' -e 'b_10_'|\
awk ' BEGIN { print "var aDataSet = ["} \
{ pri_bar = (index($1,"/")+1); \
conf = substr($1, 22, (pri_bar-23));
split(conf, parts,"_"); \
if ( $(NF-1) ~  /^[0-9]*$/ && $(NF-1) > 200)  print "[\"" $4 " target=_blank " $5 "</a>" "\",\"" \
$(NF-1) "\",\"" \
conf "\",\"" \
parts[1]"\",\"" \
parts[2]"\",\"" \
parts[4]"\",\"" \
parts[5]"\",\"" \
parts[6]"\",\"" \
parts[7]"\",\"" \
parts[8]"\",\"" \
parts[9]"\",\"" \
"1.0.3" "\",\"" \
"<a target=_blank href=/jobs/" substr($1, 0, (pri_bar-2)) ">files</a>" "\",\"" \
strftime("%Y%m%d_%H%M",$3) \
"\"],"  } \
END { print "];"}' )"

csv="$(grep  --include=log*.log -r -e 'href'  201* |grep 8099 |grep -v -e 'prep_' -e 'b_min_' -e 'b_10_'|\
awk ' BEGIN { print "exec,bench,exe_time,init_time,zabbix_time,zabbix_link,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size"} \
{ pri_bar = (index($1,"/")+1); \
conf = substr($1, 0, (pri_bar-2));\
pri_mas = (index($5,">")-7);\
time_pos = (index($5,"&stime=")+7);\
split(conf, parts,"_"); \
bench = substr($5,(pri_mas+8));\
\
if ( $(NF-1) ~  /^[0-9]*$/ && $(NF-1) > 200)\
print \
conf "/" bench "," \
bench "," \
$(NF-1) "," \
$3 ","\
substr($5,(time_pos),14) "," \
substr($5,7,pri_mas) "," \
parts[4]"," \
parts[5]"," \
parts[6]"," \
parts[7]"," \
parts[8]"," \
parts[9]"," \
parts[10]"," \
parts[11]"," \
parts[12]\
} \
' )"


if [[ ! -z $2 ]] ; then
  echo "$json" > "$2"
  echo "$csv" > "${2:0:-3}.csv"
else
  echo "$csv" > "./table.csv"
  echo "$csv"
fi

if [[ -z $DEV ]] ; then
  sudo chown www-data: /var/www/jobs
  sudo chown -R www-data: /data/hadoop/jobs

  #build html index page
  cd /var/www/datatables/
  php datatable.php 2> /dev/null > /var/www/datatables/index.html
fi

