param([String]$clusterName="alojahdi6", [String]$inputData="/example/data/1TB-sort-input", [String]$outputData="/example/data/1TB-sort-output")

. ./common.ps1

./runterasort.ps1
./runsort.ps1
./runwordcount.ps1
