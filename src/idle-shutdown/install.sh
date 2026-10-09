#!/usr/bin/env bash
# Installs the idle-shutdown watchdog. Runs as root at image build time.
set -euo pipefail

MINUTES="${MINUTES:-30}"
case "$MINUTES" in
  ''|*[!0-9]*) echo "idle-shutdown: minutes must be a whole number, got '$MINUTES'" >&2; exit 1 ;;
esac

# ps/pgrep (procps) and flock/setsid (util-linux); slim images can lack procps.
if ! command -v pgrep >/dev/null || ! command -v flock >/dev/null || ! command -v setsid >/dev/null; then
  apt-get update
  apt-get install -y --no-install-recommends procps util-linux
  rm -rf /var/lib/apt/lists/*
fi

install -d /usr/local/share/idle-shutdown
install -m 0755 idle-shutdown.sh /usr/local/share/idle-shutdown/idle-shutdown.sh
echo "DEFAULT_MINUTES=$MINUTES" > /usr/local/share/idle-shutdown/defaults

# Feature entrypoints run one after another in PID 1's shell at every container
# start and must return, so the watchdog is detached into its own session.
cat > /usr/local/share/idle-shutdown/entrypoint.sh <<'EOF'
#!/bin/sh
setsid nohup /usr/local/share/idle-shutdown/idle-shutdown.sh \
  >> /var/log/idle-shutdown.log 2>&1 < /dev/null &
EOF
chmod 0755 /usr/local/share/idle-shutdown/entrypoint.sh
