#!/bin/sh

# paths
PROG="/usr/bin/mihomo"
HOME_DIR="/etc/nikki"
PROFILES_DIR="$HOME_DIR/profiles"
SUBSCRIPTIONS_DIR="$HOME_DIR/subscriptions"
MIXIN_FILE_PATH="$HOME_DIR/mixin.yaml"
RUN_DIR="$HOME_DIR/run"
RUN_PROFILE_PATH="$RUN_DIR/config.yaml"
PROVIDERS_DIR="$RUN_DIR/providers"
RULE_PROVIDERS_DIR="$PROVIDERS_DIR/rule"
PROXY_PROVIDERS_DIR="$PROVIDERS_DIR/proxy"
GEOIP_DAT_PATH="$RUN_DIR/GeoIP.dat"
GEOIP_V2RAY_PATH="/usr/share/v2ray/geoip.dat"
GEOSITE_PATH="$RUN_DIR/GeoSite.dat"
GEOSITE_V2RAY_PATH="/usr/share/v2ray/geosite.dat"

# log
LOG_DIR="/var/log/nikki"
APP_LOG_PATH="$LOG_DIR/app.log"
CORE_LOG_PATH="$LOG_DIR/core.log"

# temp
TEMP_DIR="/var/run/nikki"
PID_FILE_PATH="$TEMP_DIR/nikki.pid"
STARTED_FLAG_PATH="$TEMP_DIR/started.flag"
BRIDGE_NF_CALL_IPTABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_iptables.flag"
BRIDGE_NF_CALL_IP6TABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_ip6tables.flag"

# ucode
UCODE_DIR="$HOME_DIR/ucode"
INCLUDE_UCODE="$UCODE_DIR/include.uc"
MIXIN_UC="$UCODE_DIR/mixin.uc"
HIJACK_UT="$UCODE_DIR/hijack.ut"

# scripts
SH_DIR="$HOME_DIR/scripts"
INCLUDE_SH="$SH_DIR/include.sh"
FIREWALL_INCLUDE_SH="$SH_DIR/firewall_include.sh"

# nftables
NFT_DIR="$HOME_DIR/nftables"
RESERVED_IP_NFT="$NFT_DIR/reserved_ip.nft"
RESERVED_IP6_NFT="$NFT_DIR/reserved_ip6.nft"
GEOIP_CN_NFT="$NFT_DIR/geoip_cn.nft"
GEOIP6_CN_NFT="$NFT_DIR/geoip6_cn.nft"

# functions
format_filesize() {
	local kb; kb=1024
	local mb; mb=$((kb * 1024))
	local gb; gb=$((mb * 1024))
	local tb; tb=$((gb * 1024))
	local pb; pb=$((tb * 1024))
	local size; size="$1"
	if [ -z "$size" ]; then
		echo ""
	elif [ "$size" -lt "$kb" ]; then
		echo "$size B"
	elif [ "$size" -lt "$mb" ]; then
		echo "$(awk "BEGIN {print $size / $kb}") KB"
	elif [ "$size" -lt "$gb" ]; then
		echo "$(awk "BEGIN {print $size / $mb}") MB"
	elif [ "$size" -lt "$tb" ]; then
		echo "$(awk "BEGIN {print $size / $gb}") GB"
	elif [ "$size" -lt "$pb" ]; then
		echo "$(awk "BEGIN {print $size / $tb}") TB"
	else
		echo "$(awk "BEGIN {print $size / $pb}") PB"
	fi
}

prepare_files() {
	if [ ! -d "$LOG_DIR" ]; then
		mkdir -p "$LOG_DIR"
	fi
	if [ ! -f "$APP_LOG_PATH" ]; then
		touch "$APP_LOG_PATH"
	fi
	if [ ! -f "$CORE_LOG_PATH" ]; then
		touch "$CORE_LOG_PATH"
	fi
	if [ ! -d "$TEMP_DIR" ]; then
		mkdir -p "$TEMP_DIR"
	fi
	[ -L "$GEOIP_DAT_PATH" ] && [ ! -f "$GEOIP_V2RAY_PATH" ] && rm "$GEOIP_DAT_PATH"
	[ -L "$GEOSITE_PATH" ] && [ ! -f "$GEOSITE_V2RAY_PATH" ] && rm "$GEOSITE_PATH"
	[ ! -f "$GEOIP_DAT_PATH" ] && [ -f "$GEOIP_V2RAY_PATH" ] && ln -s "$GEOIP_V2RAY_PATH" "$GEOIP_DAT_PATH"
	[ ! -f "$GEOSITE_PATH" ] && [ -f "$GEOSITE_V2RAY_PATH" ] && ln -s "$GEOSITE_V2RAY_PATH" "$GEOSITE_PATH"
}

clear_log() {
	echo -n > "$APP_LOG_PATH"
	echo -n > "$CORE_LOG_PATH"
}

log() {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$1] $2" >> "$APP_LOG_PATH"
}
