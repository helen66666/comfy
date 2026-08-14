#!/usr/bin/env bash
# download.sh — 批量下载脚本
# 在 DOWNLOADS 数组中添加下载项即可

set -euo pipefail

# ═══════════════════════════════════════════════════════════
# !! 在这里添加下载项 !!
# ═══════════════════════════════════════════════════════════
# 格式: "文件名|下载链接|保存路径"
# 保存路径留空则使用 workspace/
DOWNLOADS=(
    "waiIllustriousSDXL_v170.safetensors|https://civitai.red/api/download/models/2883731?fileId=2763986|ComfyUI/models/checkpoints"
    "ponyDiffusionV6XL.safetensors|https://civitai.red/api/download/models/290640?fileId=228616|ComfyUI/models/checkpoints"
    "Small_Penis_Blowjob.safetensors|https://civitai.red/api/download/models/1140643?fileId=1045604|ComfyUI/models/loras/position"
)

# ═══════════════════════════════════════════════════════════
# !! 替换为你的 CivitAI Token !!
# ═══════════════════════════════════════════════════════════
CIVITAI_TOKEN="2ce0130a5f5d8484453ee7aa647badb7"

# ── 目录配置 ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/workspace"          # 固定工作目录：脚本同级的 workspace/

# ── 跳转到工作目录 ───────────────────────────────────────────
echo "→ 工作目录: $WORKSPACE"
cd "$WORKSPACE"

echo "→ 共 ${#DOWNLOADS[@]} 个文件"
echo ""

# ── 批量下载 ──────────────────────────────────────────────
SUCCESS=0
FAILED=0

for item in "${DOWNLOADS[@]}"; do
    IFS='|' read -r FILENAME URL DOWNLOAD_DIR <<< "$item"

    # 如果未指定路径，使用 workspace/
    if [[ -z "$DOWNLOAD_DIR" ]]; then
        DOWNLOAD_DIR="$WORKSPACE"
    fi

    # 确保下载目录存在
    mkdir -p "$DOWNLOAD_DIR"
    DEST="$DOWNLOAD_DIR/$FILENAME"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$((SUCCESS + FAILED + 1))/${#DOWNLOADS[@]}] $FILENAME"
    echo "URL:  $URL"
    echo "保存: $DEST"
    echo ""

    # 下载（优先用 curl，回退到 wget）
    if command -v curl &>/dev/null; then
        if curl -L --progress-bar --retry 3 --retry-delay 2 \
                -H "Authorization: Bearer $CIVITAI_TOKEN" \
                --output "$DEST" "$URL"; then
            echo "✓ 完成"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "✗ 失败" >&2
            FAILED=$((FAILED + 1))
        fi
    elif command -v wget &>/dev/null; then
        if wget --show-progress --tries=3 --waitretry=2 \
                --header="Authorization: Bearer $CIVITAI_TOKEN" \
                -O "$DEST" "$URL"; then
            echo "✓ 完成"
            SUCCESS=$((SUCCESS + 1))
        else
            echo "✗ 失败" >&2
            FAILED=$((FAILED + 1))
        fi
    else
        echo "错误: 找不到 curl 或 wget，请先安装其中之一。" >&2
        exit 2
    fi
    echo ""
done

# ── 汇总 ──────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "下载完成: $SUCCESS 成功, $FAILED 失败"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
