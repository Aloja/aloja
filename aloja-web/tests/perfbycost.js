casper.test.begin("Perf by cost tests", function(test) {
   casper.start('http://localhost:8080/costperfeval?bench=terasort', function() {
	test.assertExists("#chart", 'Chart created');
	test.assertExists("form select", 'Filters rendered');
	this.evaluate(function() { 
	   $("form select").first().val(['sort']).change();
	});
   });

   casper.then(function() {
	var benchsSelected = this.evaluate(function() { 
   	   return $("form select").first().val();
	});
	test.assertEquals(benchsSelected, 'sort', 'Sort selected');
   });

   casper.run(function() {
      test.done();
   });
});
