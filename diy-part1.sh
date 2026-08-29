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
# 注意：fw876/helloworld 已被 GitHub 归档、不再更新。
# 若后续编译失败，可注释掉下面这行，并自行添加其他仍在维护的科学上网 feed。
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
