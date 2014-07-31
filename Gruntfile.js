'use strict';
module.exports = function(grunt) {
  grunt.initConfig({
    jshint: {
      options: {
	jshintrc: '.jshintrc'
      },
      files: [
	'Gruntfile.js',
	'package.json',
	'aloja-web/tests/*.js'
      ]
    },
    connect: {
    www: {
      options: {
	// keepalive: true,
	base: 'source',
	port: 4545
      }
    }
    },
    ghost: {
      test: {
	files: [{
	  src: ['tests/*.js']
	}]
      },
      options: {
	args: {
	  baseUrl: 'http://localhost:8080/aloja-web/'
	},
	direct: false,
	logLevel: 'error',
	printCommand: false,
	printFilePaths: true
      }
    }
  });
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-nodeunit');
  grunt.loadNpmTasks('grunt-ghost');

  grunt.registerTask('test', ['jshint', 'connect', 'ghost']);
  grunt.registerTask('default', ['connect']);
};
