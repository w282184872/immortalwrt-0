#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Add a feed source
# 仅保留三个插件：luci-app-adbyby-plus / luci-app-ttyd / luci-app-passwall
# 全部第三方 feed 均已锁定为固定 commit（src-git name url^<commit>），
# 避免滚动分支更新导致编译结果不可复现；升级时手动刷新 hash 即可。
# passwall 核心依赖包 feed（Openwrt-Passwall 官方组织维护，提供 xray-core 等）
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git^ca9248d3f7c21f55b3519191ca0b85abbfc50136' >>feeds.conf.default
# 第三方 feed：iStore 应用商店（提供 luci-app-store）
echo 'src-git istore https://github.com/linkease/istore.git^3fca15b30aeed9ecacb3efc8b4a8b9c2584ad5c7' >>feeds.conf.default
# 第三方 feed：mosdns DNS 分流（提供 mosdns + luci-app-mosdns，openwrt-21.02 专用分支）
echo 'src-git mosdns https://github.com/sbwml/luci-app-mosdns.git^3154c763082c9e45c4de5fda2670e616a28345e4' >>feeds.conf.default
# 第三方 feed：任务设置插件（提供 luci-app-taskplan）
echo 'src-git taskplan https://github.com/sirpdboy/luci-app-taskplan.git^babd67a496a592ad9bd625fbc08db804cff45ab9' >>feeds.conf.default
