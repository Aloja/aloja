$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments $inputData
echo "Generating data"
RunBench $randomtextwriter
echo "Done generating data"

echo "Executing sort"
$sort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "sort" -Arguments $inputData, $outputData
RunBench $sort
echo "Done sort" 
