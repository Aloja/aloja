casper.options.logLevel = "debug";
casper.test.begin("Config improvement tests", function(test) {
   casper.start('http://localhost:8080/configimprovement', function() {
	test.assertExists("#chart", 'Chart created');
	test.assertExists("form[name=configFilters] input", 'Filters rendered');
	this.evaluate(function() {
	   $("input[name$='benchs[]']").each(function() {
			   $(this).removeAttr('checked');
	   });
	   document.querySelector("input[value='wordcount']").setAttribute('checked',true);
	   document.querySelector("input[value='sort']").setAttribute('checked',true);
	});
   });

   casper.then(function() {
	var checked = this.evaluate(function() {
	    var wordChecked = $("input[value$='wordcount']").first().attr("checked");
  	    var sortChecked = $("input[value$='sort']").first().attr("checked");
	    return (wordChecked && sortChecked);	
	});
	test.assertTruthy(checked, 'Sort and wordcount selected');
	/*var benchsSelected = this.evaluate(function() { 
   	   return $("form[name=configFilters]").find('select').first().val();
	 });
	test.assertEquals(benchsSelected, ['sort','wordcount'], 'Sort and wordcount selected');*/
   });

   casper.run(function() {
      test.done();
   });
});

casper.on('remote.message', function(msg) {
    this.echo('DEBUG: ' + msg);
})
