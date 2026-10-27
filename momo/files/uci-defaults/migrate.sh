#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

# since v1.0.2

section_placeholder=$(uci -q get momo.placeholder); [ -z "$section_placeholder" ] && uci set momo.placeholder="placeholder"

# since v1.1.0

proxy_bypass_china_mainland_ip=$(uci -q get momo.proxy.bypass_china_mainland_ip)
proxy_bypass_china_mainland_ip6=$(uci -q get momo.proxy.bypass_china_mainland_ip6)
[ -z "$proxy_bypass_china_mainland_ip6" ] && uci set momo.proxy.bypass_china_mainland_ip6=$proxy_bypass_china_mainland_ip

routing_tproxy_fw_mask=$(uci -q get momo.routing.tproxy_fw_mask); [ -z "$routing_tproxy_fw_mask" ] && uci set momo.routing.tproxy_fw_mask=0xFF
routing_tun_fw_mask=$(uci -q get momo.routing.tun_fw_mask); [ -z "$routing_tun_fw_mask" ] && uci set momo.routing.tun_fw_mask=0xFF

procd=$(uci -q get momo.procd); [ -z "$procd" ] && {
	uci set momo.procd=procd
	uci set momo.procd.fast_reload=$(uci -q get momo.config.fast_reload)
	uci del momo.config.fast_reload
}

# since v1.1.1

dummy_device=$(uci -q get momo.routing.dummy_device); [ -z "$dummy_device" ] && uci set momo.routing.dummy_device=momo-dummy

# since v1.1.2

config_scheduled_restart_cron=$(uci -q get momo.config.scheduled_restart_cron); [ -z "$config_scheduled_restart_cron" ] && uci rename momo.config.cron_expression="scheduled_restart_cron"

section_log=$(uci -q get momo.log); [ -z "$section_log" ] && {
	uci set momo.log=log
	uci set momo.log.scheduled_clear=1
	uci set momo.log.scheduled_clear_cron="*/5 * * * *"
	uci set momo.log.scheduled_clear_size_limit=1
	uci set momo.log.scheduled_clear_size_limit_unit=MB
}

section_mixin=$(uci -q get momo.mixin); [ -z "$section_mixin" ] && {
	uci set momo.mixin=mixin
	uci set momo.mixin.log_disabled='0'
	uci set momo.mixin.log_level='info'
	uci set momo.mixin.log_timestamp='1'
	uci set momo.mixin.dns_independent_cache='1'
	uci set momo.mixin.dns_reverse_mapping='1'
	uci set momo.mixin.cache_enabled='1'
	uci set momo.mixin.cache_store_fakeip='1'
	uci set momo.mixin.cache_store_rdrc='1'
	uci set momo.mixin.external_control_ui_path='ui'
	uci set momo.mixin.external_control_ui_download_url='https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip'
}

# since v1.2.1
config_clear_at_stop=$(uci -q get momo.log.clear_at_stop); [ -z "$config_clear_at_stop" ] && uci set momo.log.clear_at_stop=1

singbox_api_ui_path=$(uci -q get momo.mixin.singbox_api_ui_path); [ -z "$singbox_api_ui_path" ] && uci set momo.mixin.singbox_api_ui_path='dashboard'
singbox_api_listen=$(uci -q get momo.mixin.singbox_api_listen); [ -z "$singbox_api_listen" ] && uci set momo.mixin.singbox_api_listen='0.0.0.0:9091'
singbox_api_tls_enabled=$(uci -q get momo.mixin.singbox_api_tls_enabled); [ -z "$singbox_api_tls_enabled" ] && uci set momo.mixin.singbox_api_tls_enabled='0'

proxy_disable_quic=$(uci -q get momo.proxy.disable_quic); [ -z "$proxy_disable_quic" ] && uci set momo.proxy.disable_quic=0

# commit
uci commit momo

# exit with 0
exit 0
