#!/bin/bash

if [ "$#" -lt 2 ]; then
	echo "Illegal number of parameters";
	echo "Usage: getconf_param -f file  [-p [param_name,]]";                    
fi;

file=$2

if [ ! -f $file ]; then
	echo "File doesn't exists!";
	exit;
fi; 

if [ "$#" -eq 4 ]; then
	echo $4 | tr ',' '\n' | while read param; do
		echo $param=$(xmllint --xpath "string(//property[name=\"$param\"]/value)" $file)	
	done;
else
	countParams=$(xmllint --xpath "count(//property)" $file);
	for i in $(seq $countParams)
	do
		echo $(xmllint --xpath "string(//property[$i]/name)" $file)=$(xmllint --xpath "string(//property[$i]/value)" $file)
	done;
fi;