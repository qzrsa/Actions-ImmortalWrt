#!/bin/sh
# 99-custom.sh - 首次启动脚本
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

# 设置默认防火墙规则
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"


# Modify default IP
sed -i 's/192.168.1.1/192.168.11.50/g' package/base-files/files/bin/config_generate
sed -i "s/ImmortalWrt/OpenWrt/g" package/base-files/files/bin/config_generate
    

# 设置编译信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="by 丶曲終人散ゞ"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
