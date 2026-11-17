#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

tproxy_table=$(uci -q get momo.routing.tproxy_route_table)
[ -z "$tproxy_table" ] && tproxy_table=80
tun_table=$(uci -q get momo.routing.tun_route_table)
[ -z "$tun_table" ] && tun_table=81

cat << EOF

# Momo Debug Info
## system
\`\`\`shell
$(cat /etc/openwrt_release 2>/dev/null)
\`\`\`
## kernel
\`\`\`
$(uname -a)
\`\`\`
## application
\`\`\`
$(
if [ -x "/bin/opkg" ]; then
	opkg list-installed "momo"
	opkg list-installed "luci-app-momo"
elif [ -x "/usr/bin/apk" ]; then
	apk list -I "momo"
	apk list -I "luci-app-momo"
fi
)
\`\`\`
## config
\`\`\`json
$(ucode -S -e '
import { cursor } from "uci";

const uci = cursor();
const config = uci.get_all("momo") ?? {};
const result = {};

for (let section_id in config) {
	const section = config[section_id];
	const section_type = section[".type"];
	if (result[section_type] == null) {
		result[section_type] = [];
	}
	push(result[section_type], section);
}
for (let section_type in result) {
	for (let section in result[section_type]) {
		delete section[".anonymous"];
		delete section[".type"];
		delete section[".name"];
		delete section[".index"];
	}
}
if (exists(result, "mixin")) {
	for (let x in result["mixin"]) {
		if (exists(x, "external_control_api_secret")) {
			x["external_control_api_secret"] = "*";
		}
		if (exists(x, "singbox_api_secret")) {
			x["singbox_api_secret"] = "*";
		}
	}
}
if (exists(result, "subscription")) {
	for (let x in result["subscription"]) {
		if (exists(x, "url")) {
			x["url"] = "*";
		}
		if (exists(x, "info_url")) {
			x["info_url"] = "*";
		}
	}
}
if (exists(result, "lan_access_control")) {
	for (let x in result["lan_access_control"]) {
		if (exists(x, "ip") && type(x["ip"]) == "array") {
			for (let i = 0; i < length(x["ip"]); i++) {
				x["ip"][i] = "*";
			}
		}
		if (exists(x, "ip6") && type(x["ip6"]) == "array") {
			for (let i = 0; i < length(x["ip6"]); i++) {
				x["ip6"][i] = "*";
			}
		}
		if (exists(x, "mac") && type(x["mac"]) == "array") {
			for (let i = 0; i < length(x["mac"]); i++) {
				x["mac"][i] = "*";
			}
		}
	}
}
delete result["placeholder"];
print(result);
')
\`\`\`
## profile
\`\`\`json
$(ucode -S -e '
import { load_profile } from "/etc/momo/ucode/include.uc";

function desensitize_inbounds(inbounds) {
	for (let x in inbounds) {
		if (exists(x, "password")) x["password"] = "*";
		if (exists(x, "users")) x["users"] = "*";
		if (exists(x, "obfs") && type(x["obfs"]) == "object" && exists(x["obfs"], "password")) {
			x["obfs"]["password"] = "*";
		}
		if (exists(x, "tls") && type(x["tls"]) == "object") {
			if (exists(x["tls"], "server_name")) x["tls"]["server_name"] = "*";
			if (exists(x["tls"], "certificate")) x["tls"]["certificate"] = "*";
			if (exists(x["tls"], "key")) x["tls"]["key"] = "*";
			if (exists(x["tls"], "acme")) x["tls"]["acme"] = {};
			if (exists(x["tls"], "reality") && type(x["tls"]["reality"]) == "object") {
				if (exists(x["tls"]["reality"], "private_key")) x["tls"]["reality"]["private_key"] = "*";
				if (exists(x["tls"]["reality"], "short_id")) x["tls"]["reality"]["short_id"] = "*";
			}
		}
		if (exists(x, "transport") && type(x["transport"]) == "object") {
			if (exists(x["transport"], "host")) x["transport"]["host"] = "*";
			if (exists(x["transport"], "path")) x["transport"]["path"] = "*";
			if (exists(x["transport"], "server_name")) x["transport"]["server_name"] = "*";
		}
	}
}

function desensitize_outbounds(outbounds) {
	const secret_fields = [
		"server", "server_port", "server_ports", "sni", "ports", "port-range",
		"uuid", "private-key", "private_key", "public-key", "public_key",
		"pre_shared_key", "auth_str", "token", "user", "username", "password"
	];
	for (let x in outbounds) {
		for (let f in secret_fields) {
			if (exists(x, f)) x[f] = "*";
		}
		if (exists(x, "obfs") && type(x["obfs"]) == "object" && exists(x["obfs"], "password")) {
			x["obfs"]["password"] = "*";
		}
		if (exists(x, "tls") && type(x["tls"]) == "object") {
			if (exists(x["tls"], "server_name")) x["tls"]["server_name"] = "*";
			if (exists(x["tls"], "certificate")) x["tls"]["certificate"] = "*";
			if (exists(x["tls"], "reality") && type(x["tls"]["reality"]) == "object") {
				if (exists(x["tls"]["reality"], "public_key")) x["tls"]["reality"]["public_key"] = "*";
				if (exists(x["tls"]["reality"], "short_id")) x["tls"]["reality"]["short_id"] = "*";
			}
		}
		if (exists(x, "transport") && type(x["transport"]) == "object") {
			if (exists(x["transport"], "host")) x["transport"]["host"] = "*";
			if (exists(x["transport"], "path")) x["transport"]["path"] = "*";
			if (exists(x["transport"], "server_name")) x["transport"]["server_name"] = "*";
		}
	}
}

function desensitize_endpoints(endpoints) {
	for (let x in endpoints) {
		if (exists(x, "private_key")) x["private_key"] = "*";
		if (exists(x, "peers") && type(x["peers"]) == "array") {
			for (let y in x["peers"]) {
				if (exists(y, "address")) y["address"] = "*";
				if (exists(y, "port")) y["port"] = "*";
				if (exists(y, "public_key")) y["public_key"] = "*";
				if (exists(y, "pre_shared_key")) y["pre_shared_key"] = "*";
			}
		}
		if (exists(x, "auth_key")) x["auth_key"] = "*";
		if (exists(x, "control_url")) x["control_url"] = "*";
	}
}

function desensitize_profile() {
	const profile = load_profile();
	if (exists(profile, "experimental") && type(profile["experimental"]) == "object" &&
	    exists(profile["experimental"], "clash_api") && type(profile["experimental"]["clash_api"]) == "object" &&
	    exists(profile["experimental"]["clash_api"], "secret")) {
		profile["experimental"]["clash_api"]["secret"] = "*";
	}
	if (exists(profile, "inbounds") && type(profile["inbounds"]) == "array") {
		desensitize_inbounds(profile["inbounds"]);
	}
	if (exists(profile, "outbounds") && type(profile["outbounds"]) == "array") {
		desensitize_outbounds(profile["outbounds"]);
	}
	if (exists(profile, "endpoints") && type(profile["endpoints"]) == "array") {
		desensitize_endpoints(profile["endpoints"]);
	}
	if (exists(profile, "services")) {
		profile["services"] = [];
	}
	return profile;
}

print(desensitize_profile());
')
\`\`\`
## ip rule
\`\`\`
$(ip rule list)
\`\`\`
## ip route
\`\`\`
TPROXY:
$(ip route list table "$tproxy_table" 2>/dev/null)

TUN:
$(ip route list table "$tun_table" 2>/dev/null)
\`\`\`
## ip6 rule
\`\`\`
$(ip -6 rule list)
\`\`\`
## ip6 route
\`\`\`
TPROXY:
$(ip -6 route list table "$tproxy_table" 2>/dev/null)

TUN:
$(ip -6 route list table "$tun_table" 2>/dev/null)
\`\`\`
## firewall tables
\`\`\`
$(nft list tables 2>/dev/null)
\`\`\`
## firewall
\`\`\`
$(nft list table inet momo 2>/dev/null)
\`\`\`
## service
\`\`\`json
$(/etc/init.d/momo info 2>/dev/null)
\`\`\`
EOF
