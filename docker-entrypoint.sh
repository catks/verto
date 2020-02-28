#!/bin/sh

set -e

if [[ -n "${SSH_PRIVATE_KEY}" ]]; then
  eval `ssh-agent -s` > /dev/null
  ssh-add $SSH_PRIVATE_KEY 2> /dev/null
fi

exec verto "$@"

