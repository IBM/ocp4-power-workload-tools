#!/usr/bin/env sh

set -e

loglevel="${loglevel:-}"

USERID=$(id -u)

# if the first argument look like a parameter (i.e. start with '-'), run Envoy
if [ "${1#-}" != "$1" ]; then
    set -- envoy "$@"
fi

if [ "$1" = 'envoy' ]; then
    # set the log level if the $loglevel variable is set
    if [ -n "$loglevel" ]; then
        set -- "$@" --log-level "$loglevel"
    fi
fi

if [ "$ENVOY_UID" != "0" ] && [ "$USERID" = 0 ]; then
    if [ -n "$ENVOY_UID" ]; then
        usermod -u "$ENVOY_UID" envoy
    fi
    if [ -n "$ENVOY_GID" ]; then
        groupmod -g "$ENVOY_GID" envoy
    fi
    # Ensure the envoy user is able to write to container logs
    chown envoy:envoy /dev/stdout /dev/stderr
    # Drop to the envoy user. Upstream uses `su-exec`, which is not packaged
    # for Fedora; `setpriv` from util-linux provides the same behaviour and
    # is already present in fedora-minimal via util-linux-core.
    exec setpriv --reuid=envoy --regid=envoy --init-groups --inh-caps=-all "$@"
else
    exec "$@"
fi
