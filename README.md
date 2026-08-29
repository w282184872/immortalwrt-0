# ImmortalWrt MT798x 云编译

基于 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 模板，使用 GitHub Actions 自动编译 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（`openwrt-21.02` 分支，内核 5.4）固件。

## 支持的机型

| 机型 | 配置文件 | 编译工作流 |
| --- | --- | --- |
| 小米 Mi Router AX3000T | `Mi.config` | `build-Mi.yml` |
| ABT ASR3000 | `ABT.config` | `build-ABT.yml` |

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
| `Mi.config` | 小米 AX3000T 编译配置 |
| `ABT.config` | ABT ASR3000 编译配置 |
| `diy-part1.sh` | 自定义 feeds 脚本（更新 feeds 前执行） |
| `diy-part2.sh` | 编译前自定义脚本（默认 IP 已改为 192.168.6.1） |
| `.github/workflows/build-Mi.yml` | 小米 AX3000T 编译工作流 |
| `.github/workflows/build-ABT.yml` | ABT ASR3000 编译工作流 |
| `.github/workflows/update-checker.yml` | 上游源码更新检测工作流 |

## 自定义

- 修改默认登录 IP：编辑 `diy-part2.sh`
- 增删插件：编辑对应的 `.config` 后重新触发编译
- 如需上传完整 bin 目录（全部 ipk）：把工作流中 `UPLOAD_BIN_DIR` 改为 `true`（会显著增大 Artifact）

## 注意事项

- `diy-part1.sh` 中引用的 `fw876/helloworld`（ssr-plus）feed 已被 GitHub 归档、不再更新；如遇编译失败可移除该行或替换为仍在维护的 feed。
- 固件下载位置：Actions 运行记录页的 Artifacts，或 Releases 页面（tag 格式 `YYYY.MM.DD-HHMM`）。
