param([bool]$runTeragen=$true,[Int32]$reduceTasks=8,[String]$containerName,[String]$inputData,[String]$outputData)

if($runTeragen) {
	$teragen = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "teragen_$containerName_r_$reduceTasks" -ClassName "teragen" -Arguments "-Dmapred.map.tasks=$reduceTasks","-Dmapred.reduce.tasks=$reduceTasks","1000000000", $inputData
	Write-Verbose "Executing teragen"
	RunBench $teragen $containerName -BenchName "prep_terasort"
	Write-Verbose "Done teragen"
}

Write-Verbose "Running terasort with $reduceNumber reducer tasks"
$terasort = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "terasort_$containerName_r_$reduceTasks" -ClassName "terasort" -Arguments "-Dmapred.map.tasks=$reduceTasks","-Dmapred.reduce.tasks=$reduceTasks", $inputData, $outputData
RunBench $terasort $containerName $reduceTasks -BenchName "terasort"
Write-Verbose "Done terasort"
