#!/bin/sh
set -e

# Momo's feed

# check env (POSIX sh)
if { [ ! -x "/bin/opkg" ] && [ ! -x "/usr/bin/apk" ]; } || [ ! -x "/sbin/fw4" ]; then
	echo "only supports OpenWrt build with firewall4!"
	exit 1
fi

# include openwrt_release
. /etc/openwrt_release

# get branch/arch
arch="$DISTRIB_ARCH"
branch=""
case "$DISTRIB_RELEASE" in
	*"24.10"*)
		branch="openwrt-24.10"
		;;
	*"25.12"*)
		branch="openwrt-25.12"
		;;
	"SNAPSHOT")
		branch="SNAPSHOT"
		;;
	*)
		echo "unsupported release: $DISTRIB_RELEASE"
		exit 1
		;;
esac

# feed url
repository_url="https://momomomo.pages.dev"
feed_url="$repository_url/$branch/$arch/momo"

if [ -x "/bin/opkg" ]; then
	echo "add key"
	key_build_pub_file="/tmp/momo-key-build.pub"
	trap 'rm -f "$key_build_pub_file"' EXIT
	wget -O "$key_build_pub_file" "$repository_url/key-build.pub"
	opkg-key add "$key_build_pub_file"
	rm -f "$key_build_pub_file"
	echo "add feed"
	if [ -f /etc/opkg/customfeeds.conf ] && grep -q momo /etc/opkg/customfeeds.conf; then
		sed -i '/momo/d' /etc/opkg/customfeeds.conf
	fi
	echo "src/gz momo $feed_url" >> /etc/opkg/customfeeds.conf
	echo "update feeds"
	opkg update
elif [ -x "/usr/bin/apk" ]; then
	echo "add key"
	mkdir -p /etc/apk/keys /etc/apk/repositories.d
	wget -O "/etc/apk/keys/momo.pem" "$repository_url/public-key.pem"
	echo "add feed"
	if [ -f /etc/apk/repositories.d/customfeeds.list ] && grep -q momo /etc/apk/repositories.d/customfeeds.list; then
		sed -i '/momo/d' /etc/apk/repositories.d/customfeeds.list
	fi
	echo "$feed_url/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
	echo "update feeds"
	apk update
fi

echo "success"
