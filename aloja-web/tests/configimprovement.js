casper.test.begin("Config improvement tests", function(test) {
   casper.start('http://localhost:8080/aloja-web/config_improvement.php', function() {
	test.assertExists("#chart", 'Chart created');
	test.assertExists("form[name=configFilters] select", 'Filters rendered');
	this.evaluate(function() { 
	   $("form[name=configFilters] select").first().val(['sort','wordcount']).change();
	});
   });

   casper.then(function() {
	var benchsSelected = this.evaluate(function() { 
   	   return $("form[name=configFilters]").find('select').first().val();
	 });
	test.assertEquals(benchsSelected, ['sort','wordcount'], 'Sort and wordcount selected');
   });

   casper.run(function() {
      test.done();
   });
});
