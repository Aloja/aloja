#!/bin/bash

host1="minerva-1001"
host2="minerva-1002"
host3="minerva-1003"
host4="minerva-1004"

DSH="dsh -m $host1,$host2,$host3,$host4"

/scratch/ssd/npoggi/hadoop-hibench_3/aplic/hadoop-1.0.3/bin/stop-all.sh
/scratch/hdd/npoggi/hadoop-hibench_3/aplic/hadoop-1.0.3/bin/stop-all.sh

$DSH "rm -rf /scratch/ssd/npoggi/hadoo*" |sort
$DSH "rm -rf /scratch/hdd/npoggi/hadoo*" |sort
$DSH "rm -rf /users/scratch/npoggi/hadoop*" |sort
$DSH "pkill -9 java" |sort
$DSH "pkill -9 vmstat" |sort
$DSH "pkill -9 bwm-ng" |sort
$DSH "pkill -9 sadc" |sort
ssh_tunnel="ssh -N -L minerva-1001:30070:minerva-1001-ib0:30070 -L minerva-1001:30030:minerva-1001-ib0:30030 minerva-1001"
$DSH "pkill -9 \"$ssh_tunnel\""
