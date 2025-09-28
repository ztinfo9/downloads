#!/bin/bash
# Dante SOCKS5 一键安装脚本 for CentOS 7.6
# 安装目录: /usr/local/dante
# 配置文件: /etc/sockd.conf
# systemd:  /etc/systemd/system/sockd.service

set -e

echo "[1/5] 安装依赖..."
yum install -y gcc make wget tar

echo "[2/5] 下载并编译 Dante..."
cd /usr/local/src
wget -O dante-1.4.2.tar.gz https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar xzf dante-1.4.2.tar.gz
cd dante-1.4.2
./configure --prefix=/usr/local/dante
make && make install

echo "[3/5] 创建配置文件..."
cat > /etc/sockd.conf <<EOF
logoutput: syslog

internal: 0.0.0.0 port = 1080
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

echo "[4/5] 创建 systemd 服务..."
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

echo "[5/5] 启动服务..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable sockd
systemctl restart sockd

echo "✅ Dante 安装完成！"
echo "默认监听端口: 1080"
echo "配置文件路径: /etc/sockd.conf"
echo "systemctl status sockd 查看运行状态"
