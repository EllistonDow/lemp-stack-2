#!/bin/bash
# 最终修复脚本 - 专注于修复MySQL和Varnish服务

echo "===== 开始最终修复 ====="

# 1. 修复MySQL配置
echo "修复MySQL配置问题..."

# 创建MySQL配置目录
sudo mkdir -p /etc/mysql/conf.d
sudo mkdir -p /etc/mysql/mysql.conf.d

# 使用update-alternatives注册MySQL配置文件
cat << EOF | sudo tee /etc/mysql/my.cnf
# MySQL配置文件
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
EOF

# 创建基本MySQL配置
cat << EOF | sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf
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

[client]
socket = /var/run/mysqld/mysqld.sock
port = 3306
EOF

# 创建MySQL服务环境配置
cat << EOF | sudo tee /etc/default/mysql
# 为MySQL服务设置环境变量
MYSQLD_OPTS="--explicit_defaults_for_timestamp"
EOF

# 修复MySQL服务单元文件
cat << EOF | sudo tee /usr/lib/systemd/system/mysql.service
[Unit]
Description=Percona Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target

[Service]
Type=notify
User=mysql
Group=mysql
EnvironmentFile=-/etc/default/mysql
ExecStartPre=/usr/share/mysql/mysql-systemd-start pre
ExecStart=/usr/sbin/mysqld \$MYSQLD_OPTS
PrivateTmp=false
LimitNOFILE=10000
Restart=on-failure
RestartPreventExitStatus=1
RestartSec=5
Environment=MYSQLD_PARENT_PID=1
PrivateDevices=false
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF

# 确保目录权限正确
echo "设置MySQL目录权限..."
sudo mkdir -p /var/log/mysql
sudo chown -R mysql:mysql /var/log/mysql
sudo chmod -R 755 /var/log/mysql
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod -R 750 /var/lib/mysql
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld

# 2. 修复Varnish配置
echo "修复Varnish配置..."

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

# 修正Varnish服务单元文件
cat << EOF | sudo tee /usr/lib/systemd/system/varnish.service
[Unit]
Description=Varnish HTTP accelerator
Documentation=https://www.varnish-cache.org/docs/
After=network.target

[Service]
Type=forking
LimitNOFILE=131072
LimitMEMLOCK=82000
ExecStart=/usr/sbin/varnishd -a :6081 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m
ExecReload=/usr/bin/varnishreload
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
PrivateDevices=true

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
echo "重新加载systemd配置..."
sudo systemctl daemon-reload

# 重新启动服务
echo "重新启动服务..."
sudo systemctl restart mysql varnish

# 检查服务状态
echo "===== 最终检查 ====="
echo "MySQL状态:"
sudo systemctl status mysql --no-pager

echo "Varnish状态:"
sudo systemctl status varnish --no-pager

echo "===== 修复完成 =====" 