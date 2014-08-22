casper.test.begin("Job counters tests", function(test) {
	 casper.on('remote.message', function(msg) {
		  this.echo(msg);
	 });
		
   casper.start('http://localhost:8080/counters?type=SUMMARY', function() {
	test.assertExists("#benchmarks", "Counters table created");
	test.assertEval(function() {
		return $("#benchmarks td").length > 1;
	}, 'Counters table has content');

    test.assertEval(function() { 
    	return $("#benchmarks tr:nth-child(2) th").children('input').eq(4).val() == 'filter col';
    }, 'Benchmark filter field exists');
    this.evaluate(function() {
    	$("#benchmarks tr:nth-child(2) th").children('input').eq(4).val('pagerank').keyup();
    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = true;
		   $("#benchmarks tbody tr td:nth-child(4)").each(function() {
			  var text = $(this).text();
			  if(text != 'pagerank')
				 isOk = false;
		   });
		   return isOk;
	   }, 'Benchmark is pagerank after filtering out the others');
	   
	   this.evaluate(function() {
	    	$("#benchmarks tr:nth-child(2) th").children('input').eq(4).val(' ').keyup();
	    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = false;
		   $("#benchmarks tbody tr td:nth-child(4)").each(function() {
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
		   $("#benchmarks tbody tr td:nth-child(4)").each(function() {
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
