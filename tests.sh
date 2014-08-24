#!/bin/bash
base_url="http://localhost:8080"
result=$(curl --silent "$base_url/serverWorksTest.php")

if [ "$result" = "hello" ]
then
   echo -e "\u001b[1;42mPASS Server is working\u001b[0m\nChecking if benchdata info is JSON\n"
   npm test
   ret_code=$?
   echo "exiting with ret code $ret_code\n"
   exit $ret_code
else
  echo -e "\e[1;101mFAIL Server is NOT working\e[0m\n"
  exit 1
fi
