#!/bin/bash
base_url="http://localhost:8080"
echo "does it work?"
result=$(curl --silent "$base_url/aloja-web/serverWorksTest.php")

if [ "$result" = "hello" ]
then
   npm test
   exit 0
fi

echo "failed :("
exit 1
