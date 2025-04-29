#!/bin/bash
# 只修复MySQL服务

echo "===== 开始修复MySQL ====="

# 1. 备份并删除所有现有的MySQL配置文件
echo "备份现有MySQL配置..."
sudo mkdir -p /etc/mysql.bak
sudo cp -r /etc/mysql/* /etc/mysql.bak/ 2>/dev/null

# 2. 创建最小化的MySQL配置文件
echo "创建简化的MySQL配置..."
sudo rm -f /etc/mysql/my.cnf
sudo rm -f /etc/mysql/mysql.conf.d/mysqld.cnf

cat << EOF | sudo tee /etc/mysql/my.cnf
[mysqld]
# 基本设置
datadir = /var/lib/mysql
socket = /var/run/mysqld/mysqld.sock
port = 3306
user = mysql

# InnoDB设置
innodb_buffer_pool_size = 256M
innodb_file_per_table = 1

# 日志设置
log_error = /var/log/mysql/error.log

# 字符集
character_set_server = utf8mb4

[client]
port = 3306
socket = /var/run/mysqld/mysqld.sock
EOF

# 3. 确保目录权限正确
echo "设置权限..."
sudo mkdir -p /var/log/mysql
sudo chown -R mysql:mysql /var/log/mysql
sudo mkdir -p /var/run/mysqld
sudo chown -R mysql:mysql /var/run/mysqld

# 4. 重置MySQL环境变量设置
echo "清除环境变量设置..."
echo "" | sudo tee /etc/default/mysql

# 5. 尝试修复数据库
echo "尝试修复数据库..."
if [ -d "/var/lib/mysql" ]; then
  # 如果遇到问题可能需要重新初始化数据库
  # 警告: 这将删除所有现有的数据
  read -p "是否要重新初始化MySQL数据库? 这将删除所有数据! (y/n) " answer
  if [ "$answer" = "y" ]; then
    echo "停止MySQL服务..."
    sudo systemctl stop mysql

    echo "备份MySQL数据目录..."
    sudo cp -r /var/lib/mysql /var/lib/mysql.bak.$(date +%Y%m%d_%H%M%S)

    echo "重新初始化MySQL数据库..."
    sudo rm -rf /var/lib/mysql/*
    sudo mkdir -p /var/lib/mysql
    sudo chown -R mysql:mysql /var/lib/mysql
    sudo chmod -R 750 /var/lib/mysql
    
    echo "尝试初始化MySQL数据目录..."
    sudo mysqld --initialize-insecure --user=mysql
  fi
fi

# 6. 重启MySQL服务
echo "重启MySQL服务..."
sudo systemctl daemon-reload
sudo systemctl restart mysql

# 7. 检查服务状态
echo "检查MySQL状态..."
sudo systemctl status mysql --no-pager

echo "===== MySQL修复完成 =====" 