#!/usr/bin/env bash
# ===========================================================================
# 本地构建 openRuyi Kiwi 镜像（riscv64）
#
# 用法:
#   ./scripts/build-local.sh [profile]
#
# 参数:
#   profile  - 构建类型: installiso / livecd / livecd_kde / all
#              默认: all（构建全部三种）
#
# 运行时:
#   - 优先使用 docker，若未安装则回退到 podman
#   - 自动通过 sudo 提权（kiwi 需要特权操作）
#
# 前置条件:
#   - docker 或 podman（建议 4.0+）
#   - 宿主机 Linux x86_64 需要安装 qemu-user-static 以运行 riscv64 容器:
#       sudo dnf install qemu-user-static   # Fedora/RHEL
#       sudo apt install qemu-user-static   # Debian/Ubuntu
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILDER_IMAGE="openruyi-kiwi-builder:local"
PROFILE="${1:-all}"

# RVA23 支持：QEMU_CPU=max 启用所有扩展（含 V / Zv* / zicond 等）
# 可被用户覆盖：QEMU_CPU=rv64,rvv=true ./scripts/build-local.sh
export QEMU_CPU="${QEMU_CPU:-max}"

# ---------- 颜色输出 ----------
INFO()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
OK()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }
WARN()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
ERROR() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# ---------- 检查 root 权限 ----------
# kiwi 构建需要 loop 设备挂载、mkfs、chroot 等特权操作，rootless 容器无法满足。
if [ "$(id -u)" -ne 0 ]; then
    INFO "kiwi 需要 root 权限来挂载 loop 设备和创建文件系统，正在通过 sudo 重新执行..."
    exec sudo "$0" "$@"
fi

# ---------- 选择容器运行时：优先 docker，回退 podman ----------
if command -v docker &>/dev/null; then
    RUNTIME="docker"
elif command -v podman &>/dev/null; then
    RUNTIME="podman"
    WARN "未找到 docker，回退使用 podman。"
else
    ERROR "未找到 docker 或 podman，请先安装其中一个。"
    exit 1
fi
INFO "使用容器运行时: $RUNTIME"

# docker/podman 通用命令封装（build / run）
img_exists() { $RUNTIME image exists "$BUILDER_IMAGE"; }
build_img()  { QEMU_CPU="$QEMU_CPU" $RUNTIME build --platform linux/riscv64 --tag "$BUILDER_IMAGE" --file Dockerfile .; }
run_img()    { QEMU_CPU="$QEMU_CPU" $RUNTIME run --rm --privileged --platform linux/riscv64 "$@"; }
# 需要把宿主 /dev 挂进去：kpartx 需要 loop + device-mapper 设备节点，
# 这些由宿主内核管理，不能只靠 --privileged 在容器内自建
run_img() {
    QEMU_CPU="$QEMU_CPU" $RUNTIME run --rm --privileged \
        --platform linux/riscv64 \
        -v /dev:/dev \
        "$@"
}

# ---------- 步骤 1: 构建 Builder 镜像 ----------
INFO "步骤 1/3: 构建 kiwi-builder 镜像（riscv64）..."

# 检查是否已有本地镜像
if img_exists; then
    INFO "发现已有 builder 镜像，如需重建请先执行: $RUNTIME rmi $BUILDER_IMAGE"
else
    cd "$REPO_DIR"
    build_img
    OK "Builder 镜像构建完成: $BUILDER_IMAGE"
fi

# ---------- 步骤 2: 确定构建 profile ----------
case "$PROFILE" in
    all)
        PROFILES=("installiso" "livecd" "livecd_kde")
        ;;
    installiso|livecd|livecd_kde)
        PROFILES=("$PROFILE")
        ;;
    *)
        ERROR "未知 profile: $PROFILE，可选: installiso / livecd / livecd_kde / all"
        exit 1
        ;;
esac

INFO "步骤 2/3: 开始构建 profile: ${PROFILES[*]}"

# ---------- 步骤 3: 执行构建 ----------
for profile in "${PROFILES[@]}"; do
    INFO "构建 [${profile}] ..."

    OUTPUT_DIR="$REPO_DIR/output/${profile}"
    mkdir -p "$OUTPUT_DIR"

    run_img \
        -v "$REPO_DIR:/workspace:Z" \
        -v "$OUTPUT_DIR:/workspace/output:Z" \
        "$BUILDER_IMAGE" \
        --profile "$profile" \
        system build \
        --description /workspace \
        --target-dir /workspace/output

    OK "[${profile}] 构建完成！产物目录: $OUTPUT_DIR"
done

# ---------- 完成 ----------
INFO "步骤 3/3: 列出产出物..."
for profile in "${PROFILES[@]}"; do
    OUTPUT_DIR="$REPO_DIR/output/${profile}"
    if [ -d "$OUTPUT_DIR" ]; then
        echo ""
        INFO "Profile: ${profile}"
        find "$OUTPUT_DIR" -type f \( -name "*.iso" -o -name "*.qcow2" -o -name "*.raw" -o -name "*.xz" \) 2>/dev/null | \
            while read -r f; do
                ls -lh "$f"
            done
    fi
done

echo ""
OK "全部完成！镜像文件位于 output/ 目录下。"
