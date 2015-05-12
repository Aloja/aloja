param([String]$inputData,[String]$outputData,[bool]$runTeragen=$True,[Int32]$reduceTasks=48,[String]$containerName,[String]$nodesNumber)

if($runPrepare) {
	$mapsPerHost=16
	$gbPerHost=(128000000000/$nodesNumber)
	$bytesPerMap=[Int64]($gbPerHost/$mapsPerHost)
	$randomtextwriter = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -ClassName "randomtextwriter" -Arguments "-Dmapreduce.randomtextwriter.bytespermap=$bytesPerMap", "-Dmapreduce.randomtextwriter.mapsperhost=$mapsPerHost", $inputData -JobName "randomtextwriter"
	echo $randomtextwriter
	Write-Verbose "Generating data"
	RunBench $randomtextwriter -containerName $containerName -reduceTasks $reduceTasks -BenchName "prep_wordcount"
	Write-Verbose "Done generating data"
}

Write-Verbose "Running wordcount with $reduceNumber reducer tasks"
$wordcount = New-AzureHDInsightMapReduceJobDefinition -JarFile "/example/jars/hadoop-mapreduce-examples.jar" -JobName "wordcount_$containerName_r_$reduceTasks" -ClassName "wordcount" -Arguments "-Dmapred.reduce.tasks=$reduceTasks",-Dmapreduce.inputformat.class=org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat,-Dmapreduce.outputformat.class=org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat,-Dmapreduce.job.inputformat.class=org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat,-Dmapreduce.job.outputformat.class=org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat,$inputData,$outputData
RunBench $wordcount -containerName $containerName -reduceTasks $reduceTasks -BenchName "wordcount"
Write-Verbose "Done wordcount"

