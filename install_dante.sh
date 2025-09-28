#!/bin/bash

# 检查是否有用户名和密码环境变量
if [ -z "$SOCKS5_USER" ] || [ -z "$SOCKS5_PASS" ]; then
  echo "错误：请在生产环境中设置环境变量 SOCKS5_USER 和 SOCKS5_PASS"
  echo "例如：export SOCKS5_USER='your_username' && export SOCKS5_PASS='your_password'"
  exit 1
fi

# 更新系统软件包
echo "更新系统软件包..."
sudo apt update -y
sudo apt upgrade -y

# 安装 Dante 依赖
echo "安装 Dante 依赖..."
sudo apt install -y dante-server

# 创建一个没有登录权限的用户
echo "创建用户名为 $SOCKS5_USER 的系统用户..."
sudo useradd -M -s /usr/sbin/nologin $SOCKS5_USER
echo "$SOCKS5_USER:$SOCKS5_PASS" | sudo chpasswd

# 配置 Dante 服务器
echo "配置 Dante SOCKS5 代理..."
cat <<EOF | sudo tee /etc/danted.conf
logoutput: /var/log/danted.log
internal: eth0 port = 1080
external: eth0
method: username
user.privileged: root
user.unprivileged: nobody
socksmethod: username
user.libwrap: no
clientmethod: none
user.$SOCKS5_USER: $SOCKS5_PASS
EOF

# 设置防火墙规则（开放 1080 端口）
echo "配置防火墙规则..."
sudo ufw allow 1080/tcp
sudo ufw reload

# 启动 Dante 服务
echo "启动 Dante SOCKS5 代理服务..."
sudo systemctl restart danted
sudo systemctl enable danted

# 检查 Dante 服务状态
echo "检查 Dante 服务状态..."
sudo systemctl status danted

echo "安装完成，Dante SOCKS5 代理服务正在运行，端口：16999，用户名：$SOCKS5_USER"
