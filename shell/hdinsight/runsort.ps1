$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments "-Dfs.azure.selfthrottling.write.factor=1", "-Dfs.azure.selfthrottling.read.factor=1", $inputData
echo "Generating data"
RunBench $randomtextwriter
echo "Done generating data"

echo "Executing sort"
$sort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "sort" -Arguments "-Dfs.azure.selfthrottling.write.factor=1", "-Dfs.azure.selfthrottling.read.factor=1", $inputData, $outputData
RunBench $sort
echo "Done sort" 
