#!/bin/bash
base_url="http://localhost:8080"
result=$(curl --silent "$base_url/aloja-web/serverWorksTest.php")

if [ "$result" = "hello" ]
then
   echo -e "\e[1;42mPASS Server is working\e[0m\nRunning functional tests..\n"
   npm test
   ret_code=$?
   echo "exiting with ret code $ret_code\n"
   exit $ret_code
else
  echo -e "\e[1;101mFAIL Server is NOT working\e[0m\n"
  exit 1
fi
