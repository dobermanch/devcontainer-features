#!/usr/bin/env bash
# vscode-base only contributes customizations, which VS Code applies, not the
# container; installing cleanly is all there is to test here.
set -e
source dev-container-features-test-lib

check "container runs" true

reportResults
