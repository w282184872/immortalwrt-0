#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP（按机型由 workflow env LAN_IP 注入：Mi=192.168.3.1，ABT=192.168.6.1）
sed -i "s/192.168.1.1/${LAN_IP:-192.168.1.1}/g" package/base-files/files/bin/config_generate

# ============================================================
# 修复 mosdns 编译报错：invalid go version '1.25.0': must match format 1.23
# ------------------------------------------------------------
# 原因：
#   sbwml/luci-app-mosdns 的 openwrt-21.02 分支在 2026-03-24（3154c76）
#   把 mosdns/v2dat 的 go.mod 升到 go 1.25.0（三段格式版本号）。
#   immortalwrt-mt798x 21.02 构建链自带的 Go 工具链为 1.20，
#   只认两段格式（如 go 1.23），解析 go 1.25.0 直接报 invalid go version。
# 方案：
#   将 feeds/packages 的 golang 工具链整体替换为 openwrt/packages master
#   （Go 1.25+），支持三段格式，可正常解析 mosdns 5.3.4。
#   若 master 版 golang-package.mk 与 21.02 构建系统不兼容，
#   把下面的 -b master 改为 -b openwrt-23.05（Go 1.22，GOTOOLCHAIN 自动下载）。
# ============================================================
rm -rf feeds/packages/lang/golang
if git clone --depth 1 -b master https://github.com/openwrt/packages.git /tmp/openwrt-packages 2>/dev/null; then
    :
else
    git clone --depth 1 -b openwrt-23.05 https://github.com/openwrt/packages.git /tmp/openwrt-packages
fi
cp -r /tmp/openwrt-packages/lang/golang feeds/packages/lang/golang
rm -rf /tmp/openwrt-packages

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
