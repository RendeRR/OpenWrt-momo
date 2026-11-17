#!/bin/sh

. "$IPKG_INSTROOT/lib/functions.sh"
. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

config_load momo
config_get_bool enabled "config" "enabled" 0
config_get_bool core_only "config" "core_only" 0
config_get_bool proxy_enabled "proxy" "enabled" 0
config_get tcp_mode "proxy" "tcp_mode"
config_get udp_mode "proxy" "udp_mode"
config_get tun_inbound_tag "core" "tun_inbound_tag"

if [ "$enabled" = 1 ] && [ "$core_only" = 0 ] && [ "$proxy_enabled" = 1 ]; then
	if [ "$tcp_mode" = "tun" ] || [ "$udp_mode" = "tun" ]; then
		tun_device=$(ucode -S -e "
			import { load_profile } from '/etc/momo/ucode/include.uc';
			const p = load_profile();
			for (let i in (p.inbounds ?? [])) {
				if (i.tag == '$tun_inbound_tag' && i.type == 'tun' && i.interface_name) {
					print(i.interface_name);
					break;
				}
			}
		")
		if [ -n "$tun_device" ]; then
			for chain in input forward; do
				handles=$(nft --json list chain inet fw4 "$chain" 2>/dev/null | jsonfilter -q -e "@['nftables'][*]['rule']" | jsonfilter -q -a -e "@[@['comment']='momo']" | jsonfilter -q -a -e "@[*]['handle']")
				for handle in $handles; do
					nft delete rule inet fw4 "$chain" handle "$handle" 2>/dev/null
				done
			done
			nft insert rule inet fw4 input iifname "$tun_device" counter accept comment "momo"
			nft insert rule inet fw4 forward oifname "$tun_device" counter accept comment "momo"
			nft insert rule inet fw4 forward iifname "$tun_device" counter accept comment "momo"
		fi
	fi
fi

exit 0
