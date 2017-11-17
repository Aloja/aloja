#!/usr/bin/env bats

. ../monitor/monitor_yarn.sh

yarn_output='{
  "apps": {
    "app": [
      {
        "resourceRequests": [
          {
            "resourceName": "*",
            "relaxLocality": true,
            "priority": {
              "priority": 0
            },
            "numContainers": 0,
            "nodeLabelExpression": "",
            "capability": {
              "virtualCores": 1,
              "memory": 512
            }
          }
        ],
        "numAMContainerPreempted": 0,
        "numNonAMContainerPreempted": 0,
        "preemptedResourceVCores": 0,
        "preemptedResourceMB": 0,
        "vcoreSeconds": 27,
        "memorySeconds": 14358,
        "runningContainers": 2,
        "allocatedVCores": 2,
        "allocatedMB": 1024,
        "amHostHttpAddress": "vagrant-99-01:8042",
        "amContainerLogs": "http://vagrant-99-01:8042/node/containerlogs/container_1510842738303_0001_01_000001/vagrant",
        "trackingUI": "ApplicationMaster",
        "progress": 0,
        "finalStatus": "UNDEFINED",
        "state": "RUNNING",
        "queue": "default",
        "name": "HIVE-d59da2ff-6196-4711-9b81-6de32aa50b65",
        "user": "vagrant",
        "id": "application_1510842738303_0001",
        "trackingUrl": "http://vagrant-99-00:8088/proxy/application_1510842738303_0001/",
        "diagnostics": "",
        "clusterId": 1510842738303,
        "applicationType": "TEZ",
        "applicationTags": "test,populatemetastore",
        "startedTime": 1510842860085,
        "finishedTime": 0,
        "elapsedTime": 19954
      }
    ]
  }
}
'

yarn_output_empty_bench='{
  "apps": {
    "app": [
      {
        "applicationTags": "test"
      }
    ]
  }
}
'

yarn_output_empty_experiment='{
  "apps": {
    "app": [
      {
        "applicationTags": ""
      }
    ]
  }
}
'

setup () {
  jq_path="$BATS_TEST_DIRNAME/../.."
  mapfile -t lines < <(_monitor_parse_yarn_output "$jq_path" <<<"$yarn_output")
  mapfile -t lines_empty_bench < <(_monitor_parse_yarn_output "$jq_path" <<<"$yarn_output_empty_bench")
  mapfile -t lines_empty_experiment < <(_monitor_parse_yarn_output "$jq_path" <<<"$yarn_output_empty_experiment")
}

@test "produces two lines of output" {
  [ ${#lines[@]} -eq 2 ]
}
@test "first line is valid JSON" {
  run jq . <<<"${lines[0]}"
  [ $status -eq 0 ]
}
@test "second line is valid JSON" {
  run jq . <<<"${lines[1]}"
  [ $status -eq 0 ]
}
@test "sets the expected experimentId" {
  run jq -r '.experimentId' <<<"${lines[1]}"
  [ "$output" = 'test' ]
}
@test "sets the expected displayName" {
  run jq -r '.displayName' <<<"${lines[1]}"
  [ "$output" = 'populatemetastore' ]
}
@test "empty benchmark results in null value" {
  run jq -r '.displayName' <<<"${lines_empty_bench[1]}"
  [ "$output" = 'null' ]
}
@test "empty experiment results in null value" {
  run jq -r '.experimentId' <<<"${lines_empty_experiment[1]}"
  [ "$output" = 'null' ]
}
