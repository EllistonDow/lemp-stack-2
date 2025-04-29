#!/bin/bash
# 全面修复LEMP安装的问题

echo "===== LEMP环境问题修复脚本 ====="

# 1. 修复APT密钥和仓库问题
echo "修复APT配置..."
sudo echo 'APT::Get::AllowUnauthenticated "true";' | sudo tee /etc/apt/apt.conf.d/99allow-insecure
sudo echo 'Acquire::AllowInsecureRepositories "true";' | sudo tee -a /etc/apt/apt.conf.d/99allow-insecure
sudo echo 'APT::Get::AllowReleaseInfoChange "true";' | sudo tee /etc/apt/apt.conf.d/99allow-release-info-change

# 2. 修复OpenSearch仓库
echo "修复OpenSearch仓库..."
sudo rm -f /etc/apt/sources.list.d/opensearch*
cat << EOF | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
deb [trusted=yes] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main
EOF

# 3. 更新APT缓存
echo "更新APT缓存..."
sudo apt-get update -y --allow-insecure-repositories

# 4. 尝试安装ModSecurity
echo "尝试安装ModSecurity..."
# 添加需要的源以安装ModSecurity
cat << EOF | sudo tee /etc/apt/sources.list.d/nginx-modsecurity.list
deb [trusted=yes] http://nginx.org/packages/mainline/ubuntu/ jammy nginx
deb-src [trusted=yes] http://nginx.org/packages/mainline/ubuntu/ jammy nginx
EOF

sudo apt-get update -y
sudo apt-get install -y nginx-module-modsecurity || echo "ModSecurity安装失败，可能需要手动编译"

# 5. 修复MySQL/Percona服务
echo "修复MySQL/Percona服务..."
sudo systemctl stop mysql
sudo rm -f /var/lib/mysql/ib_logfile*
sudo systemctl start mysql || echo "MySQL启动失败，尝试更多修复..."

# 如果还是无法启动，尝试更深入的修复
if ! systemctl is-active --quiet mysql; then
    echo "执行额外的MySQL修复..."
    sudo mkdir -p /var/log/mysql
    sudo chown -R mysql:mysql /var/log/mysql
    sudo chmod -R 755 /var/log/mysql
    
    # 修复权限
    sudo chown -R mysql:mysql /var/lib/mysql
    sudo chmod -R 750 /var/lib/mysql
    
    # 重新启动服务
    sudo systemctl daemon-reload
    sudo systemctl start mysql || echo "MySQL仍无法启动，可能需要完全重新安装"
fi

# 6. 修复OpenSearch服务
echo "修复OpenSearch服务..."
sudo apt-get install -y opensearch || echo "OpenSearch安装失败，可能需要手动安装"
if ! systemctl is-active --quiet opensearch; then
    echo "尝试启动OpenSearch服务..."
    sudo systemctl daemon-reload
    sudo systemctl start opensearch || echo "OpenSearch服务启动失败，可能需要检查日志"
fi

# 7. 安装缺失的服务
echo "安装缺失的服务..."
sudo apt-get install -y fail2ban rabbitmq-server varnish certbot 

# 8. 确保所有服务都已启动
echo "启动所有服务..."
sudo systemctl enable nginx valkey mysql opensearch fail2ban rabbitmq-server varnish
sudo systemctl start nginx valkey mysql opensearch fail2ban rabbitmq-server varnish

echo "===== 修复完成 ====="
echo "请检查各服务状态，部分服务可能需要手动配置。" 