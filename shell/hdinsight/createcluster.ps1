param($clusterName,[String]$inputData="example/data/1TB-sort-input",[String]$outputData="example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true, [Int32[]]$reducersNumber=(12,12), [Int32]$nodesNumber=16, [bool]$createContainer=$True, [AzureHDInsightConfig]$config = $null,[String]$subscriptionName = "Azpas300ONP8668", [bool]$destroyCluster=$True, [bool]$destroyContainer=$True)

. ./common.ps1

Write-Verbose "Logging into Azure"
AzureLogin
SelectSubscription "Azpas300ONP8668"
Write-Verbose "Logged into Azure"

createCluster $clusterName $nodesNumber $storageName $storageKey $createContainer $containerName $config $subscriptionName

./runhdibench.ps1 -clusterName $clusterName -inputData $inputData -outputData $outputData -storageAccount $storageAccount -storageKey $storageKey -containerName $containerName -runTeragen $runTeragen -reducersNumber $reducersNumber
RetrieveData $storageAccount $storageContainer $logsDir $storageKey $minervaLogin

if($destroyCluster == $True) {
   destroyCluster $clusterName $storageName $storageKey $destroyContainer $containerName $subscriptionName
}
