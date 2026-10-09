#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "~/.ssh is a read-only mount" sh -c "grep ' /home/vscode/.ssh ' /proc/mounts | grep -qE '\sro[,\s]'"

reportResults
