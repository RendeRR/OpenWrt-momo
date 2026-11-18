#!/bin/sh
set -e

# Momo's feed (RendeRR fork)

# check env (POSIX sh)
# this fork's feed is apk-only: packages are built with a snapshot SDK
if [ ! -x "/usr/bin/apk" ] || [ ! -x "/sbin/fw4" ]; then
	echo "only supports apk-based OpenWrt builds with firewall4!"
	exit 1
fi

# include openwrt_release
. /etc/openwrt_release

# the feed currently builds for aarch64_cortex-a53 only (e.g. GL.iNet Flint 2)
arch="$DISTRIB_ARCH"
if [ "$arch" != "aarch64_cortex-a53" ]; then
	echo "unsupported arch: $arch (this feed only builds aarch64_cortex-a53)"
	exit 1
fi

# feed urls (this fork, not the upstream momomomo.pages.dev feed)
key_url="https://raw.githubusercontent.com/RendeRR/OpenWrt-momo/main/custom-feed.pem"
feed_url="https://RendeRR.github.io/OpenWrt-momo/$arch/custommomo/packages.adb"

echo "add key"
mkdir -p /etc/apk/keys /etc/apk/repositories.d
wget -qO /etc/apk/keys/custom-feed.pem "$key_url"

echo "add feed"
echo "$feed_url" > /etc/apk/repositories.d/custommomo.list

echo "update feeds"
apk update

echo "success"
