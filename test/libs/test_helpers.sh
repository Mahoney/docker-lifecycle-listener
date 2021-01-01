get_descendants() {
  declare children; children=$(pgrep -P "$1")
  for i in $children; do
    declare pid="$i"
    get_descendants "$pid"
    echo "$pid"
  done
}

assert_all_exited() {
  declare processes; processes="$1"
  echo "Checking if $processes have exited"
  while IFS= read -r process; do
    echo "Checking if $process has exited"
    run kill -0 "$process"
    test "$status" -ne 0
  done <<< "$processes"
}

exit_test() {
  local command=$1
  local signal=$2

  # Given the notifier has started
  bash -c "$command" &
  process_under_test=$!
  sleep 1

  # Check it is running
  kill -0 $process_under_test

  # Capture its child processes
  local descendants; descendants=$(get_descendants $process_under_test)

  # When it is sent the signal
  kill -s "$signal" $process_under_test

  # Then it exits successfully
  wait $process_under_test
  test $? -eq 0

  # And has no child processes
  assert_all_exited "$descendants"
}