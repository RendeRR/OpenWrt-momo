![GitHub License](https://img.shields.io/github/license/nikkinikki-org/OpenWrt-momo?style=for-the-badge&logo=github) ![GitHub Tag](https://img.shields.io/github/v/release/nikkinikki-org/OpenWrt-momo?style=for-the-badge&logo=github) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/nikkinikki-org/OpenWrt-momo/total?style=for-the-badge&logo=github) ![GitHub Repo stars](https://img.shields.io/github/stars/nikkinikki-org/OpenWrt-momo?style=for-the-badge&logo=github) [![Telegram](https://img.shields.io/badge/Telegram-gray?style=for-the-badge&logo=telegram)](https://t.me/nikkinikki_org)

English | [中文](README.zh.md)

# What's new in this fork
 
Additions on top of the original [OpenWrt-momo](https://github.com/nikkinikki-org/OpenWrt-momo) package — the web interface and service for transparent proxying via sing-box.
 
## A separate dashboard for the sing-box API
 
Previously, the only "Open Dashboard" button opened a web panel that worked exclusively through the Clash-compatible API. If that API was disabled in settings, there was no dashboard to open at all.
 
The Mixin settings now include a separate **Sing-box API Config** tab, where you can independently configure sing-box's own native API: listen address and port, access password, the web UI path and download URL, plus HTTPS with your own certificate and key.
 
A new button has appeared on the app's main page next to the old one — **Open Sing-box Dashboard**. It opens this dashboard in a new browser tab, automatically filling in the right address, port, and password.
 
## Updating the sing-box core from the web interface
 
A new **Sing-Box Update** block has appeared on the app page. The list of available sing-box versions is fetched directly from GitHub — just pick a version from the dropdown and click "Install". Downloading and installing happen without SSHing into the router, and the result is shown in a popup.
 
## Checking the profile before startup
 
A new **Format Profile** setting lets you validate and normalize the source profile (or subscription) before your own mixin settings are applied to it — helping catch config errors earlier.
 
The final check before startup is also more reliable now: previously the app formatted the final config without checking whether that succeeded, and on error it could still try to start with a broken profile. Now, if formatting fails, startup stops cleanly and the reason is logged.
 
## Small stuff
 
The "App Version" and "Core Version" fields on the status page now display more neatly — no more line wrapping.

# Momo

Transparent Proxy with sing-box on OpenWrt.

## Prerequisites

- OpenWrt >= 24.10
- Linux Kernel >= 5.13
- firewall4

## Feature

- Transparent Proxy (Redirect/TPROXY/TUN, IPv4 and/or IPv6)
- Access Control
- Profile Editor
- Scheduled Restart

## Install & Update

### A. Install From Feed (Recommended)

1. Add Feed

```shell
# only needs to be run once
wget -O - https://github.com/nikkinikki-org/OpenWrt-momo/raw/refs/heads/main/feed.sh | ash
```

2. Install

```shell
# you can install from shell or `Software` menu in LuCI
# for opkg
opkg install momo
opkg install luci-app-momo
opkg install luci-i18n-momo-zh-cn
# for apk
apk add momo
apk add luci-app-momo
apk add luci-i18n-momo-zh-cn
```

### B. Install From Release

```shell
wget -O - https://github.com/nikkinikki-org/OpenWrt-momo/raw/refs/heads/main/install.sh | ash
```

## Uninstall & Reset

```shell
wget -O - https://github.com/nikkinikki-org/OpenWrt-momo/raw/refs/heads/main/uninstall.sh | ash
```

## How To Use

See [Wiki](https://github.com/nikkinikki-org/OpenWrt-momo/wiki)

## How does it work
 
1. Run sing-box.
2. Set scheduled restart.
3. Get neccesarry param from profile.
4. Set ip rule/route.
5. Generate firewall and apply it.

Note that the steps above may change base on config.

## Compilation

```shell
# add feed
echo "src-git momo https://github.com/nikkinikki-org/OpenWrt-momo.git;main" >> "feeds.conf.default"
# update & install feeds
./scripts/feeds update -a
./scripts/feeds install -a
# make package
make package/luci-app-momo/compile
```

The package files will be found under `bin/packages/your_architecture/momo`.

## Dependencies

- ca-bundle
- curl
- firewall4
- ip-full
- kmod-inet-diag
- kmod-nft-socket
- kmod-nft-tproxy
- kmod-tun
- sing-box >= 1.12

## Contributors

[![Contributors](https://contrib.rocks/image?repo=nikkinikki-org/OpenWrt-momo)](https://github.com/nikkinikki-org/OpenWrt-momo/graphs/contributors)
