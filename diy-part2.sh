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
#   将 feeds/packages 的 golang 工具链整体替换为 openwrt/packages 固定
#   commit（1c2ce76，Go 1.25+），支持三段格式，可正常解析 mosdns 5.3.4。
#   固定 commit 保证结果可复现；仅当 fetch 该 commit 失败时兜底回退
#   到 master 滚动分支（此时结果不再可复现，需及时刷新下方 hash）。
# ============================================================
rm -rf feeds/packages/lang/golang /tmp/openwrt-packages
git init -q /tmp/openwrt-packages
git -C /tmp/openwrt-packages remote add origin https://github.com/openwrt/packages.git
# fetch 固定 commit，最多重试 3 次（Actions 网络偶发失败会导致回退，必须避免）
ok=0
for i in 1 2 3; do
    if git -C /tmp/openwrt-packages fetch --depth 1 origin 1c2ce769a8a87cc41caf23397628b1eaa8875c82 2>/dev/null; then
        git -C /tmp/openwrt-packages reset --hard -q FETCH_HEAD
        ok=1
        break
    fi
    sleep 3
done
if [ "$ok" = "0" ]; then
    git -C /tmp/openwrt-packages fetch --depth 1 origin master
    git -C /tmp/openwrt-packages reset --hard -q FETCH_HEAD
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
# 注意：kconfig 禁用行的合法格式必须带 "# " 前缀（"# CONFIG_X is not set"）。
# 不带 # 的 "CONFIG_X is not set" 是非法行，make defconfig 会忽略并回退到
# 默认值（passwall INCLUDE_V2ray 在 aarch64 默认 y），导致 v2ray-core 仍被编译。
# 先纠正历史遗留的非法行（无 # 前缀），再写合法格式，最后兜底追加。
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set$/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set$/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray=.*/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set/' .config
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=.*/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set/' .config
grep -q '^# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set' .config || echo '# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set' >> .config
grep -q '^# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set' .config || echo '# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set' >> .config
# 显式保留 Xray 内核（默认即 y，此处确保依赖链生效；
# sed 先强制 =y，再兜底追加，避免已有 is not set 行时 grep 前缀匹配误判为已启用）
sed -i 's/^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=.*/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y/' .config
sed -i 's/^# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray is not set/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y/' .config
grep -q '^CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y' .config || echo 'CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y' >> .config

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
