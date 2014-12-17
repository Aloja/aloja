param([String]$inputData,[String]$outputData,[bool]$runPrepare=$True,[Int32]$reduceTasks=8,[String]$containerName,[String]$bytesPerMap=32000000000,[String]$mapsPerHost=16)

if($runPrepare) {
	$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments "-Dmapreduce.randomtextwriter.bytespermap=$bytesPerMap", "-Dmapreduce.randomtextwriter.mapsperhost=$mapsPerHost", $inputData -JobName "randomtextwriter"
	echo $randomtextwriter
	Write-Verbose "Generating data"
	RunBench $randomtextwriter -containerName $containerName -reduceTasks $reduceTasks -BenchName "prep_wordcount"
	Write-Verbose "Done generating data"
}

Write-Verbose "Running wordcount with $reduceNumber reducer tasks"
$wordcount = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "wordcount_$containerName_r_$reduceTasks" -ClassName "wordcount" -Arguments "-Dmapred.reduce.tasks=$reduceTasks","-Dmapred.map.tasks=$reduceTasks",$inputData,$outputData
RunBench $wordcount -containerName $containerName -reduceTasks $reduceTasks -BenchName "wordcount"
Write-Verbose "Done wordcount"

