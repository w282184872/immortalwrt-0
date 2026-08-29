---
AIGC:
    Label: "1"
    ContentProducer: 001191440300708461136T1XGW3
    ProduceID: 70cc7aa9153719fc662c314ffe010142_d24ae7a5a3f611f1abe1525400e6dd8f
    ReservedCode1: pV4Q12kf3irewf2WI8BipAxO7YTJ6/xkH44kOKXglw3AluXSNMhFs7ZUUdIn+eQfz3NI1JGipLh2dNVZvoJRoa0/ncWYl4i7TRjaAHbauqMKmOU/MUK5m8wF6exoCSDlg/rUFCa8vG4erEQVeMphNw91lP+iY3mY/gxF95Vs7Bi4qv1TI0Ko5lC2d7I=
    ContentPropagator: 001191440300708461136T1XGW3
    PropagateID: 70cc7aa9153719fc662c314ffe010142_d24ae7a5a3f611f1abe1525400e6dd8f
    ReservedCode2: pV4Q12kf3irewf2WI8BipAxO7YTJ6/xkH44kOKXglw3AluXSNMhFs7ZUUdIn+eQfz3NI1JGipLh2dNVZvoJRoa0/ncWYl4i7TRjaAHbauqMKmOU/MUK5m8wF6exoCSDlg/rUFCa8vG4erEQVeMphNw91lP+iY3mY/gxF95Vs7Bi4qv1TI0Ko5lC2d7I=
---

# immortalwrt-mt798x 两套无线配置方案

针对两台设备（小米 AX3000T、ABT ASR3000）分别生成 mtwifi-cfg 与 luci-app-mtk 两套配置文件，共 4 个 `.config`。

## 文件对应表

| 无线方案 | 小米 AX3000T (mt7981) | ABT ASR3000 (mt7981) |
|---|---|---|
| mtwifi-cfg（新，推荐） | `defconfig-mtwifi/Mi-ax3000t.config` | `defconfig-mtwifi/ABT-asr3000.config` |
| luci-app-mtk（旧） | `defconfig-mtk/Mi-ax3000t.config` | `defconfig-mtk/ABT-asr3000.config` |

## 两套方案差异

| 项目 | mtwifi-cfg | luci-app-mtk |
|---|---|---|
| 上游状态 | 当前默认，源码内 `defconfig/` | 已弃用，目录于 2024-10-14 移除（commit 2438027），仅历史版本 |
| 配置基准 | 上游 `defconfig/mt7981-ax3000.config`（最新） | 上游删除前 `defconfig/luci-app-mtk-deprecated/mt7981-ax3000.config`（commit 8fc10f5） |
| 无线控制 | mtwifi-cfg 脚本 | wifi-profile 脚本（三级 chip/dev/vif 配置） |
| LuCI 界面 | luci-app-mtwifi-cfg（界面美观，参数较少） | luci-app-mtk（界面简陋，参数几乎全可调） |
| 与 OpenWrt 原生 LuCI/netifd | 兼容 | 不兼容（使用 MTK 私有 wifi 配置） |
| 关键包 | `mtwifi-cfg`、`luci-app-mtwifi-cfg`、`luci-i18n-mtwifi-cfg-zh-cn` | `wifi-profile`、`luci-app-mtk`、`luci-i18n-mtk-zh-cn` |
| 互斥性 | 两套不可共存，编译只能二选一 | 同左 |

## 与当前源码的适配说明

- 旧版 luci-app-mtk 配置中的 `CONFIG_MTK_MT7981_NEW_FW` 选项已在当前源码移除，已替换为当前默认的驱动版本选项：
  - `CONFIG_MTK_MT_WIFI_DRIVER_VERSION_7673=y`
  - `CONFIG_MTK_MT_WIFI_MT7981_DEFAULT_FIRMWARE=y`
- 两套均精简为单机型（各自只保留目标设备的 `CONFIG_TARGET_DEVICE_*`），关闭 `CONFIG_TARGET_MULTI_PROFILE`，与现有编译仓库 workflow 的单机型编译方式一致。
- 文件内不含第三方插件选择（passwall/ssr-plus 等），插件项由现有仓库 `plugins.conf` + `apply-plugins.sh` 在 `make defconfig` 前写入；若脱离该机制使用，可参考上游 defconfig 中的 `CONFIG_PACKAGE_luci-app-passwall_INCLUDE_*` 等行自行补充。

## 使用方法

```bash
# 选用 mtwifi-cfg 方案编译 AX3000T
cp defconfig-mtwifi/Mi-ax3000t.config /path/to/workflow/Mi.config

# 选用 luci-app-mtk 方案编译 ASR3000
cp defconfig-mtk/ABT-asr3000.config /path/to/workflow/ABT.config
```

替换后需重新执行 `make defconfig` 以补全依赖。
*（内容由AI生成，仅供参考）*
