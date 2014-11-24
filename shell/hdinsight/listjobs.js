var https = require('https');
 
// Cluster Authentication Setup
var clustername = "aloja8";
var username = "";
var password = ""; // Reminder: Don`t share this file with your password saved!
 
// Set up the options to get all known Jobs from WebHCat
var optionJobs = {
    host: clustername + ".azurehdinsight.net",
    path: "/templeton/v1/jobs?user.name=" + username + "&showall=true",
    auth: username + ":" + password, // this is basic auth over ssl
    port: 443
};
 
// Make the call to the WebHCat Endpoint
https.get(optionJobs, function (res) {
    console.log("\nHTTP Response Code: " + res.statusCode);
    var responseString = ""; // Initialize the response string
    res.on('data', function (data) {
        responseString += data; // Accumulate any chunked data
    });
    res.on('end', function () {
        // Parse the response, we know it`s going to be JSON, so we`re not checking Content-Type
        var Jobs = JSON.parse(responseString);
        console.log("The following job information was retrieved:");
        console.log(Jobs);
        Jobs.forEach(function (Job) {
            // Set up the options to get information about a specific Job Id
            var optionJob = {
                host: clustername + ".azurehdinsight.net",
                path: "/templeton/v1/jobs/" + Job.id + "?user.name=" + username + "&showall=true",
                auth: username + ":" + password, // this is basic auth over ssl
                port: 443
            };
            https.get(optionJob, function (res) {
                console.log("\nHTTP Response Code: " + res.statusCode);
                var jobResponseString = ""; // Initialize the response string
                res.on('data', function (data) {
                    jobResponseString += data; // Accumulate any chunked data
                });
                res.on('end', function () {
                    var thisJob = JSON.parse(jobResponseString); // Parse the JSON response
                    console.log("The following is the Status for JobId " + Job.id);
 
                    console.log(thisJob.status); // Just Log the status element.
                });
            });
        });
    });
});
