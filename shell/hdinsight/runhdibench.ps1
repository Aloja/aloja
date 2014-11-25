param($clusterName,[String]$inputData="/example/data/1TB-sort-input",[String]$outputData="/example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName)

. ./common.ps1

DeleteStorageFile $inputData $storageAccount $storageKey $containerName
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runterasort.ps1
DeleteStorageFile $inputData $storageAccount $storageKey $containerName
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runsort.ps1
DeleteStorageFile $inputData $storageAccount $storageKey $containerName
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runwordcount.ps1
