#!/bin/sh

set -e

echo "Starting openssh"
mkdir -p /run/sshd /var/run/sshd

# enable root login and password authentication
if grep -qE '^#?PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null; then
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
else
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
fi

if grep -qE '^#?PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null; then
    sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
fi

# generate host keys if missing
ssh-keygen -A >/dev/null 2>&1 || true

# set root password from env var ROOT_PASSWORD or default to 'root'
ROOT_PASSWORD="${ROOT_PASSWORD:-root}"
echo "Setting root password to '${ROOT_PASSWORD}'"
echo "root:${ROOT_PASSWORD}" | chpasswd

# start sshd (daemonize so the script can continue)
if command -v systemctl >/dev/null 2>&1; then
    systemctl start sshd.service || true
else
    /usr/sbin/sshd || true
fi
