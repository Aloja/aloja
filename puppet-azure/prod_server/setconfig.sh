#!/bin/bash

if [ "$#" -ne "2" ]; then
   echo "You must proivde an user and a password"
   exit
fi

user=$1
password=$2

mysql -uroot -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$password'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$user'@'localhost'"

cd /var/www/aloja-web/config
sed -e "s/mysql_user: root/mysql_user: $user/" -e "s/mysql_pwd:/mysql_pwd: $password/" config.sample.yml > config.yml
exit
