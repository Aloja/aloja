param([String]$clusterName="alojahdi6", [String]$inputData="/example/data/1TB-sort-input", [String]$outputData="/example/data/1TB-sort-output")

function RunBench($definition) {
   $definition | Start-AzureHDInsightJob -Cluster $clusterName | Wait-AzureHDInsightJob
}

$teragen = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "teragen" -Arguments "-Dmapred.map.tasks=16", "1000000000", $inputData
echo "Executing teragen"
RunBench $teragen
echo "Done teragen"

echo "Executing terasort"
$terasort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "terasort" -Arguments $inputData, $outputData
RunBench $terasort
echo "Done terasort"
