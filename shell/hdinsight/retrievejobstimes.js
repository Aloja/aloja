var https = require('https');
 
// Cluster Authentication Setup
var clustername = "alojahdi16";
var username = require('../../secure/azure_settings.js').username;
var password = require('../../secure/azure_settings.js').password;

process.argv.forEach(function(val,index,array) {
  if(index == 2)
   clustername = val;
});
 
// Set up the options to get all known Jobs from WebHCat
var optionJobs = {
    host: clustername + ".azurehdinsight.net",
    path: "/templeton/v1/jobs?user.name=" + username + "&showall=true",
    auth: username + ":" + password, // this is basic auth over ssl
    port: 443
};
 
// Make the call to the WebHCat Endpoint
https.get(optionJobs, function (res) {
    var responseString = ""; // Initialize the response string
    res.on('data', function (data) {
        responseString += data; // Accumulate any chunked data
    });
    res.on('end', function () {
        // Parse the response, we know it`s going to be JSON, so we`re not checking Content-Type
	var Jobs = JSON.parse(responseString);
        Jobs.forEach(function (Job) {
            // Set up the options to get information about a specific Job Id
            var optionJob = {
                host: clustername + ".azurehdinsight.net",
                path: "/templeton/v1/jobs/" + Job.id + "?user.name=" + username + "&showall=true",
                auth: username + ":" + password, // this is basic auth over ssl
                port: 443
            };
            https.get(optionJob, function (res) {
                var jobResponseString = ""; // Initialize the response string
                res.on('data', function (data) {
                    jobResponseString += data; // Accumulate any chunked data
                });
                res.on('end', function () {
                    var thisJob = JSON.parse(jobResponseString); // Parse the JSON response
		    if(thisJob.status != undefined && thisJob.status.state == "SUCCEEDED" && thisJob.status.jobName != "TempletonControllerJob" ) {
			if(thisJob.parentId != undefined) {	
			optionJob.path = "/templeton/v1/jobs/" + thisJob.parentId + "?user.name=" + username + "&showall=true";
			https.get(optionJob, function(res) {
			  parentResponseString = ""; //Initialize parent response string
			  res.on('data', function(data) {
			    parentResponseString += data;
			  });
			  res.on('end', function() {
			    var parentJob = JSON.parse(parentResponseString); 
			    var startTime = new Date(thisJob.status.startTime);
                            var finishTime = new Date(thisJob.status.finishTime);
			    var diff = finishTime - startTime;
			    var tmp = parentJob.userargs.define;
			    if(tmp != undefined) {
				tmp = tmp[0].split('hdInsightJobName=');
			        console.log("\""+tmp[1]+"\",\""+thisJob.status.jobId+"\",\""+(diff/1000)+"\"");
			    }
			    //console.log("\""+thisJob.status.jobName+"\",\""+thisJob.status.jobId+"\",\""+(diff/1000)+"\"");
			  });
			});
		    }
                }
              });
            });
        });
    });
});
