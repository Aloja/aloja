param($clusterName,[String]$inputData="example/data/1TB-sort-input",[String]$outputData="example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true, [Int32[]]$reducersNumber=(12,12), [Int32]$nodesNumber=16, [bool]$createContainer=$True, [String]$subscriptionName = "", [bool]$destroyCluster=$True, [bool]$destroyContainer=$True, [String]$fullUsername, [String]$password)

. ./common.ps1

Write-Verbose "Logging into Azure"
AzureLogin
SelectSubscription $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccountName $storageAccount
Write-Verbose "Logged into Azure"

$secPassword = ConvertTo-SecureString -string $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PsCredential($fullUsername, $secPassword)

if($destroyCluster -eq $True) {
   destroyCluster $clusterName $storageAccount $storageKey $destroyContainer $containerName $subscriptionName
}
