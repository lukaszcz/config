#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for test_file in \
  "${TEST_DIR}/main_test.sh" \
  "${TEST_DIR}/system_test.sh" \
  "${TEST_DIR}/install_test.sh" \
  "${TEST_DIR}/src_config_test.sh" \
  "${TEST_DIR}/all_test.sh"; do
  printf '==> %s\n' "$(basename "${test_file}")"
  bash "${test_file}"
done

printf 'All tests passed.\n'

