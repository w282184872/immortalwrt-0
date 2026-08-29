#!/usr/bin/env bash
# =============================================================
# apply-plugins.sh — 将 plugins.conf 的插件选择应用到 .config
#
# 用法: bash apply-plugins.sh <plugins.conf> [.config]
#   默认在调用目录下查找 .config（workflow 中 cd openwrt 后执行）
#
# 行为:
#   包名=y  -> 写入 CONFIG_PACKAGE_<包名>=y（启用）
#   包名=n  -> 写入 # CONFIG_PACKAGE_<包名> is not set（禁用）
#   后续由 workflow 中的 make defconfig 自动补齐依赖
# =============================================================
set -e

PLUGINS_CONF="${1:-plugins.conf}"
CONFIG_FILE="${2:-.config}"

[ -f "$PLUGINS_CONF" ] || { echo "[apply-plugins] 未找到 $PLUGINS_CONF，跳过"; exit 0; }
[ -f "$CONFIG_FILE" ]  || { echo "[apply-plugins] 未找到 $CONFIG_FILE"; exit 1; }

echo "[apply-plugins] 读取 $PLUGINS_CONF -> 应用到 $CONFIG_FILE"

apply_one() {
  local pkg="$1" val="$2"
  # 删除该包已有的配置行（=y / =m / not set），保留 INCLUDE 等子项行
  grep -v "^CONFIG_PACKAGE_${pkg}=" "$CONFIG_FILE" \
    | grep -v "^# CONFIG_PACKAGE_${pkg} is not set" > "${CONFIG_FILE}.tmp" || true
  if [ "$val" = "y" ]; then
    echo "CONFIG_PACKAGE_${pkg}=y" >> "${CONFIG_FILE}.tmp"
    echo "  [+] $pkg"
  else
    echo "# CONFIG_PACKAGE_${pkg} is not set" >> "${CONFIG_FILE}.tmp"
    echo "  [-] $pkg"
  fi
  mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

count_y=0
count_n=0

while IFS= read -r line || [ -n "$line" ]; do
  # 去掉 UTF-8 BOM、行内注释与首尾空白
  line="$(printf '%s' "$line" | sed 's/^\xef\xbb\xbf//; s/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -z "$line" ] && continue
  case "$line" in
    *=y|*=Y)
      apply_one "${line%%=*}" y
      count_y=$((count_y + 1))
      ;;
    *=n|*=N)
      apply_one "${line%%=*}" n
      count_n=$((count_n + 1))
      ;;
    *)
      echo "[apply-plugins] 跳过无法识别的行: $line"
      ;;
  esac
done < "$PLUGINS_CONF"

echo "[apply-plugins] 完成: 启用 $count_y 个, 禁用 $count_n 个"
