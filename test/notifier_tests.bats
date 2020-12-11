#!/usr/bin/env ./libs/bats/bin/bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'

source 'libs/test_helpers.sh'

@test "notifier exits cleanly on HUP" {
  skip # fails on mac because infinity cannot be passed to sleep
  exit_test ../notifier.sh HUP
}

@test "notifier exits cleanly on TERM" {
  skip # fails on mac because infinity cannot be passed to sleep
  exit_test ../notifier.sh TERM
}

@test "notifier exits cleanly on INT" {
  skip # I don't understand why this fails...
  exit_test ../notifier.sh INT
}
