#!/bin/bash
# 专门修复MySQL和OpenSearch的脚本

echo "===== 开始修复MySQL和OpenSearch ====="

# 1. 修复MySQL配置问题
echo "修复MySQL配置..."
sudo mkdir -p /etc/mysql/conf.d

# 创建MySQL主配置文件
cat << EOF | sudo tee /etc/mysql/my.cnf
# Percona Server配置文件
#
# 针对Ubuntu 24.04环境

[mysqld]
# 基本设置
datadir = /var/lib/mysql
socket  = /var/run/mysqld/mysqld.sock
port    = 3306
user    = mysql

# 移除不支持的旧参数
# query_cache_limit=2M - 在MySQL 8中已不再支持
# default_authentication_plugin=caching_sha2_password - 格式已更改

# 新的认证插件设置
authentication_policy=mysql_native_password,*,*

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

[client]
socket = /var/run/mysqld/mysqld.sock
port = 3306

[mysqld_safe]
log_error = /var/log/mysql/error.log
pid_file = /var/run/mysqld/mysqld.pid
EOF

# 确保MySQL目录权限正确
echo "设置MySQL目录权限..."
sudo mkdir -p /var/log/mysql
sudo chown -R mysql:mysql /var/log/mysql
sudo chmod -R 755 /var/log/mysql
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod -R 750 /var/lib/mysql
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld

# 尝试启动MySQL服务
echo "重启MySQL服务..."
sudo systemctl daemon-reload
sudo systemctl restart mysql

# 2. 修复OpenSearch配置
echo "修复OpenSearch..."

# 确保OpenSearch源设置正确
sudo rm -f /etc/apt/sources.list.d/opensearch*
cat << EOF | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
deb [trusted=yes] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main
EOF

# 更新apt缓存
sudo apt-get update -y --allow-insecure-repositories

# 检查并安装OpenSearch
if ! dpkg -l | grep -q opensearch; then
    echo "安装OpenSearch..."
    sudo apt-get install -y opensearch
else
    echo "OpenSearch已安装，配置服务..."
fi

# 设置OpenSearch配置
sudo mkdir -p /etc/opensearch

# 创建OpenSearch配置文件
cat << EOF | sudo tee /etc/opensearch/opensearch.yml
# OpenSearch基本配置
cluster.name: lemp-cluster
node.name: node-1
path.data: /var/lib/opensearch
path.logs: /var/log/opensearch
network.host: 127.0.0.1
http.port: 9200
discovery.type: single-node
action.auto_create_index: true

# 安全设置
plugins.security.disabled: true
EOF

# 确保OpenSearch目录权限正确
sudo mkdir -p /var/lib/opensearch /var/log/opensearch
sudo chown -R opensearch:opensearch /var/lib/opensearch /var/log/opensearch
sudo chmod -R 750 /var/lib/opensearch /var/log/opensearch

# 重新启动OpenSearch服务
echo "重启OpenSearch服务..."
sudo systemctl daemon-reload
sudo systemctl restart opensearch

# 检查服务状态
echo "===== 检查服务状态 ====="
echo "MySQL状态:"
sudo systemctl status mysql | head -n 10

echo "OpenSearch状态:"
sudo systemctl status opensearch | head -n 10

echo "===== 修复完成 =====" 