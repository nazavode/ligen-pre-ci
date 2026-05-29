#!/bin/sh

if [ -d /docker-entrypoint.d ]; then
  for f in /docker-entrypoint.d/*.sh; do
      [ -f "${f}" ] && . "${f}"
  done
fi

exec "$@"
