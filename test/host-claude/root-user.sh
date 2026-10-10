#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "links into root's home, not vscode's" sh -c '[ "$(readlink /root/.claude)" = /mnt/host-claude ] && [ ! -L /home/vscode/.claude ]'

reportResults
