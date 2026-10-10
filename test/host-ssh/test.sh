#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "~/.ssh links to the host mount" sh -c '[ "$(readlink ~/.ssh)" = /mnt/host-ssh ]'
check "the host mount is read-only" sh -c "grep ' /mnt/host-ssh ' /proc/mounts | grep -qE '\sro[,\s]'"

reportResults
