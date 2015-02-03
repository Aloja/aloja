#!/bin/bash

#on the devel machine
init_folder=${1:-.}


cd "$init_folder"

echo "Starting on $init_folder"

#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386235848 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205102128&period=560'>wordcount conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 560 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386236655 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205103332&period=643'>sort conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 643 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386237990 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205104807&period=1103'>terasort conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 1103 s.
#20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256/log_20131205_091834_conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256.log:SENDING: hibench.runs 1386239322 <a href='http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20131205110933&period=1149'>kmeans conf_IB_SSD_b_m12_i10_r1_I65536_c0_z256</a> <strong>Time:</strong> 1149 s.

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
substr(parts[7],2)"," \
substr(parts[8],2)"," \
substr(parts[9],2)"," \
substr(parts[10],2)"," \
substr(parts[11],2)"," \
substr(parts[12],2)\
} \
' )"

echo "$csv"

echo "$csv" > "./table_db.csv"


