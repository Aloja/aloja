param([String]$clusterName="alojahdi6", [String]$inputData="/example/data/1TB-sort-input", [String]$outputData="/example/data/1TB-sort-output")

. ./common.ps1

$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments $inputData
echo "Generating data"
RunBench $randomtextwriter
echo "Done generating data"

echo "Executing wordcount"
$wordcount = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "wordcount" -Arguments $inputData, $outputData
RunBench $wordcount
echo "Done wordcount" 
