$teragen = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "teragen" -Arguments "1000000000", $inputData
echo "Executing teragen"
RunBench $teragen
echo "Done teragen"

echo "Executing terasort"
$terasort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "terasort" -Arguments $inputData, $outputData
RunBench $terasort
echo "Done terasort"
