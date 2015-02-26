function CreatePerformanceMonitoringCounter($Credentials, [String]$numberOfNodes)
{	
	for($i = 0; $i -lt $numberOfNodes; ++$i) {
	    Invoke-Command -ComputerName "workernode$i" -Authentication Negotiate -Credential $Credentials -ScriptBlock { if ( Test-Path C:\counters$(hostname).txt ) { rm C:\counters$(hostname).txt; }; add-content "C:\counters$(hostname).txt" "\System\*`n\Processor(*)\*`n\Processor Information\*`n\Processor Performance\*`n\Process(*)\*`n\Memory\*`n\Network Interface\*"; logman create counter "hdicounters" -cf  "C:\counters$(hostname).txt" -si "00:00:01" -f csv -v mmddhhmm -o "C:\perfmetrics$(hostname).csv" } -AsJob | Wait-Job
    }
}

function StartPerformanceMonitoring($Credentials, [String]$numberOfNodes)
{
	for($i = 0; $i -lt $numberOfNodes; ++$i) {
	    Invoke-Command -ComputerName "workernode$i" -Authentication Negotiate -Credential $Credentials -ScriptBlock { rm "C:\perfmetrics$(hostname)*.csv"; logman start "hdicounters" } -AsJob | Wait-Job
    }
}

function StopPerformanceMonitoring($Credentials, [String]$numberOfNodes)
{
	for($i = 0; $i -lt $numberOfNodes; ++$i) {
	    Invoke-Command -ComputerName "workernode$i" -Authentication Negotiate -Credential $Credentials -ScriptBlock { logman stop "hdicounters" } -AsJob | Wait-Job
    }
}

function CollectPerfMetricsLogs([String]$numberOfNodes,[String]$minervaLogin="acall")
{
	rmdir C:\perflogs* -Recurse -Force

	$date = [int][double]::Parse((Get-Date -UFormat %s))
    $year = (Get-Date -f yyyyMMdd)
    
	$dirLogs = "perflogs_${year}_${storageAccount}_$date"
	mkdir "C:\$dirLogs"
	
	for($i = 0; $i -lt $numberOfNodes; ++$i) {
	    Copy-Item  -Recurse -Force -Path \\"workernode$i"\c$\"perfmetricsworkernode${i}*.csv" -Destination \\$(hostname)\c$\"$dirLogs"\"perfmetricsworkernode${i}.csv"
    }
    
    if ( !(Test-Path "pscp.exe") ) {
    	(new-object System.Net.WebClient).DownloadFile('http://the.earth.li/~sgtatham/putty/latest/x86/pscp.exe','pscp.exe')
    }

   .\pscp.exe -r "C:\$dirLogs" "$minervaLogin@minerva.bsc.es:"
   Write-Verbose "Retrieval and saving of logs completed"
}

function AzureLogin([String]$credentialsFile)
{
  Import-AzurePublishSettingsFile $credentialsFile
}

function SelectSubscription([String]$subscriptionName)
{
   Select-AzureSubscription -Current $subscriptionName
}

function DeleteStorageFile([String]$fileToDelete,[String]$storageAccount, [String]$storageKey, [String]$containerName) {
  $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
  $blob = Get-AzureStorageBlob -Container $containerName -Blob $fileToDelete -Context $context -ErrorVariable blobExist -ErrorAction silentlyContinue | Out-null
  if($blobExist.Exception -eq $null) {
    $blob | %{ Remove-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $context }
    Write-Verbose "Blob removed"
  }
  else {
    Write-Verbose "$fileToDelete does not exist in storage container!"
	Write-Verbose "Error: $blobExist"
  }
}

function RunBench($definition, $containerName, $reduceTasks, $benchName = "terasort") {
   $result = Test-Path $containerName
   if(!$result) {
      mkdir $containerName
   }
   
   $directoryName = $benchName + "_r_$reduceTasks"
   $result = Test-Path $containerName/$directoryName
   if(!$result) {
     mkdir $containerName/$directoryName
   }
 
   Write-Verbose "Start running benchmark"
   $definition | Start-AzureHDInsightJob -Cluster $clusterName | Wait-AzureHDInsightJob -WaitTimeoutInSeconds 100000 | %{ Get-AzureHDInsightJobOutput -Cluster $clusterName -JobId $_.JobId -StandardError -StandardOutput > $_.JobId }
   mv job_* $containerName/$directoryName/
   Write-Verbose "Completed"
}

function RetrieveData([String]$storageAccount, [String]$storageContainer, [String]$logsDir, [String]$storageKey, [String]$minervaLogin) {
   $date = [int][double]::Parse((Get-Date -UFormat %s))
   $year = (Get-Date -f yyyyMMdd)
   $newLogsDirName="${year}_${storageAccount}_$date"
   
   rm $logsDir -R
   mkdir $logsDir
   Write-Verbose "Copying from storage blob"
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:mapred /Y
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:app-logs /Y
   AzCopy /Source:"https://$storageAccount.blob.core.windows.net/$storageContainer" /Dest:$logsDir /SourceKey:"$storageKey" /S /Pattern:yarn /Y
   Write-Verbose "Copying job logs to logs dir"
   cp -R $storageContainer $logsDir/
   Write-Verbose "Copying to minerva account"
   
   if ( !(Test-Path "pscp.exe") ) {
    	(new-object System.Net.WebClient).DownloadFile('http://the.earth.li/~sgtatham/putty/latest/x86/pscp.exe','pscp.exe')
   }
   
   mv $logsDir $newLogsDirName
   .\pscp.exe -r "$newLogsDirName" "$minervaLogin@minerva.bsc.es:"
   Write-Verbose "Retrieval and saving of logs completed"
}

function createAzureStorageContainer([String]$storageName, [String]$storageKey, [String]$containerName) {
   $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
   New-AzureStorageContainer -Context $context -Name $containerName
}

function removeAzureStorageContainer([String]$storageName, [String]$storageKey, [String]$containerName) {
	 $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
	 Remove-AzureStorageContainer -Name $containerName -Context $context -Force
}

function createCluster([String]$clusterName, [Int32]$nodesNumber=16, [String]$storageName, [String]$storageKey, [bool]$createContainer=$True, [String]$containerName = $null, [String]$subscriptionName, [System.Management.Automation.PsCredential]$cred) {
   if($containerName -eq $null) {
     $containerName = $storageName
   }
   
   if($createContainer) {
     Write-Verbose "Creating container $containerName to storage $storageName"
     createAzureStorageContainer -storageName $storageName -storageKey $storageKey -containerName $containerName
   }
   Write-Verbose "Storage container assigned to cluster"
   
   Write-Verbose "Creating HDInsight cluster"
   New-AzureHDInsightCluster -Name $clusterName -ClusterSizeInNodes $nodesNumber -Location "West Europe" -Credential $cred -DefaultStorageAccountKey $storageKey -DefaultStorageAccountName "$storageName.blob.core.windows.net" -DefaultStorageContainerName $containerName
   Write-Verbose "HDInsight cluster created successfully"
}

function destroyCluster([String]$clusterName, [String]$storageName, [String]$storageKey, [bool]$destroyContainer=$True, [String]$containerName=$null, [String]$subscriptionName) {
  if($destroyContainer -eq $True) {
     if($containerName -eq $null) {
	    $containerName = $storageName
	 }
	 Write-Verbose "Removing azure storage container"
	 removeAzureStorageContainer -StorageName $storageName -StorageKey $storageKey -ContainerName $containerName
  }
  
  Write-Verbose "Removing HDInsight cluster"
  Remove-AzureHDInsightCluster -Name $clusterName
  Write-Verbose "HDinsight cluster removed successfully"
}
