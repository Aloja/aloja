param([String]$clusterName, [String]$inputData="/example/data/1TB-sort-input",[String]$outputData="/example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName)

. ./common.ps1

./runterasort.ps1
./runsort.ps1
./runwordcount.ps1
