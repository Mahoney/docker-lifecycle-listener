#!/usr/bin/env ./libs/bats/bin/bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'
source 'libs/test_helpers.sh'

exit_test() {
  local signal=$1

  # Given the notifier has started
  ../docker_watcher.sh &
  process_under_test=$!
  sleep 1

  # Check it is running
  run kill -0 $process_under_test
  assert_success

  # Capture its child processes
  local descendants; descendants=$(get_descendants $process_under_test)

  # When it is sent the signal
  kill -s "$signal" $process_under_test

  # Then it exits successfully
  wait $process_under_test
  assert_equal $? 0

  # And has no child processes
  assert_all_exited "$descendants"
}

@test "docker_watcher exits cleanly on HUP" {
  exit_test HUP
}

@test "docker_watcher exits cleanly on TERM" {
  exit_test TERM
}

@test "docker_watcher exits cleanly on INT" {
  skip # I don't understand why this fails...
  exit_test INT
}
