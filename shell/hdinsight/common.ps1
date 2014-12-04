function AzureLogin([String]$credentialsFile)
{
  Import-AzurePublishSettingsFile $credentialsFile
}

function SelectSubscription([String]$subscriptionName)
{
   Set-AzureSubscription -SubscriptionName $subscriptionName
}

function DeleteStorageFile([String]$fileToDelete,[String]$storageAccount, [String]$storageKey, [String]$containerName) {
  $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
  $blob = Get-AzureStorageBlob -Container $containerName -Blob $fileToDelete -Context $context -ErrorVariable blobExist -ErrorAction silentlyContinue | Out-null
  if($blobExist.Exception -eq $null) {
    $blob | %{ Remove-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $context }
    Write-Verbose "Blob removed"
  }
#  else {
#    Write-Verbose "$fileToDelete does not exist in storage container!"
#	Write-Verbose "Error: $blobExist"
#  }
}

function RunBench($definition, $containerName, $reduceTasks) {
   $result = Test-Path $containerName
   if(!$result) {
      mkdir $containerName
   }
   
   $result = Test-Path $containerName/r_$reduceTasks
   if(!$result) {
     mkdir $containerName/r_$reduceTasks
   }
 
   Write-Verbose "Start running benchmark"
   $definition | Start-AzureHDInsightJob -Cluster $clusterName | Wait-AzureHDInsightJob -WaitTimeoutInSeconds 100000 | %{ Get-AzureHDInsightJobOutput -Cluster $clusterName -JobId $_.JobId -StandardError -StandardOutput > $containerName/r_$reduceTasks/"$_.JobId" }
   Write-Verbose "Completed"
}

function RetrieveData([String]$storageAccount, [String]$storageContainer, [String]$logsDir, [String]$storageKey, [String]$minervaLogin) {
   $subscriptions = Get-AzureSubscription
   $currentSubscription = ""
   Foreach($subs in $subscriptions) {
      if($subs.IsCurrent) {
	    $currentSubscription = $subs.SubscriptionName
	  }
   }
   rm $logsDir -R
   Set-AzureSubscription -SubscriptionName $currentSubscription -CurrentStorageAccountName $storageContainer
   Write-Verbose "Copying from storage blob"
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:mapred /Y
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:app-logs /Y
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:yarn /Y
   Write-Verbose "Copying job logs to logs dir"
   cp -R alojahdi* $logsDir/
   Write-Verbose "Copying to minerva account"
   $date = date +%h-%m-%s
   scp -r "$logsDir" "$minervaLogin@minerva.bsc.es:~/hdplogs$storageAccount$date"
   Write-Verbose "Retrieval and saving of logs completed"
}

function createAzureStorageContainer([String]$storageName, [String]$storageKey, [String]$containerName) {
   $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
   New-AzureStorageContainer -Context $context -Name $containerName
}

function removeAzureStorageContainer([String]$storageName, [String]$storageKey, [String]$containerName) {
	 $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
	 Remove-AzureStorageContainer -Name $containerName -Context $context
}

function createCluster([String]$clusterName, [Int32]$nodesNumber=16, [String]$storageName, [String]$storageKey, [bool]$createContainer=$True, [String]$containerName = $null, [AzureHDInsightConfig]$config = $null,[String]$subscriptionName) {
   if($config == $null) {
     Write-Verbose "Creating default configuration with $nodesNumber nodes"
     $config = New-AzureHDInsightConfig -ClusterSizeInNodes $nodesNumber -ClusterType "Hadoop"
   }
   Write-Verbose "Creating HDInsight cluster"
   New-AzureHDInsightCluster -Name $clusterName -Config $config -Subscription $subscriptionName -Location "Western Europe"
   Write-Verbose "Adding storage account to cluster"
   if($containerName == $null) {
     $containerName = $storageName
   }
   
   if($createContainer) {
     Write-Verbose "Creating container $containerName to storage $storageName"
     createAzureStorageContainer -storageName $storageName -storageKey $storageKey -containerName $containerName
   }
   
   Set-AzureHDInsightDefaultStorage -StorageAccountName "$storageName.blob.core.windows.net"  -StorageAccountKey $storageKey -StorageContainerName $containerName
   Write-Verbose "Storage container assigned to cluster"
   Write-Verbose "HDInsight created successfully"
}

function destroyCluster([String]$clusterName, [String]$storageName, [String]$storageKey, [bool]$destroyContainer=$True, [String]$containerName=$null, [String]$subscriptionName) {
  if($destroyContainer == $True) {
     if($containerName == $null) {
	    $containerName = $storageName
	 }
	 Write-Verbose "Removing azure storage container"
	 removeAzureStorageContainer -StorageName $storageName -StorageKey $storageKey -ContainerName $containerName
  }
  
  Write-Verbose "Removing HDInsight cluster"
  Remove-AzureHDInsightCluster -Name $clusterName -Subscription $subscriptionName
  Write-Verbose "HDinsight cluster removed successfully"
}
