#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "minutes option applied" grep -qx 'DEFAULT_MINUTES=5' /usr/local/share/idle-shutdown/defaults
check "watchdog logged its timeout" grep -q 'stopping after 5m' /var/log/idle-shutdown.log

reportResults
