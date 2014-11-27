$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments $inputData
echo "Generating data"
RunBench $randomtextwriter
echo "Done generating data"

echo "Executing wordcount"
$wordcount = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "wordcount" -Arguments $inputData, $outputData
RunBench $wordcount
echo "Done wordcount" 
