# ImmortalWrt MT798x 云编译

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板，使用 GitHub Actions 自动编译 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（`openwrt-21.02` 分支，内核 5.4）固件。

## 支持的机型

| 机型 | 配置文件 | 编译工作流 |
| --- | --- | --- |
| 小米 Mi Router AX3000T | `Mi.config` | `build-Mi.yml` |
| ABT ASR3000 | `ABT.config` | `build-ABT.yml` |

各机型默认登录 IP 由工作流 `env.LAN_IP` 注入（Mi：`192.168.3.1`，ABT：`192.168.6.1`）。

## 自动编译流程

1. `Update Checker` 每 6 小时检查一次上游源码是否有新提交（也可在 Actions 页面手动运行）；
2. 上游有更新时，自动通过 `repository_dispatch` 触发 `build-Mi.yml` 和 `build-ABT.yml`；
3. 编译完成后固件自动上传到 **Actions Artifacts** 与 **Releases**（Release 保留最近 3 个版本）。

也可以手动触发：仓库 Actions 页面 → 选择对应工作流 → Run workflow。

## 首次配置

1. **（推荐）配置 PAT**：仓库 Settings → Secrets and variables → Actions → New repository secret，新建 `ACTIONS_TRIGGER_PAT`，值为一个勾选了 `repo` 权限的 Personal Access Token。
   - 不配置也能运行（会自动回退使用默认 token），但配置后 `Update Checker` 自动触发编译更稳定。
2. 其余无需配置，直接手动 Run 一次 `build-Mi.yml` / `build-ABT.yml` 验证即可。

## 目录结构

| 文件 | 说明 |
| --- | --- |
| `Mi.config` | 小米 AX3000T 编译配置（含 3 个默认插件） |
| `ABT.config` | ABT ASR3000 编译配置（含 3 个默认插件） |
| `plugins.conf` | **插件选择文件**：只填 `y` / `n` 即可开关插件，编译自动生效 |
| `apply-plugins.sh` | 插件选择应用脚本：读取 `plugins.conf` 并写入 `.config` |
| `diy-part1.sh` | 自定义 feeds 脚本（更新 feeds 前执行） |
| `diy-part2.sh` | 编译前自定义脚本（默认 IP 按机型注入） |
| `.github/workflows/build-Mi.yml` | 小米 AX3000T 编译工作流 |
| `.github/workflows/build-ABT.yml` | ABT ASR3000 编译工作流 |
| `.github/workflows/update-checker.yml` | 上游源码更新检测工作流 |

## 自定义

- 修改默认登录 IP：编辑各工作流 `env.LAN_IP` 或 `diy-part2.sh`
- 增删插件：**编辑 `plugins.conf`** 后重新触发编译即可（详见下节）
- 如需上传完整 bin 目录（全部 ipk）：把工作流中 `UPLOAD_BIN_DIR` 改为 `true`（会显著增大 Artifact）

## 可选插件（plugins.conf）

编译时无需再改 `.config`，只需在 `plugins.conf` 中把对应插件行改为 `y`（启用）或 `n`（禁用）。workflow 会在编译前自动把选择写入 `.config`，再经 `make defconfig` 补齐依赖。

```
luci-app-openclash=y    # 启用 OpenClash
luci-app-sqm=n          # 禁用 SQM
```

> 提示：`plugins.conf` 同时作用于两个机型。若只想某个机型启用，可把该插件在两份 config 中直接写 `CONFIG_PACKAGE_xxx=y`（config 优先级更高，会与 plugins.conf 合并）。

### 已启用插件（默认 3 个）

| 插件 | 说明 |
| --- | --- |
| `luci-app-adbyby-plus` | 广告过滤（依赖 adbyby + dnsmasq-full + ipset） |
| `luci-app-passwall` | 科学上网插件（含 Xray 内核，其余 INCLUDE 均关闭） |
| `luci-app-ttyd` | 网页终端（浏览器内 SSH 登录路由器） |

### 可选未启用插件（189 个）

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

## 注意事项

- 以上插件均已在 feed 内，可直接在 `plugins.conf` 选择；个别插件（如 passwall）带有 `INCLUDE_*` 子选项，如需调整请在对应 `.config` 中修改。
- `diy-part1.sh` 中引用的 `fw876/helloworld`（ssr-plus）feed 已被 GitHub 归档、不再更新；如遇编译失败可移除该行或替换为仍在维护的 feed。
- 固件下载位置：Actions 运行记录页的 Artifacts，或 Releases 页面（tag 格式 `YYYY.MM.DD-HHMM`）。
