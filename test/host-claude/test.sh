#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "~/.claude links to the host mount" sh -c '[ "$(readlink ~/.claude)" = /mnt/host-claude ]'
check "the host mount is writable" sh -c "grep ' /mnt/host-claude ' /proc/mounts | grep -qE '\srw[,\s]'"
check "~/.claude is also mounted at the host's path" sh -c "grep -q '/\.claude ' /proc/mounts"

reportResults
