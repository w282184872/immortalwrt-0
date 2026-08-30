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

# 升级 xray-core 到 openwrt/packages master 版（26.3.27）
# 21.02 feed 自带 xray-core 1.8.x 依赖旧版 quic-go（仅支持 Go <=1.21），
# 工具链升到 Go 1.25 后同样无法编译，必须同步升级。
if [ -d feeds/packages/net/xray-core ]; then
    rm -rf feeds/packages/net/xray-core
    cp -r /tmp/openwrt-packages/net/xray-core feeds/packages/net/xray-core
fi

# 删除 passwall_packages feed 中的重复 xray-core
# （该 feed 与 packages feed 包名重复，feeds install 时后者被跳过并产生
#   duplicate 警告；删除源码目录消除歧义，确保编译走上方替换后的版本）
if [ -d feeds/passwall_packages/xray-core ]; then
    rm -rf feeds/passwall_packages/xray-core
fi
if [ -d package/feeds/passwall_packages/xray-core ]; then
    rm -rf package/feeds/passwall_packages/xray-core
fi

rm -rf /tmp/openwrt-packages

# ============================================================
# 修复 v2ray-core 编译失败：quic-go v0.33.0 不支持 Go 1.21+
# ------------------------------------------------------------
# 原因：
#   passwall(4.68-1) 的 INCLUDE_V2ray 在 aarch64 平台默认 y
#   （default y if aarch64），强制依赖 v2ray-core；21.02 feed 的
#   v2ray-core 5.7.0 依赖 quic-go v0.33.0，明确不支持 Go 1.21+
#   （报 "can't be built on Go 1.21 yet"）。升级 Go 工具链到 1.25
#   后该问题被触发。
# 方案：
#   关闭 V2ray 系内核（v2ray-core / v2ray-plugin，均依赖旧版
#   quic-go），保留 Xray 作为 passwall 代理内核（已升级到 master
#   版 26.3.27，兼容 Go 1.25）。
# ============================================================
# 显式写入/覆盖 .config（make defconfig 会尊重已有显式设置）
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray=.*/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=.*/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' .config
grep -q '^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray' .config || echo 'CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set' >> .config
grep -q '^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin' .config || echo 'CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set' >> .config
# 显式保留 Xray 内核（默认即 y，此处确保依赖链生效；
# sed 先强制 =y，再兜底追加，避免已有 is not set 行时 grep 前缀匹配误判为已启用）
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=.*/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y/' .config
sed -i 's/^# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray is not set/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y/' .config
grep -q '^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray' .config || echo 'CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y' >> .config

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
