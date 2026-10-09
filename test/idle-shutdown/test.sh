#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "watchdog installed" test -x /usr/local/share/idle-shutdown/idle-shutdown.sh
check "default timeout is 30" grep -qx 'DEFAULT_MINUTES=30' /usr/local/share/idle-shutdown/defaults
check "watchdog running" pgrep -f /usr/local/share/idle-shutdown/idle-shutdown.sh
check "watchdog logged its timeout" grep -q 'stopping after 30m' /var/log/idle-shutdown.log

reportResults
