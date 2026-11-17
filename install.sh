#!/bin/sh
set -e

# Momo's installer

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
	echo "update feeds"
	opkg update
	echo "get languages"
	languages=$(opkg list-installed 'luci-i18n-base-*' | cut -d ' ' -f 1 | cut -d '-' -f 4-)
	echo "get latest version"
	version_tmp="/tmp/momo.version"
	trap 'rm -f "$version_tmp"' EXIT
	wget -O "$version_tmp" "$feed_url/index.json"
	echo "install ipks"
	eval "$(jsonfilter -i "$version_tmp" -e "momo_version=@['packages']['momo']" -e "luci_app_momo_version=@['packages']['luci-app-momo']")"
	opkg install "$feed_url/momo_${momo_version}_${arch}.ipk"
	opkg install "$feed_url/luci-app-momo_${luci_app_momo_version}_all.ipk"
	for lang in $languages; do
		lang_version=$(jsonfilter -q -i "$version_tmp" -e "@['packages']['luci-i18n-momo-${lang}']" || true)
		if [ -n "$lang_version" ]; then
			opkg install "$feed_url/luci-i18n-momo-${lang}_${lang_version}_all.ipk" || true
		fi
	done
	rm -f "$version_tmp"
elif [ -x "/usr/bin/apk" ]; then
	echo "update feeds"
	apk update
	echo "get languages"
	languages=$(apk list --installed --manifest 'luci-i18n-base-*' | cut -d ' ' -f 1 | cut -d '-' -f 4-)
	echo "install apks from remote repository"
	apk add --allow-untrusted -X "$feed_url/packages.adb" momo luci-app-momo
	for lang in $languages; do
		apk add --allow-untrusted -X "$feed_url/packages.adb" "luci-i18n-momo-${lang}" || true
	done
fi

echo "success"
