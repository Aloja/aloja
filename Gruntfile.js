'use strict';
module.exports = function(grunt) {
  grunt.initConfig({
     casper: {
	  options: {
        test: true,
	  },
      files: ['aloja-web/tests/*.js']
     }
  });

  grunt.loadNpmTasks('grunt-casper');

  grunt.registerTask('test', ['casper']);
  grunt.registerTask('default', ['connect']);
};
