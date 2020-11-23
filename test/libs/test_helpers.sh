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
  while IFS= read -r process; do
    run kill -0 "$process"
    assert_failure
  done <<< "$processes"
}
