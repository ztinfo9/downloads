#!/bin/bash
# Dante SOCKS5 一键安装脚本 for CentOS 7.6
# 安装目录: /usr/local/dante
# 配置文件: /etc/sockd.conf
# systemd:  /etc/systemd/system/sockd.service

set -e

USERNAME="socks5user"
PASSWORD="redback"
PORT="1080"

echo "[1/6] 安装依赖..."
yum install -y gcc make wget tar firewalld

echo "[2/6] 下载并编译 Dante..."
cd /usr/local/src
wget -O dante-1.4.2.tar.gz https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar xzf dante-1.4.2.tar.gz
cd dante-1.4.2
./configure --prefix=/usr/local/dante
make && make install

echo "[3/6] 创建配置文件..."
cat > /etc/sockd.conf <<EOF
logoutput: syslog

internal: 0.0.0.0 port = ${PORT}
external: 0.0.0.0

method: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
EOF

echo "[4/6] 创建 systemd 服务..."
cat > /etc/systemd/system/sockd.service <<EOF
[Unit]
Description=Dante SOCKS5 Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/dante/sbin/sockd -f /etc/sockd.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[5/6] 添加用户..."
id -u ${USERNAME} &>/dev/null || useradd ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd

echo "[6/6] 配置防火墙并启动服务..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=${PORT}/tcp
firewall-cmd --permanent --add-port=${PORT}/udp
firewall-cmd --reload

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sockd
systemctl restart sockd

echo "✅ Dante SOCKS5 安装完成！"
echo "服务状态: systemctl status sockd"
echo "SOCKS5 地址: 服务器IP:${PORT}"
echo "用户名: ${USERNAME}"
echo "密码: ${PASSWORD}"
