#!/bin/bash
if [ "$#" -lt "1" ]; then
	echo "Usage: updategitbranch.sh branch"
	exit
fi

cd /var/www		
git fetch -a
git reset --hard HEAD
echo "Checking out branch $1"
git checkout $1
echo "Pulling origin $1"
git pull origin $1
retcode=$?
if [ "$retcode" -ne "0" ]; then
	echo "An error on git pull ocurred. Does the specified branch exist?"
	exit $retcode	
fi
exit 0