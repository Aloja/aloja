param($clusterName,[String]$inputData="example/data/1TB-sort-input",[String]$outputData="example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true, [Int32[]]$reducersNumber=(12,12), [String]$subscriptionName)

. ./common.ps1

Write-Verbose "Logging into Azure"
AzureLogin
SelectSubscription $subscriptionName
Write-Verbose "Logged into Azure"

if($runTeragen) {
   Write-Verbose "Removing teragen output data"
   DeleteStorageFile $inputData $storageAccount $storageKey $containerName
}

Write-Verbose "Removing output data"
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
foreach($reduceNumber in $reducersNumber) {
  Write-Verbose "Logging into Azure"
  AzureLogin
  SelectSubscription $subscriptionName
  Write-Verbose "Logged into Azure"
  
  Write-Verbose "Running terasort with $reduceNumber reducer tasks"
  ./runterasort.ps1 -runTeragen $runTeragen -reduceTasks $reduceNumber -containerName $containerName
  $runTeragen = $False
}
Write-Verbose "Execution completed successfully"
