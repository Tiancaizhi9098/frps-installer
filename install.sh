#!/bin/bash

# frps一键安装脚本
# 支持多版本选择，自动配置自启动
# Github: https://github.com/Tiancaizhi9098/frps-installer

# 显示彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${GREEN}=== frps一键安装脚本 ===${NC}"
echo -e "${BLUE}GitHub: https://github.com/Tiancaizhi9098/frps-installer${NC}"

# 检查权限
if [ "$(id -u)" != "0" ]; then
   echo -e "${YELLOW}提示: 当前非root用户，部分功能可能受限${NC}"
   echo -e "${YELLOW}建议使用root权限运行此脚本以确保完整功能${NC}"
   # 不退出，继续执行
fi

# 检测系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    arm*)
        ARCH="arm"
        ;;
    *)
        echo -e "${RED}不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}检测到系统架构: $ARCH${NC}"

# 获取最新版本号
get_latest_version() {
    LATEST=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -Po '"tag_name": "v\K.*?(?=")')
    if [ -z "$LATEST" ]; then
        LATEST="0.51.3" # 默认版本
        echo -e "${YELLOW}获取最新版本失败，使用默认版本${NC}"
    else
        echo -e "${GREEN}获取最新版本成功: v$LATEST${NC}"
    fi
    echo $LATEST
}

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
fi

# 版本选择
echo -e "\n${BLUE}========== frps版本选择 ==========${NC}"
LATEST_VERSION=$(get_latest_version)
echo -e "1. v0.51.3 (使用ini配置文件格式)"
echo -e "2. v$LATEST_VERSION (最新版本)"
echo -e "3. 自定义版本"

read -p "请选择版本 [1]: " version_choice
version_choice=${version_choice:-1}

case $version_choice in
    1)
        FRP_VERSION="0.51.3"
        CONFIG_FORMAT="ini"
        ;;
    2)
        FRP_VERSION="$LATEST_VERSION"
        # 版本号比较，确定配置文件格式
        if [ "$(printf '%s\n' "0.52.0" "$LATEST_VERSION" | sort -V | head -n1)" = "0.52.0" ]; then
            CONFIG_FORMAT="toml"
        else
            CONFIG_FORMAT="ini"
        fi
        ;;
    3)
        read -p "请输入版本号 (例如 0.51.3): " FRP_VERSION
        if [ -z "$FRP_VERSION" ]; then
            FRP_VERSION="0.51.3"
            CONFIG_FORMAT="ini"
        elif [ "$(printf '%s\n' "0.52.0" "$FRP_VERSION" | sort -V | head -n1)" = "0.52.0" ]; then
            CONFIG_FORMAT="toml"
        else
            CONFIG_FORMAT="ini"
        fi
        ;;
    *)
        FRP_VERSION="0.51.3"
        CONFIG_FORMAT="ini"
        ;;
esac

echo -e "${GREEN}已选择 frp v${FRP_VERSION}, 配置文件格式: ${CONFIG_FORMAT}${NC}"

# 生成随机token (32位字母数字组合)
RANDOM_TOKEN=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)

# 配置参数设置
echo -e "\n${BLUE}========== frps配置参数设置 ==========${NC}"
echo -e "${YELLOW}请设置参数或直接按Enter使用默认值${NC}"

# 让用户自定义配置
read -p "服务器绑定端口 [7000]: " bind_port
bind_port=${bind_port:-7000}

read -p "Dashboard管理面板端口 [7500]: " dashboard_port
dashboard_port=${dashboard_port:-7500}

read -p "Dashboard用户名 [admin]: " dashboard_user
dashboard_user=${dashboard_user:-admin}

read -p "Dashboard密码 [admin]: " dashboard_pwd
dashboard_pwd=${dashboard_pwd:-admin}

read -p "认证Token [随机生成的token]: " token
token=${token:-$RANDOM_TOKEN}

read -p "虚拟主机HTTP端口 [80]: " vhost_http_port
vhost_http_port=${vhost_http_port:-80}

read -p "虚拟主机HTTPS端口 [443]: " vhost_https_port
vhost_https_port=${vhost_https_port:-443}

read -p "服务器域名/IP [$SERVER_IP]: " subdomain_host
subdomain_host=${subdomain_host:-$SERVER_IP}

# 安装目录
read -p "安装目录 [/usr/local/frp]: " INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-/usr/local/frp}

# 创建临时目录
TMP_DIR=$(mktemp -d)
cd $TMP_DIR

# 下载frp
DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz"

echo -e "\n${YELLOW}开始下载frp v${FRP_VERSION}...${NC}"
echo -e "${YELLOW}下载地址: ${DOWNLOAD_URL}${NC}"
curl -L -o frp.tar.gz $DOWNLOAD_URL

if [ $? -ne 0 ]; then
    echo -e "${RED}下载失败，请检查网络连接或版本号是否正确${NC}"
    rm -rf $TMP_DIR
    exit 1
fi

# 解压
echo -e "${YELLOW}解压文件...${NC}"
tar -xzf frp.tar.gz
cd frp_${FRP_VERSION}_linux_${ARCH}

# 创建安装目录
echo -e "${YELLOW}创建安装目录: $INSTALL_DIR${NC}"
mkdir -p $INSTALL_DIR

# 复制文件
cp frps $INSTALL_DIR/
chmod 755 $INSTALL_DIR/frps

# 根据不同版本创建不同格式的配置文件
echo -e "${YELLOW}创建配置文件...${NC}"

if [ "$CONFIG_FORMAT" = "ini" ]; then
    # INI 格式配置文件
    cat > $INSTALL_DIR/frps.ini << EOF
[common]
# 运行frps服务的端口
bind_port = ${bind_port}
# 访问Dashboard的端口
dashboard_port = ${dashboard_port}
# Dashboard登录用户名和密码
dashboard_user = ${dashboard_user}
dashboard_pwd = ${dashboard_pwd}
# 连接frps的token，客户端需要与此一致
token = ${token}
# 是否启用TCP多路复用
tcp_mux = true
# 允许客户端端口范围
allow_ports = 10000-50000

# 虚拟主机HTTP/HTTPS设置
vhost_http_port = ${vhost_http_port}
vhost_https_port = ${vhost_https_port}
subdomain_host = ${subdomain_host}

# 日志设置
log_file = /var/log/frps.log
log_level = info
log_max_days = 3
EOF
    CONFIG_FILE="$INSTALL_DIR/frps.ini"
    echo -e "${GREEN}已创建INI格式配置文件: $CONFIG_FILE${NC}"
else
    # TOML 格式配置文件
    cat > $INSTALL_DIR/frps.toml << EOF
# frps.toml
bindPort = ${bind_port}

webServer.addr = "0.0.0.0"
webServer.port = ${dashboard_port}
webServer.user = "${dashboard_user}"
webServer.password = "${dashboard_pwd}"

auth.token = "${token}"

transport.tcpMux = true

allowPorts = [
    { start = 10000, end = 50000 }
]

webServer.vhostHTTPPort = ${vhost_http_port}
webServer.vhostHTTPSPort = ${vhost_https_port}
subdomainHost = "${subdomain_host}"

log.to = "/var/log/frps.log"
log.level = "info"
log.maxDays = 3
EOF
    CONFIG_FILE="$INSTALL_DIR/frps.toml"
    echo -e "${GREEN}已创建TOML格式配置文件: $CONFIG_FILE${NC}"
fi

chmod 755 $CONFIG_FILE

# 保存配置参数副本
cat > $INSTALL_DIR/frps_config_backup.txt << EOF
# frps配置参数 (安装时间: $(date))
# frp版本: ${FRP_VERSION}
# 配置文件格式: ${CONFIG_FORMAT}
bind_port = ${bind_port}
dashboard_port = ${dashboard_port}
dashboard_user = ${dashboard_user}
dashboard_pwd = ${dashboard_pwd}
token = ${token}
vhost_http_port = ${vhost_http_port}
vhost_https_port = ${vhost_https_port}
subdomain_host = ${subdomain_host}
EOF
chmod 755 $INSTALL_DIR/frps_config_backup.txt

# 尝试创建日志文件
if [ -w /var/log ]; then
    touch /var/log/frps.log
    chmod 755 /var/log/frps.log
else
    echo -e "${YELLOW}警告: 无权创建/var/log/frps.log，将日志输出修改为标准输出${NC}"
    # 更新配置文件中的日志设置
    if [ "$CONFIG_FORMAT" = "ini" ]; then
        sed -i 's|log_file = /var/log/frps.log|# log_file = /var/log/frps.log|g' $CONFIG_FILE
    else
        sed -i 's|log.to = "/var/log/frps.log"|# log.to = "/var/log/frps.log"|g' $CONFIG_FILE
    fi
fi

# 创建systemd服务
if [ -d /etc/systemd/system/ ] && [ -w /etc/systemd/system/ ]; then
    echo -e "${YELLOW}配置systemd服务...${NC}"
    
    if [ "$CONFIG_FORMAT" = "ini" ]; then
        CONFIG_PARAM="-c $INSTALL_DIR/frps.ini"
    else
        CONFIG_PARAM="-c $INSTALL_DIR/frps.toml"
    fi
    
    cat > /etc/systemd/system/frps.service << EOF
[Unit]
Description=frps service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/frps $CONFIG_PARAM
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    # 设置权限
    chmod 755 /etc/systemd/system/frps.service

    # 尝试启用并启动服务
    if command -v systemctl &> /dev/null; then
        systemctl daemon-reload
        systemctl enable frps.service
        systemctl start frps.service

        # 检查服务状态
        sleep 2
        if systemctl is-active --quiet frps; then
            echo -e "${GREEN}frps服务已成功启动!${NC}"
            SERVICE_STATUS="active (running)"
        else
            echo -e "${RED}frps服务启动失败，请检查日志: systemctl status frps${NC}"
            SERVICE_STATUS="failed"
        fi
    else
        echo -e "${YELLOW}警告: 未检测到systemctl，无法启动服务${NC}"
        SERVICE_STATUS="not started"
    fi
else
    echo -e "${YELLOW}警告: 无权创建systemd服务，请手动配置自启动${NC}"
    echo -e "${YELLOW}手动启动命令: $INSTALL_DIR/frps $CONFIG_PARAM${NC}"
    SERVICE_STATUS="not configured"
fi

# 清理
rm -rf $TMP_DIR

# 输出信息
echo -e "\n${GREEN}====== frps安装完成 ======${NC}"
echo -e "${YELLOW}frps版本: ${FRP_VERSION} (${CONFIG_FORMAT}格式)${NC}"
echo -e "${YELLOW}配置文件: $CONFIG_FILE${NC}"
echo -e "${YELLOW}配置备份: $INSTALL_DIR/frps_config_backup.txt${NC}"
echo -e "${YELLOW}服务状态: $SERVICE_STATUS${NC}"

echo -e "\n${GREEN}====== 服务访问信息 ======${NC}"
echo -e "${YELLOW}服务器IP/域名: ${subdomain_host}${NC}"
echo -e "${YELLOW}frps服务端口: ${bind_port}${NC}"
echo -e "${YELLOW}HTTP访问端口: ${vhost_http_port}${NC}"
echo -e "${YELLOW}HTTPS访问端口: ${vhost_https_port}${NC}"
echo -e "${YELLOW}管理面板: http://${subdomain_host}:${dashboard_port}${NC}"
echo -e "${YELLOW}管理面板用户名: ${dashboard_user}${NC}"
echo -e "${YELLOW}管理面板密码: ${dashboard_pwd}${NC}"
echo -e "${YELLOW}认证Token: ${token}${NC}"

echo -e "\n${GREEN}====== 常用命令 ======${NC}"
if command -v systemctl &> /dev/null; then
    echo -e "${YELLOW}查看服务状态: systemctl status frps${NC}"
    echo -e "${YELLOW}启动frps服务: systemctl start frps${NC}"
    echo -e "${YELLOW}停止frps服务: systemctl stop frps${NC}"
    echo -e "${YELLOW}重启frps服务: systemctl restart frps${NC}"
else
    echo -e "${YELLOW}启动frps: $INSTALL_DIR/frps $CONFIG_PARAM${NC}"
    echo -e "${YELLOW}停止frps: killall frps${NC}"
fi

if [ -w /var/log ]; then
    echo -e "${YELLOW}查看frps日志: tail -f /var/log/frps.log${NC}"
else
    echo -e "${YELLOW}frps日志通过systemd日志查看: journalctl -u frps -f${NC}"
fi

echo -e "${YELLOW}编辑配置文件: nano $CONFIG_FILE${NC}"

echo -e "\n${RED}重要提示: 请保存好以上信息，特别是认证Token!${NC}"
echo -e "${YELLOW}注意: 脚本未配置防火墙，请根据需要手动开放相关端口!${NC}"
