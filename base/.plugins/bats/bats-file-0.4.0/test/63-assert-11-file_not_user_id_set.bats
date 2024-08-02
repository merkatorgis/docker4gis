#!/usr/bin/env bats

load 'test_helper'
fixtures 'exist'

setup () {
  touch ${TEST_FIXTURE_ROOT}/dir/useridset ${TEST_FIXTURE_ROOT}/dir/useridnotset
  chmod u+s ${TEST_FIXTURE_ROOT}/dir/useridset
  
}
teardown () {
  
  rm -f ${TEST_FIXTURE_ROOT}/dir/useridset ${TEST_FIXTURE_ROOT}/dir/useridnotset
}


# Correctness
@test 'assert_file_not_user_id_set() <file>: returns 0 if <file> user id is not set' {
  local -r file="${TEST_FIXTURE_ROOT}/dir/useridnotset"
  run assert_file_not_user_id_set "$file"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 0 ]
}

@test 'assert_file_not_user_id_set() <file>: returns 1 and displays path if <file> user id is set, but it was expected not to be' {
  local -r file="${TEST_FIXTURE_ROOT}/dir/useridset"
  run assert_file_not_user_id_set "$file"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" == '-- user id is set, but it was expected not to be --' ]
  [ "${lines[1]}" == "path : $file" ]
  [ "${lines[2]}" == '--' ]
}


# Transforming path
@test 'assert_file_not_user_id_set() <file>: replace prefix of displayed path' {
  local -r BATSLIB_FILE_PATH_REM="#${TEST_FIXTURE_ROOT}"
  local -r BATSLIB_FILE_PATH_ADD='..'
  run assert_file_not_user_id_set "${TEST_FIXTURE_ROOT}/dir/useridset"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" == '-- user id is set, but it was expected not to be --' ]
  [ "${lines[1]}" == "path : ../dir/useridset" ]
  [ "${lines[2]}" == '--' ]
}

@test 'assert_file_not_user_id_set() <file>: replace suffix of displayed path' {
  local -r BATSLIB_FILE_PATH_REM='%dir/useridset'
  local -r BATSLIB_FILE_PATH_ADD='..'
  run assert_file_not_user_id_set "${TEST_FIXTURE_ROOT}/dir/useridset"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" == '-- user id is set, but it was expected not to be --' ]
  [ "${lines[1]}" == "path : ${TEST_FIXTURE_ROOT}/.." ]
  [ "${lines[2]}" == '--' ]
}

@test 'assert_file_not_user_id_set() <file>: replace infix of displayed path' {
  local -r BATSLIB_FILE_PATH_REM='dir/useridset'
  local -r BATSLIB_FILE_PATH_ADD='..'
  run assert_file_not_user_id_set "${TEST_FIXTURE_ROOT}/dir/useridset"
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 3 ]
  [ "${lines[0]}" == '-- user id is set, but it was expected not to be --' ]
  [ "${lines[1]}" == "path : ${TEST_FIXTURE_ROOT}/.." ]
  [ "${lines[2]}" == '--' ]
}
