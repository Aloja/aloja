casper.test.begin("Datatable tests", function(test) {
	 casper.on('remote.message', function(msg) {
		  this.echo(msg);
	 });
		
   casper.start('http://localhost:8080/counters?type=SUMMARY', function() {
	test.assertExists("#benchmarks", "Counters table created");
    test.assertExists("#benchmarks td", "Counters table has content");

    test.assertEval(function() { 
    	return $("tr:nth-child(2) th").children('input').eq(4).val() == 'filter col';
    }, 'Benchmark filter field exists');
    this.evaluate(function() {
    	$("tr:nth-child(2) th").children('input').eq(4).val('sort').keyup();
    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = true;
		   $("tbody tr td:nth-child(4)").each(function() {
			  var text = $(this).text();
			  if(text != 'sort' && text != 'terasort')
				 isOk = false;
		   });
		   return isOk;
	   }, 'Benchmark is sort or terasort after filtering out the others');
	   
	   this.evaluate(function() {
	    	$("tr:nth-child(2) th").children('input').eq(4).val(' ').keyup();
	    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = false;
		   $("tbody tr td:nth-child(4)").each(function() {
			  var text = $(this).text();			  
			  if(text == "wordcount")
				 isOk = true;
		   });
		   return isOk;
	   }, 'There is at least one wordcount benchmark after restoring filters');
	   
	   test.assertEval(function() {
		  return $("#benchmarks_filter input") != null; 
	   }, 'Global filter input exists');
	   
	   this.evaluate(function() {
		   $("#benchmarks_filter input").val('terasort').keyup();
	    });
   });
   
   casper.then(function() {
	   test.assertEval(function() {
		   var isOk = true;
		   $("tbody tr td:nth-child(4)").each(function() {
			  var text = $(this).text();
			  if(text != 'terasort')
				 isOk = false;
		   });
		   return isOk;
	   }, 'Benchmark is terasort using global filter');
   });

   casper.run(function() {
      test.done();
   });
});
