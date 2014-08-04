casper.test.begin("Datatable tests", function(test) {
   casper.start('http://localhost:8080/aloja-web/counters.php?type=SUMMARY', function() {
	test.assertExists("#benchmarks", "Counters table created");
    test.assertExists("#benchmarks td", "Counters table has content");
//	var tdCount = this.evaluate(function() { return $("#benchmarks td").length; });
//	test.assert(tdCount > 1, 'Datatable has content');
   });

   casper.run(function() {
      test.done();
   });
});
