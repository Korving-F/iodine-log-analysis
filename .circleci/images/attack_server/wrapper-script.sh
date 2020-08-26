#!/usr/bin/env bash

# Start sshd
/usr/sbin/sshd -D
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start sshd: $status"
  exit $status
fi

which iodined

# Start the Iodine Daemon (-4 ipv4, -c Disable Client IP/port check on each request, -f tunnel IP, domain, -P password)
iodined -4 -c -f 10.0.0.1 example.attack -P abc123
