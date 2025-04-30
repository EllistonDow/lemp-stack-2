#!/bin/bash
#
# RabbitMQ 安装和配置脚本 for LEMP环境 (用于Magento 2)
# 版本: 0.1.1
# 作者: Chen
# 发布时间: 2025-04-30
# 
# 这个脚本可在全新安装LEMP环境后使用
# 用法: sudo bash rabbitmq_setup.sh
#
# 变更日志:
# 0.1.1 - 修复Ubuntu仓库路径，修正apt依赖安装
# 0.1.0 - 初始版本

set -e

# 检查是否以root运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请以root用户运行此脚本!"
    exit 1
fi

echo "=== RabbitMQ 安装与配置脚本 v0.1.1 ==="
echo "此脚本将安装RabbitMQ并进行Magento 2优化配置"
echo

# 安装RabbitMQ
install_rabbitmq() {
    echo "[步骤1] 安装RabbitMQ和所需依赖"
    
    # 安装前置依赖
    apt-get install -y curl gnupg apt-transport-https
    
    # 添加RabbitMQ存储库
    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor > /usr/share/keyrings/com.rabbitmq.team.gpg
    
    # 添加Erlang存储库
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key | gpg --dearmor > /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg
    
    # 添加RabbitMQ存储库
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key | gpg --dearmor > /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg
    
    # 添加apt源 (检测Ubuntu或Debian版本)
    if [ -f /etc/lsb-release ]; then
        # Ubuntu
        source /etc/lsb-release
        OS_CODENAME=$DISTRIB_CODENAME
        OS_TYPE="ubuntu"
    elif [ -f /etc/os-release ]; then
        # Debian
        source /etc/os-release
        OS_CODENAME=$VERSION_CODENAME
        OS_TYPE="debian"
    else
        echo "无法检测到操作系统版本，使用默认值'noble'和'ubuntu'"
        OS_CODENAME="noble"
        OS_TYPE="ubuntu"
    fi
    
    echo "检测到操作系统: $OS_TYPE $OS_CODENAME"
    
    # 创建apt源文件
    cat > /etc/apt/sources.list.d/rabbitmq.list <<EOF
## RabbitMQ Erlang
deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/$OS_TYPE $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/$OS_TYPE $OS_CODENAME main

## RabbitMQ Server
deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/$OS_TYPE $OS_CODENAME main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/$OS_TYPE $OS_CODENAME main
EOF
    
    # 更新包索引
    apt-get update -y
    
    # 安装RabbitMQ服务器和其依赖项
    apt-get install -y erlang-base \
        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
        erlang-runtime-tools erlang-snmp erlang-ssl \
        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
    
    apt-get install -y rabbitmq-server
    
    echo "[成功] RabbitMQ已安装"
}

# 配置RabbitMQ
configure_rabbitmq() {
    echo "[步骤2] 配置RabbitMQ"
    
    # 备份原始配置（如果存在）
    if [ -f /etc/rabbitmq/rabbitmq.conf ]; then
        mv /etc/rabbitmq/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf.original
        echo "已备份原始配置到 /etc/rabbitmq/rabbitmq.conf.original"
    fi
    
    # 创建基本配置，避免多余空格等语法错误
    cat > /etc/rabbitmq/rabbitmq.conf <<EOF
# RabbitMQ 基础配置文件 - 针对 Magento 2

## 内存管理
vm_memory_high_watermark.relative = 0.4
disk_free_limit.absolute = 2GB

## 日志级别
log.file.level = warning
EOF
    
    # 确保正确的权限
    chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf
    chmod 644 /etc/rabbitmq/rabbitmq.conf
    
    # 启动RabbitMQ服务
    systemctl start rabbitmq-server
    systemctl enable rabbitmq-server
    
    # 等待RabbitMQ完全启动
    echo "等待RabbitMQ启动..."
    sleep 10
    
    # 检查服务状态
    if systemctl is-active --quiet rabbitmq-server; then
        echo "[成功] RabbitMQ服务已启动"
    else
        echo "[警告] RabbitMQ服务未能正常启动，请检查"
        return 1
    fi
    
    return 0
}

# 为Magento安装PHP AMQP扩展
install_php_amqp() {
    echo "[步骤3] 安装PHP AMQP扩展"
    
    # 安装PHP AMQP扩展
    apt-get install -y php-amqp
    
    # 重启PHP-FPM服务（自动检测PHP版本）
    for version in $(dpkg -l | grep -oP 'php\d\.\d-fpm' | sort -u); do
        echo "重启 $version 服务..."
        systemctl restart $version
    done
    
    echo "[成功] PHP AMQP扩展已安装"
}

# 创建优化的配置文件（用于生产环境）
create_optimized_config() {
    echo "[步骤4] 创建优化的配置文件"
    
    cat > /etc/rabbitmq/rabbitmq-optimized.conf <<EOF
# RabbitMQ 优化配置文件 - 针对 Magento 2

## 内存管理 
vm_memory_high_watermark.relative = 0.16
vm_memory_high_watermark_paging_ratio = 0.8
disk_free_limit.absolute = 3GB

## 队列和消息优化
queue_index_embed_msgs_below = 4096
msg_store_credit_disc_bound.count = 2000
msg_store_io_batch_size = 8192
consumer_timeout = 3600000

## 网络和连接优化
tcp_listen_options.backlog = 4096
channel_max = 2000
heartbeat = 60

## 持久化优化
queue_master_locator = min-masters
mirroring_sync_batch_size = 4096
mnesia_table_loading_retry_limit = 10
mnesia_table_loading_retry_timeout = 30000

## 资源和系统优化
connection_max = 4000

## 日志优化
log.file.level = warning
log.console.level = warning
EOF
    
    echo "[成功] 优化配置文件已创建: /etc/rabbitmq/rabbitmq-optimized.conf"
    echo "注意: 此配置文件并未启用，您可以根据需要手动应用或修改"
    echo "      应用命令: sudo cp /etc/rabbitmq/rabbitmq-optimized.conf /etc/rabbitmq/rabbitmq.conf"
}

# 创建监控脚本
create_monitor_script() {
    echo "[步骤5] 创建RabbitMQ监控脚本"
    
    cat > /usr/local/bin/rabbitmq_monitor.sh <<'EOF'
#!/bin/bash

# RabbitMQ监控脚本 - 用于Magento环境
# 用途：监控RabbitMQ队列状态，记录积压情况，发现处理缓慢的队列

LOG_FILE="/var/log/rabbitmq_monitor.log"
THRESHOLD=100 # 消息数量超过此阈值时发出警告

echo "========= RabbitMQ队列状态检查 $(date) =========" | sudo tee -a $LOG_FILE

# 获取积压消息数量较多的队列
QUEUES_WITH_MESSAGES=$(sudo rabbitmqctl list_queues name messages consumers state | awk '$2 > 0 {print}')

if [ -z "$QUEUES_WITH_MESSAGES" ]; then
    echo "所有队列均为空，没有积压消息。" | sudo tee -a $LOG_FILE
else
    echo "发现含有消息的队列:" | sudo tee -a $LOG_FILE
    echo "$QUEUES_WITH_MESSAGES" | sudo tee -a $LOG_FILE
    
    # 检查是否有超过阈值的队列
    HIGH_LOAD_QUEUES=$(echo "$QUEUES_WITH_MESSAGES" | awk -v threshold=$THRESHOLD '$2 > threshold {print}')
    if [ ! -z "$HIGH_LOAD_QUEUES" ]; then
        echo -e "\n警告: 以下队列消息数量超过阈值 ($THRESHOLD):" | sudo tee -a $LOG_FILE
        echo "$HIGH_LOAD_QUEUES" | sudo tee -a $LOG_FILE
    fi
    
    # 检查没有消费者的队列
    NO_CONSUMER_QUEUES=$(echo "$QUEUES_WITH_MESSAGES" | awk '$3 == 0 {print}')
    if [ ! -z "$NO_CONSUMER_QUEUES" ]; then
        echo -e "\n警告: 以下队列有消息但没有消费者:" | sudo tee -a $LOG_FILE
        echo "$NO_CONSUMER_QUEUES" | sudo tee -a $LOG_FILE
    fi
fi

# 检查RabbitMQ整体状态
echo -e "\n系统资源使用情况:" | sudo tee -a $LOG_FILE
sudo rabbitmqctl status | grep -E "file_descriptors|memory|processes" | sudo tee -a $LOG_FILE

echo -e "\n========= 检查结束 =========\n" | sudo tee -a $LOG_FILE
EOF
    
    chmod +x /usr/local/bin/rabbitmq_monitor.sh
    
    # 创建cron任务
    echo "# RabbitMQ队列监控 - 每10分钟执行一次" > /etc/cron.d/rabbitmq_monitor
    echo "*/10 * * * * root /usr/local/bin/rabbitmq_monitor.sh >/dev/null 2>&1" >> /etc/cron.d/rabbitmq_monitor
    
    echo "[成功] 监控脚本已创建: /usr/local/bin/rabbitmq_monitor.sh"
    echo "       Cron任务已设置: 每10分钟执行一次"
}

# 创建Magento消费者启动脚本模板
create_consumer_script() {
    echo "[步骤6] 创建Magento消费者启动脚本"
    
    cat > /usr/local/bin/magento_consumer_start.sh <<'EOF'
#!/bin/bash

# Magento 2消费者启动脚本
# 此脚本用于启动多个队列消费者进程，提高消息处理效率

# 配置项
MAGENTO_ROOT="/path/to/magento" # 修改为实际的Magento根目录
LOG_DIR="/var/log/magento/consumers"
CONSUMER_COUNT=3 # 每个队列启动的消费者数量

# 确保日志目录存在
mkdir -p $LOG_DIR

# 常见的Magento消费者列表
CONSUMERS=(
    "async.operations.all"
    "inventory.reservations.update"
    "inventory.indexer.sourceItem"
    "inventory.indexer.stock"
    "inventory.source.items.cleanup"
    "inventory.mass.update"
    "inventory.reservations.cleanup"
    "inventory.reservations.updateSalabilityStatus"
    "product_action_attribute.update"
    "product_action_attribute.website.update"
    "codegenerator"
    "exportProcessor"
    "media.storage.catalog.image.resize"
    "media.gallery.synchronization"
    "media.gallery.renditions.update"
    "media.content.synchronization"
    "sales.rule.update.coupon.usage"
    "sales.rule.quote.trigger.recollect"
)

echo "启动Magento消费者进程，每个队列 $CONSUMER_COUNT 个消费者..."

# 停止所有现有的消费者进程
echo "停止所有现有的消费者进程..."
ps aux | grep '[b]in/magento queue:consumers:start' | awk '{print $2}' | xargs -r kill

# 为每个消费者启动指定数量的进程
for CONSUMER in "${CONSUMERS[@]}"; do
    for ((i=1; i<=$CONSUMER_COUNT; i++)); do
        LOG_FILE="$LOG_DIR/${CONSUMER}_${i}.log"
        echo "启动消费者: $CONSUMER (实例 $i), 日志: $LOG_FILE"
        
        cd $MAGENTO_ROOT && \
        nohup php bin/magento queue:consumers:start "$CONSUMER" \
            --max-messages=10000 \
            --batch-size=100 \
            --debug=1 > "$LOG_FILE" 2>&1 &
    done
done

echo "所有消费者已启动，检查日志目录: $LOG_DIR"
echo "提示: 如需每次系统启动时自动运行，请添加此脚本到系统启动项或crontab"
EOF
    
    chmod +x /usr/local/bin/magento_consumer_start.sh
    
    echo "[成功] 消费者启动脚本已创建: /usr/local/bin/magento_consumer_start.sh"
    echo "       注意: 使用前请修改脚本中的MAGENTO_ROOT变量为实际路径"
}

# 创建故障排查指南
create_troubleshooting_guide() {
    echo "[步骤7] 创建故障排查指南"
    
    cat > /usr/local/share/doc/rabbitmq_troubleshooting.md <<'EOF'
# RabbitMQ 故障排查与配置指南

## 问题解决记录

RabbitMQ服务无法启动的问题通常与配置文件语法错误有关。以下是常见问题和解决方法：

### 常见问题症状
- RabbitMQ服务启动失败，systemctl显示错误退出代码
- 错误日志显示 `failed_to_prepare_configuration` 错误

### 解决方法
1. 创建最小化的配置文件以使RabbitMQ能够启动
2. 配置文件中的数值后不能有多余空格（如 `4096 ` 应该是 `4096`）
3. 某些高级配置选项可能在当前RabbitMQ版本中不支持或已弃用

### 工作的最小配置文件
```
# RabbitMQ 基础配置文件 - 针对 Magento 2

## 内存管理
vm_memory_high_watermark.relative = 0.4
disk_free_limit.absolute = 2GB
```

## RabbitMQ 维护指南

### 常用命令
- 查看服务状态：`sudo systemctl status rabbitmq-server`
- 重启服务：`sudo systemctl restart rabbitmq-server`
- 查看队列：`sudo rabbitmqctl list_queues`
- 查看队列详情：`sudo rabbitmqctl list_queues name messages consumers memory state`
- 查看服务器状态：`sudo rabbitmqctl status`

### 监控队列积压
使用提供的监控脚本：`/usr/local/bin/rabbitmq_monitor.sh`
- 已设置cron作业每10分钟执行一次
- 日志位置：`/var/log/rabbitmq_monitor.log`

### 优化消费者
使用提供的消费者启动脚本：`/usr/local/bin/magento_consumer_start.sh`
- 请修改脚本中的`MAGENTO_ROOT`路径指向实际的Magento安装目录
- 根据服务器负载调整`CONSUMER_COUNT`的值

## 故障排除提示

1. 配置文件修改后总是检查语法，尤其是数值后不要有空格
2. 修改配置后通过`journalctl -u rabbitmq-server`检查日志
3. 如果无法启动，尝试使用最小配置
4. 确保`/var/lib/rabbitmq/.erlang.cookie`文件权限正确
5. 对于Magento，确保安装了PHP AMQP扩展
EOF
    
    echo "[成功] 故障排查指南已创建: /usr/local/share/doc/rabbitmq_troubleshooting.md"
}

# 主函数
main() {
    # 检查RabbitMQ是否已安装
    if dpkg -l | grep -q rabbitmq-server; then
        echo "RabbitMQ已安装。跳过安装步骤。"
    else
        install_rabbitmq
    fi
    
    configure_rabbitmq
    
    # 检查RabbitMQ服务是否已成功启动和配置
    if [ $? -eq 0 ]; then
        # 安装PHP AMQP扩展
        install_php_amqp
        
        # 创建优化配置文件
        create_optimized_config
        
        # 创建监控脚本
        create_monitor_script
        
        # 创建消费者启动脚本
        create_consumer_script
        
        # 创建故障排查指南
        create_troubleshooting_guide
        
        echo
        echo "==== RabbitMQ安装与配置完成 ===="
        echo "1. 基本配置已生效"
        echo "2. 优化配置文件已创建: /etc/rabbitmq/rabbitmq-optimized.conf (未启用)"
        echo "3. 监控脚本已安装: /usr/local/bin/rabbitmq_monitor.sh"
        echo "4. 消费者启动脚本已创建: /usr/local/bin/magento_consumer_start.sh"
        echo "5. 故障排查指南: /usr/local/share/doc/rabbitmq_troubleshooting.md"
        echo
        echo "RabbitMQ状态:"
        rabbitmqctl status | grep -E "file_descriptors|memory|processes|listeners"
    else
        echo
        echo "==== RabbitMQ配置失败 ===="
        echo "请检查日志获取更多信息: journalctl -u rabbitmq-server"
    fi
}

# 执行主函数
main 