#!/bin/bash

if [ "$#" -ne "2" ]; then
   echo "You must proivde an user and a password"
   exit
fi

user=$1
password=$2

while read User; do
    if [[ "pristine" == "$User" ]]; then
        echo "pristine user already exists in MySQL, not creating it"
        break
    fi
done < <(mysql -B -N -e 'use mysql; SELECT `user` FROM `user`;')

if [[ "pristine" != "$User" ]]; then
    echo "Creating pristine user"
	mysql -uroot -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$password'"
	mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$user'@'localhost'"
fi

cd /var/www/aloja-web/config
sed -e "s/mysql_user: root/mysql_user: $user/" -e "s/mysql_pwd:/mysql_pwd: $password/" -e "s/enable_debug: true/enable_debug: false/" -e "s/in_cache: false/in_cache: true/" config.sample.yml > config.yml

bash -c "cd /var/www/aloja-web && sudo php composer.phar self-update && sudo php composer.phar update"
#bash -c "cd /var/www/aloja-web && php vendor/bin/phinx -cconfig/phinx.yml -eproduction migrate"
bash -c "cd /var/www/shell && ./create-update_DB.sh"
sudo chown www-data.www-data -R /var/www/aloja-web/vendor
sudo chmod 775 -R /var/www/aloja-web/vendor
	
exit
