#!/usr/bin/env bash

set -e

source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

Dev=$1
Build_Mod=$2

CONFIG_FILE="$BASE_PATH/deconfig/$Dev.config"
INI_FILE="$BASE_PATH/compilecfg/$Dev.ini"

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

if [[ ! -f $INI_FILE ]]; then
    echo "INI file not found: $INI_FILE"
    exit 1
fi

read_ini_by_key() {
    local key=$1
    awk -F"=" -v key="$key" '$1 == key {print $2}' "$INI_FILE"
}

REPO_URL=$(read_ini_by_key "REPO_URL")
REPO_BRANCH=$(read_ini_by_key "REPO_BRANCH")
REPO_BRANCH=${REPO_BRANCH:-main}
BUILD_DIR=$(read_ini_by_key "BUILD_DIR")
COMMIT_HASH=$(read_ini_by_key "COMMIT_HASH")
COMMIT_HASH=${COMMIT_HASH:-none}

if [[ -d $BASE_PATH/action_build ]]; then
    BUILD_DIR="action_build"
fi

$BASE_PATH/update.sh "$REPO_URL" "$REPO_BRANCH" "$BASE_PATH/$BUILD_DIR" "$COMMIT_HASH"

\cp -f "$CONFIG_FILE" "$BASE_PATH/$BUILD_DIR/.config"

cd "$BASE_PATH/$BUILD_DIR"
make defconfig

if grep -qE "^CONFIG_TARGET_x86_64=y" "$CONFIG_FILE"; then
    DISTFEEDS_PATH="$BASE_PATH/$BUILD_DIR/package/emortal/default-settings/files/99-distfeeds.conf"
    if [ -d "${DISTFEEDS_PATH%/*}" ] && [ -f "$DISTFEEDS_PATH" ]; then
        sed -i 's/aarch64_cortex-a53/x86_64/g' "$DISTFEEDS_PATH"
    fi
fi

if [[ $Build_Mod == "debug" ]]; then
    exit 0
fi

TARGET_DIR="$BASE_PATH/$BUILD_DIR/bin/targets"
if [[ -d $TARGET_DIR ]]; then
    find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec rm -f {} +
fi

# eBPF
echo "CONFIG_DEVEL=y" >> ./.config
echo "CONFIG_BPF_TOOLCHAIN_HOST=y" >> ./.config
echo "# CONFIG_BPF_TOOLCHAIN_NONE is not set" >> ./.config
echo "CONFIG_KERNEL_BPF_EVENTS=y" >> ./.config
echo "CONFIG_KERNEL_CGROUP_BPF=y" >> ./.config
echo "CONFIG_KERNEL_DEBUG_INFO=y" >> ./.config
echo "CONFIG_KERNEL_DEBUG_INFO_BTF=y" >> ./.config
echo "# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set" >> ./.config
echo "CONFIG_KERNEL_XDP_SOCKETS=y" >> ./.config

#修改jdc re-ss-01 (亚瑟) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-ss-01/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改jdc re-cs-02 (雅典娜) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-02/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改jdc re-cs-07 (太乙) 的内核大小为12M
sed -i "/^define Device\/jdcloud_re-cs-07/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改mr7350 (领势LINKSYS MR7350) 的内核大小为12M
sed -i "/^define Device\/linksys_mr7350/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
#修改redmi_ax5-jdcloud(京东云红米AX5) 的内核大小为12M
sed -i "/^define Device\/redmi_ax5-jdcloud/,/^endef/ { /KERNEL_SIZE := 6144k/s//KERNEL_SIZE := 12288k/ }" target/linux/qualcommax/image/ipq60xx.mk
# 想要剔除的
# echo "CONFIG_PACKAGE_htop=n" >> ./.config
# echo "CONFIG_PACKAGE_iperf3=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-wolplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-tailscale=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-advancedplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-kucat=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-mihomo=n" >> ./.config
# 使用opkg替换apk安装器
# echo "CONFIG_PACKAGE_opkg=y" >> ./.config
# echo "CONFIG_OPKG_USE_CURL=y" >> ./.config
# echo "# CONFIG_USE_APK is not set" >> ./.config
# 可以让FinalShell查看文件列表并且ssh连上不会自动断开
echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
# base64 修改码云上的内容 需要用到
echo "CONFIG_PACKAGE_coreutils-base64=y" >> ./.config
echo "CONFIG_PACKAGE_coreutils=y" >> ./.config
# 简单明了的系统资源占用查看工具
echo "CONFIG_PACKAGE_btop=y" >> ./.config
# 多网盘存储
echo "CONFIG_PACKAGE_luci-app-alist=y" >> ./.config
# 强大的工具Lucky大吉(需要添加源或git clone)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# 网络通信工具
echo "CONFIG_PACKAGE_curl=y" >> ./.config
echo "CONFIG_PACKAGE_tcping=y" >> ./.config
# BBR 拥塞控制算法(终端侧)
# echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# echo "CONFIG_DEFAULT_tcp_bbr=y" >> ./.config
# 磁盘管理
echo "CONFIG_PACKAGE_luci-app-diskman=y" >> ./.config
echo "CONFIG_PACKAGE_cfdisk=y" >> ./.config
# 其他调整
# 大鹅
echo "CONFIG_PACKAGE_luci-app-daed=y" >> ./.config
# 大鹅-next
# echo "CONFIG_PACKAGE_luci-app-daed-next=y" >> ./.config
# 连上ssh不会断开并且显示文件管理
echo "CONFIG_PACKAGE_opeh-sftp-server"=y
# docker只能集成
echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config
# qBittorrent
echo "CONFIG_PACKAGE_luci-app-qbittorrent=y" >> ./.config
# 添加Homebox内网测速
# echo "CONFIG_PACKAGE_luci-app-homebox=y" >> ./.config
# V2rayA
echo "CONFIG_PACKAGE_luci-app-v2raya=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-core=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-geoip=y" >> ./.config
echo "CONFIG_PACKAGE_v2ray-geosite=y" >> ./.config
# NSS的sqm
# echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
# echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
# NSS MASH
# echo "CONFIG_ATH11K_NSS_MESH=y" >> ./.config
# 不知道什么 加上去
# echo "CONFIG_PACKAGE_MAC80211_NSS_REDIRECT=y" >> ./.config
# istore 编译报错
# echo "CONFIG_PACKAGE_luci-app-istorex=y" >> ./.config
# QuickStart
# echo "CONFIG_PACKAGE_luci-app-quickstart=y" >> ./.config
# filebrowser-go
echo "CONFIG_PACKAGE_luci-app-filebrowser-go=y" >> ./.config
# 图形化web UI luci-app-uhttpd	
echo "CONFIG_PACKAGE_luci-app-uhttpd=y" >> ./.config
# 多播
# echo "CONFIG_PACKAGE_luci-app-syncdial=y" >> ./.config
# MosDNS
echo "CONFIG_PACKAGE_luci-app-mosdns=y" >> ./.config
# Natter2 报错
# echo "CONFIG_PACKAGE_luci-app-natter2=y" >> ./.config
# 文件管理器
echo "CONFIG_PACKAGE_luci-app-filemanager=y" >> ./.config
# 不要coremark 避免多线程编译报错
# echo "CONFIG_PACKAGE_coremark=n" >> ./.config
# 基于Golang的多协议转发工具
echo "CONFIG_PACKAGE_luci-app-gost=y" >> ./.config
# Go语言解析
# echo "CONFIG_PACKAGE_golang=y" >> ./.config
# Git
echo "CONFIG_PACKAGE_git-http=y" >> ./.config
# Nginx替换Uhttpd
# echo "CONFIG_PACKAGE_nginx-mod-luci=y" >> ./.config
# Nginx的图形化界面
# echo "CONFIG_PACKAGE_luci-nginxer=y" >> ./.config
# HAProxy 比Nginx更强大的反向代理服务器
echo "CONFIG_PACKAGE_luci-app-haproxy-tcp=y" >> ./.config
# Adguardhome去广告
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> ./.config
# cloudflre速度筛选器
echo "CONFIG_PACKAGE_luci-app-cloudflarespeedtest=y" >> ./.config
# OpenClash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> ./.config

make download -j$(($(nproc) * 2))
make -j$(($(nproc) + 1)) || make -j1 V=s

FIRMWARE_DIR="$BASE_PATH/firmware"
\rm -rf "$FIRMWARE_DIR"
mkdir -p "$FIRMWARE_DIR"
find "$TARGET_DIR" -type f \( -name "*.bin" -o -name "*.manifest" -o -name "*efi.img.gz" -o -name "*.itb" -o -name "*.fip" -o -name "*.ubi" -o -name "*rootfs.tar.gz" \) -exec cp -f {} "$FIRMWARE_DIR/" \;
\rm -f "$BASE_PATH/firmware/Packages.manifest" 2>/dev/null

if [[ -d $BASE_PATH/action_build ]]; then
    make clean
fi
