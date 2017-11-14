#!/usr/bin/env bats

. ../common/common_benchmarks.sh

big_number="10"
small_number="5"

@test "get_max_int should return the higher natural number - higher number first" {
    run get_max_int "$big_number" "$small_number"
    [ "$status" -eq 0 ]
    [ "$output" = "$big_number" ]
}

@test "get_max_int should return the higher natural number - smaller number first" {
run get_max_int "$small_number" "$big_number"
    [ "$status" -eq 0 ]
    [ "$output" = "$big_number" ]
}

@test "get_min_int should return the smaller natural number - higher number first" {
    run get_min_int "$big_number" "$small_number"
    [ "$status" -eq 0 ]
    [ "$output" = "$small_number" ]
}

@test "get_min_int should return the smaller natural number - smaller number first" {
    run get_min_int "$small_number" "$big_number"
    [ "$status" -eq 0 ]
    [ "$output" = "$small_number" ]
}

@test "get_max_int fail if only one parameter is passed" {
    run get_max_int "$big_number"
    [ "$status" -ne 0 ]
}

@test "get_min_int fail if only one parameter is passed" {
    run get_min_int "$small_number"
    [ "$status" -ne 0 ]
}
