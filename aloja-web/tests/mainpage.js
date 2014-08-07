casper.test.begin("Mainpage tests", function(test) {
   casper.start('http://localhost:8080/', function() {
     test.assertTitle('ALOJA, BSC\'s Hadoop Benchmark Repository and Online Performance Analysis Tools', 'Title is correct');
     test.assertExists('.popup-youtube', 'Video demo exists');
   });

   casper.run(function() {
      test.done();
   });
});
