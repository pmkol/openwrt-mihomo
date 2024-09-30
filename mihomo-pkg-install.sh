#!/bin/bash
#
# Notes: package install script for OpenWrt 22.03+
#
# Project home page:
#        https://github.com/pmkol/openwrt-mihomo
#
default_pkg_list=("mihomo" "luci-app-mihomo" "luci-i18n-mihomo-zh-cn")
default_git_path="https://github.com/pmkol/openwrt-mihomo"
pkg_name=("${default_pkg_list[@]}")
git_path="$default_git_path"

if [ ! -z "$1" ] && [[ "$1" != http* ]]; then
    pkg_name=("$1")
    shift
fi
if [ ! -z "$1" ]; then
    git_path="$1"
fi

[ ! -f /etc/openwrt_release ] && { echo "error: current system is not supported."; exit 1; }
major_version=$(grep 'DISTRIB_RELEASE=' /etc/openwrt_release | sed -E "s/.*'([0-9]+)\..*/\1/")
[ -z "${major_version}" ] && { echo "error: current release is not supported."; exit 1; }
[ "${major_version}" -lt 22 ] && { echo "error: OpenWrt releases below 22.03 are not supported."; exit 1; }
[ ! -x /bin/opkg ] && { echo "opkg: command not found."; exit 1; }

case $(uname -m) in
    x86_64)
        system_target=x86_64
        pkg_target=x86_64
        ;;
    aarch64)
        system_target=aarch64_generic
        pkg_target=aarch64_generic
        ;;
    *)
        echo "error: $(uname -m) target not supported."
        exit 1
        ;;
esac

curl -Ls "${git_path}/releases/download/${system_target}/packages.sha256sum" > /tmp/packages.sha256sum
{ ! grep -q "\.ipk" /tmp/packages.sha256sum; } && { rm /tmp/packages.sha256sum; echo "error: failed to download packages.sha256sum."; exit 1; }

for check_name in "${pkg_name[@]}"; do
    if ! grep -q " ${check_name}_" /tmp/packages.sha256sum; then
        echo "error: ${check_name} not found."
        rm /tmp/packages.sha256sum
        exit 1
    fi
done

for package_name in "${pkg_name[@]}"; do
    latest_version=$(grep " ${package_name}_" /tmp/packages.sha256sum | cut -d '_' -f 2)
    local_version=$(opkg list-installed | grep "^${package_name} " | cut -d ' ' -f 3)
    if [ "${latest_version}" = "${local_version}" ]; then
        echo "${package_name} ${local_version} is already installed."
    else
        [ "$(grep " ${package_name}_" /tmp/packages.sha256sum | cut -d '_' -f 3)" = "all.ipk" ] && pkg_target="all"
        curl -Ls "${git_path}/releases/download/${system_target}/${package_name}_${latest_version}_${pkg_target}.ipk" > "/tmp/${package_name}_${latest_version}_${pkg_target}.ipk"
        [ ! -f "/tmp/${package_name}_${latest_version}_${pkg_target}.ipk" ] && { echo "error: failed to download ${package_name}_${latest_version}_${pkg_target}.ipk."; exit 1; }
        latest_sha256=$(grep " ${package_name}_" /tmp/packages.sha256sum | cut -d ' ' -f 1)
        local_sha256=$(sha256sum /tmp/${package_name}_${latest_version}_${pkg_target}.ipk | cut -d ' ' -f 1)
        [ "$latest_sha256" != "$local_sha256" ] && { echo "error: SHA-256 checksum does not match for ${package_name}_${latest_version}_${pkg_target}.ipk."; exit 1; }
        opkg install "/tmp/${package_name}_${latest_version}_${pkg_target}.ipk"
        rm "/tmp/${package_name}_${latest_version}_${pkg_target}.ipk"
        new_version=$(opkg list-installed | grep "^${package_name} " | cut -d ' ' -f 3)
        echo "${package_name} ${new_version} is now successfully installed."
    fi
done

rm /tmp/packages.sha256sum
