#!/usr/bin/env bash
# Mounts can't know the container user, so the mount lands at a fixed path and
# is linked into the remote user's home here. The link dangles until the
# container starts and the mount appears.
set -e
rm -rf "${_REMOTE_USER_HOME:?}/.ssh"
ln -s /mnt/host-ssh "$_REMOTE_USER_HOME/.ssh"
chown -h "$_REMOTE_USER:" "$_REMOTE_USER_HOME/.ssh"
