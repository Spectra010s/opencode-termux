#!/data/data/com.termux/files/usr/bin/bash
# Select the PKGBUILD for the current architecture.
# aarch64 is the only supported target; anything else is refused.

ARCH=$(uname -m)
case "$ARCH" in
    "aarch64"|"arm64")
        echo "Using aarch64 PKGBUILD"
        cp PKGBUILD.aarch64 PKGBUILD
        ;;
    *)
        echo "Unsupported architecture: $ARCH (aarch64 only)" >&2
        exit 1
        ;;
esac
