param($clusterName,[String]$inputData="example/data/1TB-sort-input",[String]$outputData="example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true, [Int32[]]$reducersNumber=(12,12), [Int32]$nodesNumber=16, [bool]$createContainer=$True, [String]$subscriptionName = "", [bool]$destroyCluster=$True, [bool]$destroyContainer=$True, [String]$fullUsername, [String]$password, [String]$logsDir, [String]$minervaLogin)

. ./common.ps1

Write-Verbose "Logging into Azure"
AzureLogin
SelectSubscription $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccountName $storageAccount
Write-Verbose "Logged into Azure"

$secPassword = ConvertTo-SecureString -string $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PsCredential($fullUsername, $secPassword)

createCluster $clusterName $nodesNumber $storageAccount $storageKey $createContainer $containerName $subscriptionName $cred

if($runTeragen) {
   Write-Verbose "Removing teragen output data"
   DeleteStorageFile $inputData $storageAccount $storageKey $containerName
}

Write-Verbose "Removing output data"
DeleteStorageFile $outputData $storageAccount $storageKey $containerName
foreach($reduceNumber in $reducersNumber) {
  Write-Verbose "Logging into Azure"
  AzureLogin
  SelectSubscription "$subscriptionName"
  Write-Verbose "Logged into Azure"
  
  Write-Verbose "Running terasort with $reduceNumber reducer tasks"
  ./runterasort.ps1 -runTeragen $runTeragen -reduceTasks $reduceNumber -containerName $containerName
  $runTeragen = $False
}
Write-Verbose "Execution completed successfully"
RetrieveData $storageAccount $storageContainer $logsDir $storageKey $minervaLogin

if($destroyCluster -eq $True) {
   destroyCluster $clusterName $storageName $storageKey $destroyContainer $containerName $subscriptionName
}
