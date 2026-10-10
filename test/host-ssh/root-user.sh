#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "links into root's home, not vscode's" sh -c '[ "$(readlink /root/.ssh)" = /mnt/host-ssh ] && [ ! -L /home/vscode/.ssh ]'

reportResults
