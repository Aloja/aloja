#!/bin/bash
base_url="http://localhost:8080"
result=$(curl --silent "$base_url/aloja-web/serverWorksTest.php")

if [ "$result" = "hello" ]
then
   echo "Server is working\nRunning functional tests.."
   npm test
   ret_code=$?
   echo "exiting with ret code $ret_code\n"
   exit $ret_code
else
  echo "Server is not working"
  exit 1
fi
