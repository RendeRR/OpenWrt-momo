#!/bin/sh

# stop service first so nftables rules and policy routes are cleaned up
if [ -x "/etc/init.d/momo" ]; then
	/etc/init.d/momo stop > /dev/null 2>&1 || true
	/etc/init.d/momo disable > /dev/null 2>&1 || true
fi

# uninstall packages
if [ -x "/bin/opkg" ]; then
	i18n_pkgs=$(opkg list-installed 'luci-i18n-momo-*' | cut -d ' ' -f 1)
	if [ -n "$i18n_pkgs" ]; then
		opkg remove $i18n_pkgs
	fi
	opkg remove luci-app-momo 2>/dev/null || true
	opkg remove momo 2>/dev/null || true
elif [ -x "/usr/bin/apk" ]; then
	i18n_pkgs=$(apk list --installed --manifest 'luci-i18n-momo-*' | cut -d ' ' -f 1)
	if [ -n "$i18n_pkgs" ]; then
		apk del $i18n_pkgs
	fi
	apk del luci-app-momo 2>/dev/null || true
	apk del momo 2>/dev/null || true
fi

# remove config, files, logs, and temp state
rm -f /etc/config/momo
rm -rf /etc/momo
rm -rf /var/log/momo
rm -rf /var/run/momo

# remove feed
if [ -x "/bin/opkg" ]; then
	if [ -f /etc/opkg/customfeeds.conf ] && grep -q momo /etc/opkg/customfeeds.conf; then
		sed -i '/momo/d' /etc/opkg/customfeeds.conf
	fi
	pub_tmp="/tmp/momo.pub"
	if wget -q -T 5 -O "$pub_tmp" "https://momomomo.pages.dev/key-build.pub" 2>/dev/null; then
		opkg-key remove "$pub_tmp" 2>/dev/null || true
	fi
	rm -f "$pub_tmp"
elif [ -x "/usr/bin/apk" ]; then
	if [ -f /etc/apk/repositories.d/customfeeds.list ] && grep -q momo /etc/apk/repositories.d/customfeeds.list; then
		sed -i '/momo/d' /etc/apk/repositories.d/customfeeds.list
	fi
	rm -f /etc/apk/keys/momo.pem
fi
