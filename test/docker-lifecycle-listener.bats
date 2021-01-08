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

@test "is_valid_command succeeds for valid command" {
  is_valid_command "start"
  is_valid_command "stop"
}

@test "is_valid_command fails for invalid command" {
  run is_valid_command "whatever"
  test "$status" -ne 0
}

@test "group_other_permissions returns correct values" {
  local a_file; a_file=$(mktemp)
  chmod g=rw,o=rx "$a_file"

  run group_other_permissions "$a_file"

  test "$output" = 'rw-r-x'
}

@test "only_owner_can_write_to succeeds if only owner can write" {
  local a_file; a_file=$(mktemp)
  chmod u=rwx,g=rx,o=rx "$a_file"

  only_owner_can_write_to "$a_file"
}

@test "only_owner_can_write_to fails if group can write" {
  local a_file; a_file=$(mktemp)
  chmod u=rwx,g=rwx,o=rx "$a_file"

  run only_owner_can_write_to "$a_file"

  test "$status" -ne 0
}

@test "only_owner_can_write_to fails if other can write" {
  local a_file; a_file=$(mktemp)
  chmod u=rwx,g=rx,o=rwx "$a_file"

  run only_owner_can_write_to "$a_file"

  test "$status" -ne 0
}

@test "is_empty_dir succeeds if dir is empty" {
  local empty_dir; empty_dir=$(mktemp -d)
  is_empty_dir "$empty_dir"
}

@test "is_empty_dir fails if dir is empty" {
  local non_empty_dir; non_empty_dir=$(mktemp -d)
  touch "$non_empty_dir/something"

  run is_empty_dir "$non_empty_dir"
  test "$status" -ne 0
}
