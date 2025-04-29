#!/bin/bash
# 终极修复脚本 - 修复MySQL和Varnish具体问题

echo "===== 开始终极修复 ====="

# 1. 修复MySQL配置
echo "修复MySQL配置问题..."

# 创建MySQL配置目录
sudo mkdir -p /etc/mysql/conf.d
sudo mkdir -p /etc/mysql/mysql.conf.d

# 创建基本MySQL配置，解决authentication-policy和query_cache_size问题
cat << EOF | sudo tee /etc/mysql/my.cnf
# MySQL配置文件 - 修复版
[mysqld]
# 基本设置
datadir = /var/lib/mysql
socket  = /var/run/mysqld/mysqld.sock
port    = 3306
user    = mysql

# 连接设置
max_connections = 150
max_allowed_packet = 16M
thread_cache_size = 8

# InnoDB设置
innodb_buffer_pool_size = 256M
innodb_redo_log_capacity = 256M
innodb_log_buffer_size = 8M
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 1

# 日志设置
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 1

# 字符集
character_set_server = utf8mb4
collation_server = utf8mb4_0900_ai_ci

# 去除有问题的参数
# 不要设置 authentication_policy 参数
# 不要设置 query_cache_size 参数

[client]
socket = /var/run/mysqld/mysqld.sock
port = 3306
EOF

# 创建MySQL服务环境配置
cat << EOF | sudo tee /etc/default/mysql
# MySQL服务环境变量
MYSQLD_OPTS=""
EOF

# 确保目录权限正确
echo "设置MySQL目录权限..."
sudo mkdir -p /var/log/mysql
sudo chown -R mysql:mysql /var/log/mysql
sudo chmod -R 755 /var/log/mysql

# 修复MySQL数据目录
echo "修复MySQL数据目录..."
sudo rm -f /var/lib/mysql/ib_logfile*
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod -R 750 /var/lib/mysql

# 确保运行目录存在
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld

# 2. 安装和修复Varnish
echo "修复Varnish..."

# 重新安装Varnish
echo "重新安装Varnish..."
sudo apt-get update -y
sudo apt-get install --reinstall -y varnish

# 检查varnishd命令是否存在
if ! command -v varnishd >/dev/null 2>&1; then
    echo "Varnish不存在，尝试安装..."
    sudo apt-get install -y varnish
fi

# 确保Varnish配置目录存在
sudo mkdir -p /etc/varnish

# 创建默认VCL文件
cat << EOF | sudo tee /etc/varnish/default.vcl
vcl 4.1;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
EOF

# 创建Varnish secret文件
sudo dd if=/dev/random of=/etc/varnish/secret count=1 bs=4096 2>/dev/null
sudo chmod 600 /etc/varnish/secret

# 使用默认的Varnish服务配置
sudo cp /lib/systemd/system/varnish.service /etc/systemd/system/varnish.service

# 重新加载systemd配置
echo "重新加载systemd配置..."
sudo systemctl daemon-reload

# 重启服务
echo "重启服务..."
sudo systemctl restart mysql
sudo systemctl restart varnish

# 最终状态检查
echo "===== 最终检查 ====="
for service in nginx php8.3-fpm php8.4-fpm valkey mysql opensearch fail2ban rabbitmq-server varnish; do
    echo "检查 $service 状态:"
    sudo systemctl status $service --no-pager || echo "$service 服务未运行或不存在"
    echo "------------------------"
done

# 列出当前运行的服务
echo "所有正在运行的服务:"
sudo systemctl list-units --type=service --state=running | grep -E 'nginx|php|mysql|opensearch|valkey|varnish|rabbitmq|fail2ban'

echo "===== 修复完成 =====" 