#!/usr/bin/env bats

. ../common/common_benchmarks.sh

java_home='../$trange/p@th/t0/my app'

@test "creates the expected perl string" {
    run create_perl_template_subs JAVA_HOME "$java_home"
    expected='$r = q/..\/$trange\/p@th\/t0\/my app/; s/##JAVA_HOME##/$r/g;'
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
}

@test "fails when an odd number of arguments are passed" {
    run create_perl_template_subs one_arg
    [ "$status" -ne 0 ]
}

@test "performs the expected substitution" {
    input='(start)##JAVA_HOME##(end)'
    run perl -pe "$(create_perl_template_subs JAVA_HOME "$java_home")" <<<"$input"
    expected="(start)$java_home(end)"
    [ "$output" = "$expected" ]
}

@test "performs more than one set of substitution" {
    input='(first)##JAVA_HOME##'$'\n''(second)##JAVA_HOME##'
    run perl -pe "$(create_perl_template_subs JAVA_HOME "$java_home")" <<<"$input"
    expected="(first)$java_home"$'\n'"(second)$java_home"
    [ "$output" = "$expected" ]
}
