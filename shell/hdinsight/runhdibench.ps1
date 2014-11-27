param($clusterName,[String]$inputData="/example/data/1TB-sort-input",[String]$outputData="/example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true)

. ./common.ps1

if($runTeragen) {
   DeleteStorageFile $inputData $storageAccount $storageKey $containerName
}

DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runterasort.ps1 -runTeragen $runteragen
DeleteStorageFile $inputData $storageAccount $storageKey $containerName
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runsort.ps1
DeleteStorageFile $inputData $storageAccount $storageKey $containerName
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
./runwordcount.ps1
