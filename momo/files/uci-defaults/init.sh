#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

# check momo.config.init
init=$(uci -q get momo.config.init)
[ -z "$init" ] && exit 0

# generate cryptographically strong random token for API secrets
random=$(head -c 16 /dev/urandom | hexdump -ve '1/1 "%02x"')

# set API secrets
uci set momo.mixin.external_control_api_secret="$random"
uci set momo.mixin.singbox_api_secret="$random"

# remove momo.config.init
uci del momo.config.init

# commit
uci commit momo

exit 0
