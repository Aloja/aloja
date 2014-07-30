casper.test.begin("Datatable tests", function(test) {
   casper.start('http://localhost:8080/aloja-web/datatable.php', function() {
	test.assertExists("#benchmarks", "Datatable created");
	var tdCount = this.evaluate(function() { return $("#benchmarks td").length; });
	test.assert(tdCount > 1, 'Datatable has content');
   });

   casper.run(function() {
      test.done();
   });
});
