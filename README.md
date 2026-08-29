# ImmortalWrt MT798x 云编译

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板，使用 GitHub Actions 自动编译 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（`openwrt-21.02` 分支，内核 5.4）固件，支持小米 AX3000T 与 ABT ASR3000 双机型。

本项目主打**开箱即用**：

- 无线方案统一采用 **mtwifi-cfg**（`kmod-mt_wifi` 驱动 + `mtwifi-cfg` + `luci-app-mtwifi-cfg`），兼容 OpenWrt 原生 LuCI/netifd，WiFi 开箱即用；
- 修改根目录的 `plugins.conf` 即可开关插件，无需手工编辑庞大的 `.config`；
- 编译流程内置 **actions/cache + ccache** 缓存（源码依赖包 `dl` 与编译缓存 `.ccache`），二次编译大幅提速；
- 上游源码更新后自动触发编译，固件自动发布到 Releases，**保留所有版本**。

---

## 目录

- [支持的机型与默认配置](#支持的机型与默认配置)
- [无线方案说明](#无线方案说明)
- [仓库结构说明](#仓库结构说明)
- [编译缓存说明](#编译缓存说明)
- [快速上手（首次使用）](#快速上手首次使用)
- [插件开关教程（plugins.conf）](#插件开关教程pluginsconf)
- [第三方 feed 与插件安装](#第三方-feed-与插件安装)
- [自定义编译配置](#自定义编译配置)
- [自动编译流程说明](#自动编译流程说明)
- [固件下载与刷机](#固件下载与刷机)
- [常见问题（FAQ）](#常见问题faq)
- [注意事项](#注意事项)

---

## 支持的机型与默认配置

| 机型 | 配置文件 | 编译工作流 | 默认登录 IP | 默认后台密码 |
| --- | --- | --- | --- | --- |
| 小米 Mi Router AX3000T | `Mi.config` | `build-Mi.yml` | `192.168.3.1` | 无密码（首次登录自行设置） |
| ABT ASR3000 | `ABT.config` | `build-ABT.yml` | `192.168.6.1` | 无密码（首次登录自行设置） |

> 默认 IP 由各工作流中的 `env.LAN_IP` 变量注入，两台机器互不干扰。登录地址为 `http://<默认IP>`。

## 无线方案说明

两个机型均采用 **mtwifi-cfg** 无线方案，核心组件：

| 组件 | 说明 |
| --- | --- |
| `kmod-mt_wifi` | MTK 官方闭源 WiFi 驱动（`CONFIG_MTK_MT_WIFI`） |
| `mtwifi-cfg` | MTK WiFi 配置工具 |
| `luci-app-mtwifi-cfg` | 无线配置 LuCI 界面（含 `luci-i18n-mtwifi-cfg-zh-cn` 中文包） |
| 驱动版本 | `CONFIG_MTK_MT_WIFI_DRIVER_VERSION_7673`（含 MT7981 默认固件） |

完整方案配置存放在 `defconfig-mtwifi/` 目录（`Mi-ax3000t.config` / `ABT-asr3000.config`），根目录 `Mi.config` / `ABT.config` 即由这两份方案文件生成。该方案兼容 OpenWrt 原生 LuCI/netifd 流程，刷入后 2.4G / 5G WiFi 开箱即用，无需额外配置。

## 仓库结构说明

| 文件 | 作用 | 日常需要改吗 |
| --- | --- | --- |
| `Mi.config` | 小米 AX3000T 的 OpenWrt 编译配置（目标机型 + mtwifi-cfg 无线方案） | 一般不用 |
| `ABT.config` | ABT ASR3000 的 OpenWrt 编译配置（目标机型 + mtwifi-cfg 无线方案） | 一般不用 |
| `defconfig-mtwifi/` | 完整的 mtwifi-cfg 无线方案源文件（`Mi-ax3000t.config` / `ABT-asr3000.config`） | 无线方案备份/对比时看 |
| `plugins.conf` | **插件总开关**：每行一个插件，`=y` 启用、`=n` 禁用 | **常用，见下节** |
| `apply-plugins.sh` | 把 `plugins.conf` 的选择写入 `.config` 的脚本 | 不用动 |
| `diy-part1.sh` | 更新 feeds 前执行的脚本（追加第三方 feed 源） | 加新 feed 时才动 |
| `diy-part2.sh` | 编译前执行的脚本（默认 IP 注入等） | 一般不用 |
| `.github/workflows/build-Mi.yml` | 小米 AX3000T 编译工作流 | 改 IP / 编译频率时动 |
| `.github/workflows/build-ABT.yml` | ABT ASR3000 编译工作流 | 改 IP / 编译频率时动 |
| `.github/workflows/update-checker.yml` | 上游源码更新检测，有新提交则触发编译 | 改检测频率时动 |

## 编译缓存说明

两个编译工作流均内置 **actions/cache + ccache** 双重缓存：

- **`dl` 缓存**：`openwrt/dl`（源码依赖包下载目录）按工作流维度缓存，命中后跳过 `make download` 的网络下载；
- **ccache 缓存**：`openwrt/.ccache` 缓存编译中间产物，编译命令使用 `make -j$(nproc) USE_CCACHE=1`，重复编译同一源码树时可跳过大量重编译步骤。

缓存 key 由 `工作流名 + diy-part1.sh/plugins.conf/机型配置文件` 的哈希组成；配置或插件变更时自动失效并重建缓存，未变更时直接命中，二次编译通常可节省一半以上时间。

## 快速上手（首次使用）

1. **（推荐）配置 PAT 以启用自动编译**：仓库 `Settings → Secrets and variables → Actions → New repository secret`，新建名为 `ACTIONS_TRIGGER_PAT` 的 secret，值为一个勾选了 `repo` 权限的 Personal Access Token。
   - 不配置也能用（自动回退默认 token），只是自动触发编译的稳定性稍差。
2. **按需调整插件**：编辑根目录 `plugins.conf`，把想启用的插件行改成 `=y`（详见下节）。
3. **触发首次编译**：仓库 `Actions` 页面 → 左侧选择 `build-Mi` / `build-ABT` → `Run workflow`。
4. **等待编译完成**：约 30~60 分钟（视 GitHub 排队情况与缓存命中情况，二次编译更快），页面会显示步骤进度。
5. **下载固件**：进入该次运行记录 → `Artifacts` 下载固件压缩包，或到 `Releases` 页面下载（见"固件下载与刷机"）。

## 插件开关教程（plugins.conf）

### 原理

`apply-plugins.sh` 会在编译流程的 `make defconfig` 之前读取 `plugins.conf`，把每一行的选择写入 `.config`：

- `包名=y` → 写入 `CONFIG_PACKAGE_包名=y`
- `包名=n` → 写入 `# CONFIG_PACKAGE_包名 is not set`

随后 `make defconfig` 会自动补齐该插件的依赖项。因此**你只需要改 `plugins.conf`，编译结果就会跟着变**，不需要碰 `.config`。

### 语法说明

```
# 这是注释行，以 # 开头
luci-app-openclash=y    # 启用 OpenClash
luci-app-sqm=n          # 禁用 SQM
```

- 每行一个包，格式固定为 `包名=y` 或 `包名=n`；
- 支持 `#` 注释（整行注释，或行尾注释均可）；
- 支持 UTF-8 BOM（脚本会自动兼容）；
- 两个机型共用同一份 `plugins.conf`，改动对两台机器同时生效。

### 默认已启用插件（6 个）

| 插件 | 说明 |
| --- | --- |
| `luci-app-adbyby-plus` | 广告过滤（依赖 adbyby + dnsmasq-full + ipset） |
| `luci-app-passwall` | 科学上网插件（含 Xray 内核，其余 INCLUDE 均关闭） |
| `luci-app-ttyd` | 网页终端（浏览器内 SSH 登录路由器） |
| `luci-app-store` | iStore 应用商店（第三方 feed，刷机后可在商店内在线安装更多插件） |
| `luci-app-mosdns` | mosdns DNS 分流/加速（第三方 feed，含 mosdns 本体） |
| `luci-app-taskplan` | 任务设置/定时计划（第三方 feed，重启/关机/定时任务/自定义脚本） |

### 如何启用 / 禁用插件

**启用**：把对应行 `包名=n` 改为 `包名=y`，提交并推送，等待自动编译（或手动触发）。

**禁用**：把 `包名=y` 改为 `包名=n` 即可。默认未启用的插件在 `plugins.conf` 中均为 `=n`。

**新增清单外的插件**：见下节"第三方 feed 与插件安装"。

### 提示

- 若只想**某个机型**启用某插件，可把该插件直接写进对应 `.config`（`CONFIG_PACKAGE_xxx=y`），`.config` 优先级更高，会与 `plugins.conf` 合并生效。
- 个别插件（如 passwall）带 `INCLUDE_*` 子选项，如需调整请在对应 `.config` 中修改。

### 完整插件清单

清单按分类列出，除 6 个默认启用项外，其余默认为 `n`，需要哪个就把对应行改为 `y`。

#### 科学上网 / 代理 / VPN

| 插件 | 说明 |
| --- | --- |
| `luci-app-openclash` | OpenClash 客户端，基于 Clash 内核的代理管理 |
| `luci-app-ssr-plus` | SSR Plus 科学上网（SS/SSR/V2ray/Xray/Trojan） |
| `luci-app-vssr` | VSSR 科学上网（SSR 变体，支持 Xray） |
| `luci-app-naiveproxy` | NaiveProxy 客户端 |
| `luci-app-v2raya` | v2rayA 网页客户端，管理 v2ray/xray |
| `luci-app-v2ray-server` | V2ray 服务端 |
| `luci-app-trojan-server` | Trojan 服务端 |
| `luci-app-ssr-libev-server` | SSR-libev 服务端 |
| `luci-app-ssr-mudb-server` | SSR 多用户（mudb）服务端 |
| `luci-app-ssrserver-python` | SSR Python 服务端 |
| `luci-app-shadowsocks-libev` | Shadowsocks-libev 客户端/服务端 |
| `luci-app-brook-server` | Brook 代理服务端 |
| `luci-app-gost` | GOST 代理隧道（Go 语言） |
| `luci-app-haproxy-tcp` | HAProxy TCP 负载均衡 |
| `luci-app-kcptun` | Kcptun 加速隧道 |
| `luci-app-udp2raw` | UDP 转 TCP 隧道 |
| `luci-app-speederv2` | UDP 加速（Speeder） |
| `luci-app-n2n` | N2N P2P VPN |
| `luci-app-eoip` | EOIP 以太网隧道 |
| `luci-app-softether` | SoftEther VPN 客户端 |
| `luci-app-softethervpn` | SoftEtherVPN（旧版） |
| `luci-app-softethervpn5` | SoftEtherVPN 5 |
| `luci-app-vpn-policy-routing` | VPN 策略路由 |
| `luci-app-vpnbypass` | VPN 绕过指定流量 |
| `luci-app-wireguard` | WireGuard VPN |
| `luci-app-zerotier` | ZeroTier 异地组网 |
| `luci-app-yggdrasil` | Yggdrasil 网状网络 |
| `luci-app-ocserv` | OpenConnect VPN 服务端 |
| `luci-app-openvpn` | OpenVPN 客户端/服务端 |
| `luci-app-openvpn-server` | OpenVPN 服务端 |
| `luci-app-ipsec-vpnd` | IPSec VPN 服务端 |
| `luci-app-ipsec-vpnserver-manyusers` | IPSec 多用户服务端 |
| `luci-app-frpc` | frp 内网穿透客户端 |
| `luci-app-frps` | frp 内网穿透服务端 |
| `luci-app-nps` | nps 内网穿透客户端 |
| `luci-app-ngrokc` | ngrok 内网穿透 |
| `luci-app-microsocks` | SOCKS5 代理服务器 |
| `luci-app-tinyproxy` | 轻量 HTTP 代理 |
| `luci-app-polipo` | Polipo HTTP 代理 |
| `luci-app-privoxy` | Privoxy HTTP 代理（可过滤广告） |
| `luci-app-squid` | Squid 缓存代理 |
| `luci-app-fwknopd` | 端口敲门（SPA 单包认证）服务 |

#### DNS / 网络工具

| 插件 | 说明 |
| --- | --- |
| `luci-app-smartdns` | SmartDNS 本地 DNS 加速/分流 |
| `luci-app-ddns` | DDNS 动态域名（多服务商） |
| `luci-app-ddns-go` | DDNS-GO 动态域名（配置更简单） |
| `luci-app-dnscrypt-proxy` | DNSCrypt 加密 DNS 代理 |
| `luci-app-dnsforwarder` | DNS 转发器 |
| `luci-app-https-dns-proxy` | HTTPS DNS 代理（DoH） |
| `luci-app-unbound` | Unbound 递归 DNS 服务器 |
| `luci-app-adblock` | AdBlock 广告过滤（hosts 方式） |
| `luci-app-banip` | banIP 恶意 IP 黑名单 |
| `luci-app-simple-adblock` | 简易广告过滤 |
| `luci-app-nextdns` | NextDNS 客户端 |
| `luci-app-mwan3` | 多 WAN 负载均衡/故障切换 |
| `luci-app-mwan3helper` | MWAN3 助手（策略分流） |
| `luci-app-syncdial` | 多拨同步 |
| `luci-app-eqos` | EQoS 设备级限速 |
| `luci-app-qos` | QoS 带宽管理（旧版） |
| `luci-app-nft-qos` | 基于 nftables 的 QoS |
| `luci-app-sqm` | SQM 队列管理（智能 QoS） |
| `luci-app-turboacc` | TurboACC 网络加速 |
| `luci-app-upnp` | UPnP 自动端口映射 |
| `luci-app-udpxy` | UDP 组播转 HTTP 流 |
| `luci-app-natmap` | NAT 公网地址映射 |
| `luci-app-socat` | socat 端口转发工具 |
| `luci-app-wol` | 网络唤醒（Wake on LAN） |
| `luci-app-mwol` | 魔改版网络唤醒 |
| `luci-app-timewol` | 定时网络唤醒 |
| `luci-app-arpbind` | IP-MAC 绑定 |
| `luci-app-pppoe-relay` | PPPoE 中继 |
| `luci-app-pppoe-server` | PPPoE 服务端 |
| `luci-app-rp-pppoe-server` | RP-PPPoE 服务端 |
| `luci-app-accesscontrol` | 上网时间控制 |
| `luci-app-timecontrol` | 定时开关控制 |
| `luci-app-weburl` | URL 网址过滤 |
| `luci-app-webrestriction` | 网页访问限制 |
| `luci-app-commands` | 自定义命令快捷执行 |
| `luci-app-advanced-reboot` | 高级重启（重启到其他分区系统） |
| `luci-app-attendedsysupgrade` | 在线升级固件 |
| `luci-app-autoreboot` | 定时自动重启 |
| `luci-app-watchcat` | 看门狗（断网/定时重启） |
| `luci-app-cpufreq` | CPU 频率调节 |
| `luci-app-cpulimit` | 进程 CPU 占用限制 |
| `luci-app-netdata` | Netdata 实时系统监控 |
| `luci-app-vnstat` | vnStat 流量统计 |
| `luci-app-vnstat2` | vnStat 流量统计 v2 |
| `luci-app-statistics` | collectd 统计图表 |
| `luci-app-nlbwmon` | 按主机流量统计 |
| `luci-app-snmpd` | SNMP 网络管理协议服务 |
| `luci-app-diag-core` | 网络诊断工具 |
| `luci-app-cshark` | 抓包工具（tshark） |
| `luci-app-hnet` | Homenet 家庭组网协议 |
| `luci-app-travelmate` | 无线中继自动漫游 |
| `luci-app-omcproxy` | 组播代理 |
| `luci-app-bcp38` | BCP38 反 IP 欺骗过滤 |
| `luci-app-dawn` | 分布式 AP 管理（802.11k/v/r） |
| `luci-app-dynapoint` | 动态 AP 切换 |

#### 存储 / 下载 / 文件共享

| 插件 | 说明 |
| --- | --- |
| `luci-app-diskman` | 磁盘分区管理 |
| `luci-app-docker` | Docker 容器管理（精简版） |
| `luci-app-dockerman` | Docker 容器管理（完整版） |
| `luci-app-lxc` | LXC 容器管理 |
| `luci-app-samba4` | Samba4 网络文件共享 |
| `luci-app-cifs` | CIFS 客户端挂载 |
| `luci-app-cifs-mount` | CIFS 挂载（挂载 Windows 共享） |
| `luci-app-nfs` | NFS 网络文件共享 |
| `luci-app-ksmbd` | KSMBD 内核级 SMB 服务 |
| `luci-app-hd-idle` | 硬盘休眠控制 |
| `luci-app-minidlna` | DLNA 媒体服务器 |
| `luci-app-aria2` | Aria2 下载工具 |
| `luci-app-qbittorrent` | qBittorrent BT 下载 |
| `luci-app-transmission` | Transmission BT 下载 |
| `luci-app-amule` | aMule 电驴下载 |
| `luci-app-filebrowser` | 网页文件管理器 |
| `luci-app-fileassistant` | 文件助手（上传下载） |
| `luci-app-filetransfer` | 固件文件传输 |
| `luci-app-kodexplorer` | KodExplorer 私有网盘 |
| `luci-app-baidupcs-web` | 百度网盘 Web 客户端 |
| `luci-app-gowebdav` | WebDAV 文件服务器 |
| `luci-app-verysync` | 微力同步 |
| `luci-app-syncthing` | Syncthing 文件同步 |
| `luci-app-ps3netsrv` | PS3 游戏网络服务器 |
| `luci-app-oscam` | OSCAM 电视卡/读卡服务器 |
| `luci-app-nut` | NUT UPS 不间断电源监控 |
| `luci-app-alist` | Alist 网盘聚合 |
| `luci-app-radicale` | Radicale 日历/通讯录同步 |
| `luci-app-radicale2` | Radicale2 日历/通讯录同步 |
| `luci-app-xinetd` | xinetd 超级服务守护 |

#### 流媒体 / 娱乐

| 插件 | 说明 |
| --- | --- |
| `luci-app-airplay2` | AirPlay2 音频接收 |
| `luci-app-shairplay` | AirPlay 音频接收 |
| `luci-app-unblockneteasemusic` | 网易云音乐解锁灰色歌曲 |
| `luci-app-music-remote-center` | 音乐遥控中心 |
| `luci-app-mjpg-streamer` | USB 摄像头视频流 |
| `luci-app-dump1090` | ADS-B 飞机信号接收 |
| `luci-app-oled` | OLED 屏信息显示 |
| `luci-app-nginx-pingos` | Nginx + PingOS 流媒体模块 |
| `luci-app-uhttpd` | uhttpd Web 服务器 |

#### 校园网 / 认证 / 内网穿透

| 插件 | 说明 |
| --- | --- |
| `luci-app-mentohust` | 锐捷认证客户端 |
| `luci-app-minieap` | 校园网 802.1x 认证 |
| `luci-app-njitclient` | NJIT 校园网认证 |
| `luci-app-scutclient` | 华南理工大学校园网认证 |
| `luci-app-sysuh3c` | 中山大学 H3C 认证 |
| `luci-app-cd8021x` | 802.1x 有线认证客户端 |
| `luci-app-bitsrunlogin-go` | 深澜（Srun）校园网登录 |
| `luci-app-appfilter` | 应用流量过滤 |
| `luci-app-pagekitec` | PageKite 内网穿透 |

#### 打印 / USB / 系统杂项

| 插件 | 说明 |
| --- | --- |
| `luci-app-usb-printer` | USB 打印机共享 |
| `luci-app-p910nd` | 网络打印服务器 |
| `luci-app-usb3disable` | 禁用 USB3.0（减少 2.4G WiFi 干扰） |
| `luci-app-ser2net` | 串口转网络 |
| `luci-app-smstool` | 3G/4G 模块短信工具 |
| `luci-app-ledtrig-usbport` | USB 端口 LED 触发 |
| `luci-app-ledtrig-rssi` | WiFi 信号强度 LED |
| `luci-app-ledtrig-switch` | 物理按键 LED 触发 |
| `luci-app-guest-wifi` | 访客 WiFi |
| `luci-app-wifischedule` | WiFi 定时开关 |
| `luci-app-mtk` | MTK 平台专用配置 |
| `luci-app-ramfree` | 内存清理 |
| `luci-app-advancedsetting` | 高级设置（主机名/主题等） |
| `luci-app-webadmin` | 自定义 Web 管理端口 |
| `luci-app-argon-config` | Argon 主题配置 |
| `luci-app-acme` | ACME 免费证书自动申请 |
| `luci-app-acl` | 访问控制列表 |
| `luci-app-ahcp` | AHCP 自动主机配置 |
| `luci-app-airwhu` | 武汉大学校园网认证 |
| `luci-app-aliddns` | 阿里云 DDNS |
| `luci-app-babeld` | Babel 动态路由协议 |
| `luci-app-bird1-ipv4` | BIRD BGP 路由（IPv4） |
| `luci-app-bird1-ipv6` | BIRD BGP 路由（IPv6） |
| `luci-app-bmx6` | BMX6 网状路由 |
| `luci-app-bmx7` | BMX7 网状路由 |
| `luci-app-cjdns` | CJDNS 加密网状网络 |
| `luci-app-clamav` | ClamAV 杀毒引擎 |
| `luci-app-dcwapd` | DCWAPD 无线 AP 守护 |
| `luci-app-olsr` | OLSR 路由协议 |
| `luci-app-olsr-services` | OLSR 服务管理 |
| `luci-app-olsr-viz` | OLSR 拓扑可视化 |
| `luci-app-splash` | 强制门户认证（Captive Portal） |
| `luci-app-vlmcsd` | KMS 激活服务器 |
| `luci-app-wechatpush` | 微信推送通知（Server酱） |
| `luci-app-uugamebooster` | 网易 UU 加速器 |
| `luci-app-xlnetacc` | 迅雷快鸟提速 |
| `luci-app-beardropper` | 防暴力破解（Fail2ban 风格） |
| `luci-app-firewall` | 防火墙配置（系统默认） |
| `luci-app-opkg` | 软件包管理（系统默认） |

## 第三方 feed 与插件安装

### 概念

`plugins.conf` 里的包必须**存在于某个 feed 中**才能编译。上游 `immortalwrt-mt798x` 自带大量插件（即上面清单），但 iStore 商店类、个人维护的 luci 应用等不在其中。这类插件需要先通过 **feed 源** 引入，再在 `plugins.conf` 中启用。

### 添加新的第三方 feed（两步）

**第 1 步：编辑 `diy-part1.sh`**，追加一行 feed 源声明：

```bash
# 格式：src-git 自定义名 https://github.com/作者/仓库.git;分支名
echo 'src-git myapp https://github.com/xxx/luci-app-xxx.git;main' >>feeds.conf.default
```

**第 2 步：在 `plugins.conf` 中把该插件行改为 `y`**（或新增一行 `插件名=y`）。

之后 workflow 的 `feeds update -a / install -a` 会自动拉取 feed，插件即可参与编译。

### 当前内置的第三方 feed（4 个）

| Feed | 来源 | 提供插件 |
| --- | --- | --- |
| `passwall_packages` | passwall 依赖包集合 | `luci-app-passwall` 的后端/依赖（17 个） |
| `istore` | iStore 应用商店（main 分支） | `luci-app-store` 及 3 个依赖 |
| `mosdns` | mosdns（openwrt-21.02 分支） | `luci-app-mosdns` 及 2 个依赖 |
| `taskplan` | 任务计划（main 分支） | `luci-app-taskplan` |

### 第三方 feed 插件清单

界面插件（`luci-app-*`）可在 `plugins.conf` 中直接开关；**依赖组件由依赖关系自动启用，无需在 `plugins.conf` 中手动开启**（`plugins.conf` 中已列出的对应行保持 `n` 即可）。

#### passwall_packages（passwall 依赖组件，17 个）

| 包 | 说明 |
| --- | --- |
| `xray-core` | Xray 代理内核 |
| `xray-plugin` | Xray 传输插件（WebSocket/gRPC 等） |
| `sing-box` | sing-box 通用代理内核 |
| `naiveproxy` | NaiveProxy 内核 |
| `hysteria` | Hysteria 协议内核 |
| `shadowsocks-rust` | Shadowsocks Rust 实现 |
| `shadowsocksr-libev` | ShadowsocksR libev 实现 |
| `simple-obfs` | obfs 混淆插件 |
| `v2ray-plugin` | v2ray 传输插件 |
| `shadow-tls` | Shadow-TLS 流量伪装 |
| `chinadns-ng` | ChinaDNS-NG 分流 DNS |
| `dns2socks` | DNS 转 SOCKS5 |
| `ipt2socks` | iptables 流量转 SOCKS5 |
| `microsocks` | 轻量 SOCKS5 服务端 |
| `tcping` | TCP ping 连通性测试工具 |
| `geoview` | GeoIP/GeoSite 数据查看工具 |
| `v2ray-geodata` | v2ray GeoIP/GeoSite 数据包 |

#### istore（iStore 商店组件，4 个）

| 包 | 说明 |
| --- | --- |
| `luci-app-store` | iStore 应用商店（默认启用，可在商店内在线安装插件） |
| `taskd` | 商店后台任务守护进程（自动依赖） |
| `luci-lib-taskd` | taskd 的 LuCI 库（自动依赖） |
| `luci-lib-xterm` | 网页终端 xterm 库（自动依赖） |

#### mosdns（openwrt-21.02 分支，3 个）

| 包 | 说明 |
| --- | --- |
| `luci-app-mosdns` | mosdns 网页界面（默认启用） |
| `mosdns` | mosdns DNS 分流/加速器本体（自动依赖） |
| `v2dat` | geo 数据解析工具（自动依赖） |

#### taskplan（1 个）

| 包 | 说明 |
| --- | --- |
| `luci-app-taskplan` | 任务设置/定时计划（默认启用，重启/关机/定时任务/自定义脚本） |

## 自定义编译配置

| 想改什么 | 改哪里 | 说明 |
| --- | --- | --- |
| 默认登录 IP | 工作流 `env.LAN_IP`（或 `diy-part2.sh`） | 两机型各自独立 |
| 上传完整 bin 目录（全部 ipk） | 工作流 `UPLOAD_BIN_DIR` 改为 `true` | 会显著增大 Artifact |
| 上游检测频率 | `update-checker.yml` 中 `cron` 表达式 | 默认每 6 小时一次 |
| Release 保留版本数 | 工作流中相关删除逻辑 | 默认保留所有版本，不自动清理 |
| 编译目标机型 | `Mi.config` / `ABT.config` 中的 `CONFIG_TARGET_*` | 一般不用改 |

## 自动编译流程说明

```
Update Checker（每 6 小时检查上游源码）
        │  发现新提交
        ▼
repository_dispatch 触发 build-Mi.yml / build-ABT.yml
        │
        ▼
检出源码 → 初始化编译环境 → 克隆源码 → 恢复缓存（dl / .ccache）
→ 加载自定义配置
（diy-part1.sh 追加 feed → feeds update/install → diy-part2.sh 注入 IP
  → apply-plugins.sh 应用 plugins.conf → make defconfig 补齐依赖）
        │
        ▼
编译固件（USE_CCACHE=1 命中缓存加速）→ 上传 Artifacts → 发布 Releases（保留所有版本）
```

也可以手动触发：仓库 `Actions` 页面 → 选择对应工作流 → `Run workflow`（不勾选"enable workflow"可直接用默认参数运行）。

## 固件下载与刷机

- **下载位置**：
  - Actions 运行记录页 → 底部 `Artifacts`（固件压缩包）；
  - `Releases` 页面（tag 格式 `YYYY.MM.DD-HHMM`，保留所有版本）。
- **固件包内容**：解压后为 `*.bin` 固件文件，小米 AX3000T 请认准 `xiaomi_ax3000t` 前缀，ABT ASR3000 请认准 `abt_asr3000` 前缀。
- **刷机方式**：进入当前固件后台 → `系统 → 备份/升级 → 刷写新的固件`，选择对应 `*.bin` 文件即可（注意保留配置与否，跨版本建议不保留配置）。

## 常见问题（FAQ）

**Q1：编译失败，日志提示 `unknown package 'xxx'`？**
说明该插件不在任何 feed 中。先确认 `diy-part1.sh` 里是否添加了对应 feed 源，再确认 `plugins.conf` 中包名拼写正确（包名必须与 feed 中 Makefile 的 `PKG_NAME` 一致）。

**Q2：改了 `plugins.conf` 但固件里没有新插件？**
确认已提交并推送，且编译是在推送之后触发的。自动触发有 6 小时检测周期，急用可手动 `Run workflow`。

**Q3：iStore 商店打不开或提示缺少依赖？**
`luci-app-store` 依赖 `taskd`、`luci-lib-taskd`、`luci-lib-xterm`，三者是自动依赖，若被手动改成了 `=n` 或从 config 中删掉会出问题。保持 `plugins.conf` 中这些行不变（或删除对应行）即可。

**Q4：passwall 用不了某个协议？**
passwall 的协议内核（xray-core、sing-box、shadowsocks-rust 等）在 `passwall_packages` feed 中，已默认自动启用。若要启用特定 INCLUDE 子选项（如 `CONFIG_PACKAGE_luci-app-passwall_INCLUDE_*`），需编辑 `.config`。

**Q5：`diy-part1.sh` 中的 helloworld feed 报错？**
`fw876/helloworld`（ssr-plus）feed 已被 GitHub 归档、不再更新，如遇编译失败可移除该行或替换为仍在维护的 feed。

**Q6：编译后的固件没有 WiFi 或无线界面异常？**
检查 `.config` 是否包含 mtwifi-cfg 方案核心项：`CONFIG_PACKAGE_kmod-mt_wifi=y`、`CONFIG_PACKAGE_mtwifi-cfg=y`、`CONFIG_PACKAGE_luci-app-mtwifi-cfg=y`、`CONFIG_MTK_MT_WIFI_DRIVER_VERSION_7673=y`。若缺失，直接以 `defconfig-mtwifi/` 目录下的方案文件替换根目录 `Mi.config` / `ABT.config` 后重新编译。

**Q7：二次编译还是很慢，缓存没生效？**
确认工作流中 `actions/cache@v4` 步骤的 key 匹配（首次运行后才有缓存可用）；修改 `plugins.conf`、`diy-part1.sh` 或机型配置文件会导致缓存 key 变化、缓存重建，属正常现象。

## 注意事项

- 以上插件均已在 feed 内，可直接在 `plugins.conf` 选择；个别插件（如 passwall）带有 `INCLUDE_*` 子选项，如需调整请在对应 `.config` 中修改。
- `plugins.conf` 同时作用于两个机型。若只想某个机型启用某插件，请把该插件直接写进对应 `.config`（优先级更高）。
- 第三方 feed 与源码版本可能存在兼容性问题（依赖缺失、luci 版本差异），编译失败时请查看 Actions 日志中的具体报错。
- 固件下载位置：Actions 运行记录页的 Artifacts，或 Releases 页面（tag 格式 `YYYY.MM.DD-HHMM`）。
