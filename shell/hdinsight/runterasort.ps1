param([bool]$runTeragen=$true,[Int32]$reduceTasks=8,[String]$containerName)

if($runteragen) {
	$teragen = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "teragen_$containerName_r_$reduceTasks" -ClassName "teragen" -Arguments "-Dmapred.map.tasks=$reduceTasks","-Dmapred.reduce.tasks=$reduceTasks","10000000000", $inputData
	Write-Verbose "Executing teragen"
	RunBench $teragen $containerName
	Write-Verbose "Done teragen"
}

Write-Verbose "Executing terasort"
$terasort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "terasort_$containerName_r_$reduceTasks" -ClassName "terasort" -Arguments "-Dmapred.map.tasks=$reduceTasks","-Dmapred.reduce.tasks=$reduceTasks", $inputData, $outputData
RunBench $terasort $containerName $reduceTasks
Write-Verbose "Done terasort"

