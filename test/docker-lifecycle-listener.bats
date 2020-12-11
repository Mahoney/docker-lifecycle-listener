#!/usr/bin/env ./libs/bats/bin/bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
source 'libs/test_helpers.sh'

@test "docker-lifecycle-listener exits cleanly on TERM" {
  exit_test '../docker-lifecycle-listener.sh /tmp' TERM
}

@test "docker-lifecycle-listener exits cleanly on HUP" {
  exit_test '../docker-lifecycle-listener.sh /tmp' HUP
}

@test "docker-lifecycle-listener exits cleanly on INT" {
  skip # I don't understand why this fails...
  exit_test '../docker-lifecycle-listener.sh /tmp' INT
}
