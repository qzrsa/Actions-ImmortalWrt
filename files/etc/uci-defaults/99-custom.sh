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

# 检查PPPoE设置文件
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ -f "$SETTINGS_FILE" ]; then
    . "$SETTINGS_FILE"
    echo "PPPoE settings loaded" >> $LOGFILE
else
    echo "PPPoE settings file not found" >> $LOGFILE
fi

# 检测物理网卡
count=0
ifnames=""
for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
        count=$((count + 1))
        ifnames="$ifnames $iface_name"
    fi
done
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')
echo "Detected interfaces: $ifnames" >> $LOGFILE

# 网络设置
if [ "$count" -eq 1 ]; then
    echo "Single NIC mode" >> $LOGFILE
    uci set network.lan.proto='dhcp'
elif [ "$count" -gt 1 ]; then
    echo "Multi NIC mode" >> $LOGFILE
    wan_ifname=$(echo "$ifnames" | awk '{print $1}')
    lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)
    
    # 配置WAN口
    uci set network.wan=interface
    uci set network.wan.device="$wan_ifname"
    uci set network.wan.proto='dhcp'
    
    # 配置WAN6
    uci set network.wan6=interface
    uci set network.wan6.device="$wan_ifname"
    uci set network.wan6.proto='dhcp6'
    
    # 配置LAN口
    uci set network.lan.proto='static'
    uci set network.lan.ipaddr='192.168.11.1'
    uci set network.lan.netmask='255.255.255.0'
    
    # 更新桥接设备
    section=$(uci show network | awk -F '[.=]' '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')
    if [ -n "$section" ]; then
        uci -q delete "network.$section.ports"
        for port in $lan_ifnames; do
            uci add_list "network.$section.ports"="$port"
        done
        echo "Updated bridge ports for br-lan" >> $LOGFILE
    fi
    
    # 提交并重启网络
    uci commit network
    echo "Network configuration committed" >> $LOGFILE
    /etc/init.d/network restart
    echo "Network restarted" >> $LOGFILE
    
    # PPPoE配置
    if [ "$enable_pppoe" = "yes" ]; then
        echo "Configuring PPPoE" >> $LOGFILE
        uci set network.wan.proto='pppoe'
        uci set network.wan.username="$pppoe_account"
        uci set network.wan.password="$pppoe_password"
        uci set network.wan.peerdns='1'
        uci set network.wan.auto='1'
        uci commit network
        /etc/init.d/network restart
    fi
fi

# 其他设置
uci delete ttyd.@ttyd[0].interface
uci set dropbear.@dropbear[0].Interface=''
uci commit

# 设置编译信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="by 丶曲終人散ゞ"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
