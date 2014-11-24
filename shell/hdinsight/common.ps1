function DeleteStorageFile([String]$fileToDelete,[String]$storageAccount, [String]$storageKey, [String]$containerName) {
  $context = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
  Get-AzureStorageBlob -Container $containerName -Blob $fileToDelete -Context $context | %{ Remove-AzureStorageBlob -Blob $_.Name -Container $containerName -Context $context }
}

function RunBench($definition) {
   $definition | Start-AzureHDInsightJob -Cluster $clusterName | Wait-AzureHDInsightJob
}
