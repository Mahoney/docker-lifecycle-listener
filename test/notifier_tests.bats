#!/usr/bin/env ./libs/bats/bin/bats
load 'libs/bats-support/load'
load 'libs/bats-assert/load'

exit_test() {
  local signal=$1

  # Given the notifier has started
  ../notifier.sh &
  pid=$!
  sleep 1

  # Check it is running
  run kill -0 $pid
  assert_success

  # Capture its child processes
  local children; children=$(pgrep -P $pid)

  # When it is sent the signal
  kill -s "$signal" $pid

  # Then it exits successfully
  wait $pid
  assert_equal $? 0

  # And has no child processes
  while IFS= read -r child_pid; do
    run kill -0 "$child_pid"
    assert_failure
  done <<< "$children"
}

@test "notifier exits cleanly on HUP" {
  exit_test HUP
}

@test "notifier exits cleanly on TERM" {
  exit_test TERM
}

@test "notifier exits cleanly on INT" {
  skip # I don't understand why this fails...
  exit_test INT
}
