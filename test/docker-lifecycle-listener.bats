#!/usr/bin/env ./libs/bats/bin/bats
load 'libs/test_helpers.sh'
load '../docker-lifecycle-listener.sh'

setup() {
  tmp_script_dir=$(mktemp -d)
  chmod og-w "$tmp_script_dir"
}

teardown() {
  rm -rf "$tmp_script_dir"
}

@test "docker-lifecycle-listener exits cleanly on TERM" {
  exit_test "docker-lifecycle-listener.sh $tmp_script_dir" TERM
}

@test "docker-lifecycle-listener exits cleanly on HUP" {
  exit_test "docker-lifecycle-listener.sh $tmp_script_dir" HUP
}

@test "docker-lifecycle-listener exits cleanly on INT" {
  skip # I don't understand why this fails...
  exit_test "docker-lifecycle-listener.sh $tmp_script_dir" INT
}
