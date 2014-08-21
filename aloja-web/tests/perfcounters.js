casper.test.begin("Performance counters tests", function(test) {
	 casper.on('remote.message', function(msg) {
		  this.echo(msg);
	 });
		
   casper.start('http://localhost:8080/metrics', function() {
	test.assertExists("#benchmarks", "Metrics table created");
    test.assertExists("#benchmarks td", "Metrics table has content");

    test.assertEval(function() { 
    	return $("#benchmarks tr:nth-child(2) th").children('input').eq(2).val() == 'filter col';
    }, 'Benchmark filter field exists');
    this.evaluate(function() {
    	$("#benchmarks tr:nth-child(2) th").children('input').eq(2).val('pagerank').keyup();
    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = true;
		   $("#benchmarks tbody tr td:nth-child(2)").each(function() {
			  var text = $(this).text();
			  console.log(text);
			  if(text != 'pagerank')
				 isOk = false;
		   });
		   return isOk;
	   }, 'Benchmark is pagerank after filtering out the others');
	   
	   this.evaluate(function() {
	    	$("#benchmarks tr:nth-child(2) th").children('input').eq(2).val(' ').keyup();
	    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = false;
		   $("#benchmarks tbody tr td:nth-child(2)").each(function() {
			  var text = $(this).text();
			  if(text == "kmeans")
				 isOk = true;
		   });
		   return isOk;
	   }, 'There is at least one kmeans benchmark after restoring filters');
	   
	   test.assertEval(function() {
		  return $("#benchmarks_filter input") != null; 
	   }, 'Global filter input exists');
	   
	   this.evaluate(function() {
		   $("#benchmarks_filter input").val('dfsioe_write').keyup();
	    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = true;
		   $("#benchmarks tbody tr td:nth-child(2)").each(function() {
			  var text = $(this).text();
			  if(text != 'dfsioe_write')
				 isOk = false;
		   });
		   return isOk;
	   }, 'Benchmark is dfsioe_write using global filter');
   });

   casper.run(function() {
      test.done();
   });
});
