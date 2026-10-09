#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "~/.claude is a writable mount" sh -c "grep ' /home/vscode/.claude ' /proc/mounts | grep -qE '\srw[,\s]'"

reportResults
