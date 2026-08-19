#!/usr/bin/env bash
# download.sh — 批量下载脚本（使用 huggingface-cli）
# 在 DOWNLOADS 数组中添加下载项即可

set -euo pipefail

# ═══════════════════════════════════════════════════════════
# !! 在这里添加下载项 !!
# ═══════════════════════════════════════════════════════════
# 格式: "repo_id|文件名或模式|保存路径|repo类型"
# - repo_id: 必填，如 "stabilityai/stable-diffusion-xl-base-1.0"
# - 文件名或模式: 留空下载整个仓库，或指定文件如 "model.safetensors"，或模式如 "*.safetensors"
# - 保存路径: 留空则使用 workspace/，否则保存到指定目录
# - repo类型: 留空默认 model，可选 dataset/space
DOWNLOADS=(
    "Comfy-Org/flux1-kontext-dev_ComfyUI|split_files/diffusion_models/flux1-dev-kontext_fp8_scaled.safetensors|ComfyUI/models/unet|"
    "Comfy-Org/stable-diffusion-3.5-fp8|text_encoders/t5xxl_fp8_e4m3fn_scaled.safetensors|ComfyUI/models/clip|"
    "Comfy-Org/stable-diffusion-3.5-fp8|text_encoders/clip_l.safetensors|ComfyUI/models/clip|"
    "Comfy-Org/z_image|split_files/vae/ae.safetensors|ComfyUI/models/vae|"
    "cbmai/comfy|ClothesRemover.safetensors|ComfyUI/models/loras|"
    
    
)

# ── 目录配置 ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$SCRIPT_DIR/workspace"          # 固定工作目录：脚本同级的 workspace/

# ── 检查依赖 ──────────────────────────────────────────────
if ! command -v hf &>/dev/null; then
    echo "错误: 找不到 hf 命令，请先安装：" >&2
    echo "  pip install -U huggingface_hub[cli]" >&2
    exit 2
fi

# 检查是否已登录（尝试执行 whoami 命令）
if ! hf whoami &>/dev/null; then
    echo "警告: 未登录 Hugging Face，私有/门控仓库可能无法下载" >&2
    echo "  请先运行: hf login" >&2
fi

# ── 跳转到工作目录 ───────────────────────────────────────────
echo "→ 工作目录: $WORKSPACE"
cd "$WORKSPACE"

echo "→ 共 ${#DOWNLOADS[@]} 个下载任务"
echo "→ 假设已通过 'hf login' 登录"
echo ""

# ── 批量下载 ──────────────────────────────────────────────
SUCCESS=0
FAILED=0

for item in "${DOWNLOADS[@]}"; do
    IFS='|' read -r REPO_ID FILENAME DOWNLOAD_DIR REPO_TYPE <<< "$item"

    # 如果未指定路径，使用 workspace/
    if [[ -z "$DOWNLOAD_DIR" ]]; then
        DOWNLOAD_DIR="$WORKSPACE"
    fi

    # 确保下载目录存在
    mkdir -p "$DOWNLOAD_DIR"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "[$((SUCCESS + FAILED + 1))/${#DOWNLOADS[@]}] $REPO_ID"
    echo "文件: ${FILENAME:-<整个仓库>}"
    echo "保存: $DOWNLOAD_DIR"
    if [[ -n "$REPO_TYPE" ]]; then
        echo "类型: $REPO_TYPE"
    fi
    echo ""

    # 构建 hf download 命令
    CMD=(hf download "$REPO_ID")

    # 如果指定了文件名/模式
    if [[ -n "$FILENAME" ]]; then
        # 如果包含通配符，使用 --include
        if [[ "$FILENAME" == *"*"* ]]; then
            CMD+=(--include "$FILENAME")
        else
            CMD+=("$FILENAME")
        fi
    fi

    # 指定保存目录
    CMD+=(--local-dir "$DOWNLOAD_DIR")

    # 如果指定了仓库类型
    if [[ -n "$REPO_TYPE" ]]; then
        CMD+=(--repo-type "$REPO_TYPE")
    fi

    # 执行下载
    if "${CMD[@]}"; then
        echo "✓ 完成"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "✗ 失败" >&2
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# ── 汇总 ──────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "下载完成: $SUCCESS 成功, $FAILED 失败"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
