param([String]$clusterName, [String]$inputData="/example/data/1TB-sort-input", [String]$outputData="/example/data/1TB-sort-output", [String]$storageAccount, [String]$storageKey, [String]$containerName)

. ./common.ps1

$teragen = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "teragen" -Arguments "1000000000", $inputData
echo "Executing teragen"
RunBench $teragen
echo "Done teragen"

echo "Executing terasort"
$terasort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "terasort" -Arguments $inputData, $outputData
RunBench $terasort
echo "Done terasort"
