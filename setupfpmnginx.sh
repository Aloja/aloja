#!/bin/bash
sudo cp .travis_nginx.conf /etc/nginx/nginx.conf
sudo service nginx restart

base_url="http://localhost:8080"
echo "does it work?"
result=$(curl --silent "$base_url/aloja-web/serverWorksTest.php")

if [ "$result" = "hello" ]
then
    echo "works!"
    exit 0;
fi

echo "failed :("
exit 1

