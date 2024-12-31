#!/bin/sh
set -eu

msg() { printf '%s\n' "$*" >&2; }

if [ ! -f code ]; then
    set -eu
    case $(uname -m) in
    aarch64 | arm64) ARCH=arm64 ;;
    x86_64) ARCH=x64 ;;
    *)
        msg "Unsupported architecture"
        exit 1
        ;;
    esac

    PLATFORM=cli-alpine-${ARCH}
    QUALITY=stable
    URL=https://update.code.visualstudio.com/latest/${PLATFORM}/${QUALITY}

    if command -v curl >/dev/null; then
        DL_CMD="curl -Lk"
    elif command -v wget >/dev/null; then
        DL_CMD="wget -O-"
    else
        msg "Cannot find curl or wget"
        exit 1
    fi
    ${DL_CMD} "${URL}" | gzip -d | tar -xv
fi

if [ -f /etc/alpine-release ]; then
    apk add libstdc++
fi

./code serve-web --without-connection-token --host ::0
