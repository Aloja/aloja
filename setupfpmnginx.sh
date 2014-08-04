#!/bin/bash
sudo cp .travis_nginx.conf /etc/nginx/nginx.conf
sudo service nginx restart

base_url="http://localhost:8080`pwd`"
echo "does it work?"
echo "raw:"
curl --silent "$base_url/about.php"
result=`curl --silent "$base_url/about.php"`

echo "result:"

if [ "$result" == "hello" ]
then
    echo "works!"
    exit 0;
fi

echo "failed :("
exit 1
