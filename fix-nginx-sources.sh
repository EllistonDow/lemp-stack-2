#!/bin/bash
# 修复Nginx仓库配置问题

echo "===== 开始修复Nginx仓库配置 ====="

# 备份原Nginx仓库
echo "备份原仓库配置..."
sudo mkdir -p /etc/apt/sources.list.d.bak
sudo mv /etc/apt/sources.list.d/nginx* /etc/apt/sources.list.d.bak/ 2>/dev/null

# 创建新的Nginx仓库配置
echo "创建新的Nginx仓库配置..."
cat << EOF | sudo tee /etc/apt/sources.list.d/nginx.list
deb [trusted=yes] http://nginx.org/packages/mainline/ubuntu/ jammy nginx
deb-src [trusted=yes] http://nginx.org/packages/mainline/ubuntu/ jammy nginx
EOF

# 更新APT缓存
echo "更新APT缓存..."
sudo apt-get update -y

# 安装ModSecurity模块
echo "尝试安装ModSecurity..."
sudo apt-get install -y libmodsecurity3 libnginx-mod-http-modsecurity || echo "无法安装ModSecurity，需要手动编译"

# 安装缺失的服务
echo "安装缺失的服务..."
sudo apt-get install -y fail2ban rabbitmq-server certbot webmin

# 启用Varnish服务
echo "启用Varnish服务..."
sudo systemctl enable varnish
sudo systemctl start varnish

# 启用新安装的服务
echo "启用新安装的服务..."
sudo systemctl enable fail2ban rabbitmq-server
sudo systemctl start fail2ban rabbitmq-server

echo "===== 修复完成 ====="
echo "请检查各服务状态:"
echo "sudo systemctl status nginx mysql opensearch fail2ban rabbitmq-server varnish" 