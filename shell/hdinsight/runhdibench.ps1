param($clusterName, [String]$credentialsFile, [String]$storageAccount, [String]$storageKey, [String]$containerName, [bool]$runTeragen=$true, [Int32[]]$reducersNumber=(12,12), [Int32]$nodesNumber=16, [bool]$createContainer=$True, [String]$subscriptionName, [bool]$destroyCluster=$True, [bool]$destroyContainer=$True, [String]$fullUsername, [String]$password, [String]$logsDir, [String]$minervaLogin, [String[]]$benchmarks = ("wordcount","terasort"))

. ./common.ps1

Write-Verbose "Logging into Azure"
AzureLogin $credentialsFile
SelectSubscription $subscriptionName
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccountName $storageAccount
Write-Verbose "Logged into Azure"

$secPassword = ConvertTo-SecureString -string $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PsCredential($fullUsername, $secPassword)

createCluster $clusterName $nodesNumber $storageAccount $storageKey $createContainer $containerName $subscriptionName $cred
Write-Verbose "Waiting 1 minute"
Start-Sleep -s 60

#if($runTeragen) {
#   Write-Verbose "Removing teragen output data"
#   DeleteStorageFile $inputData $storageAccount $storageKey $containerName
#}

foreach($benchmark in $benchmarks) {
   Write-Verbose "Starting executing $benchmark"
   $c = 0
   $runPrepare = $runTeragen
   foreach($reduceNumber in $reducersNumber) {
	  $outputfile = "/example/data/"+$benchmark+"-output_"+$c
	  $inputfile = "/example/data/"+$benchmark+"-input"
	  $scriptName = "./run"+$benchmark+".ps1"
	 # Write-Verbose "Removing output data"
	  #DeleteStorageFile $outputfile $storageAccount $storageKey $containerName
	  Write-Verbose "Logging into Azure"
	  AzureLogin
	  SelectSubscription "$subscriptionName"
	  Write-Verbose "Logged into Azure"
	  # & indicates that we are gonna run a script named $scriptName with the given parameters
	  & $scriptName -runPrepare $runPrepare -reduceTasks $reduceNumber -containerName $containerName -inputData $inputfile -outputData $outputfile
	  $runPrepare = $False
	  $c++
	}
	Write-Verbose "Execution of $benchmark completed successfully"
}

RetrieveData $storageAccount $containerName $logsDir $storageKey $minervaLogin

if($destroyCluster -eq $True) {
   destroyCluster $clusterName $storageName $storageKey $destroyContainer $containerName $subscriptionName
}
