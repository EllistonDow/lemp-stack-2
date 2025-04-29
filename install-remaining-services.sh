#!/bin/bash
# 安装剩余的服务

echo "===== 开始安装剩余服务 ====="

# 更新APT缓存
echo "更新APT缓存..."
sudo apt-get update -y

# 安装Fail2ban
echo "安装Fail2ban..."
sudo apt-get install -y fail2ban || echo "无法安装Fail2ban"

# 安装RabbitMQ
echo "安装RabbitMQ..."
# 添加RabbitMQ官方仓库
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor -o /usr/share/keyrings/com.rabbitmq.team.gpg
curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key" | sudo gpg --dearmor -o /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg
curl -1sLf "https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key" | sudo gpg --dearmor -o /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg

cat << EOF | sudo tee /etc/apt/sources.list.d/rabbitmq.list
## Provides modern Erlang/OTP releases
deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

## Provides RabbitMQ
deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
EOF

# 更新APT缓存并安装
sudo apt-get update -y
sudo apt-get install -y rabbitmq-server || echo "无法安装RabbitMQ"

# 安装Certbot
echo "安装Certbot..."
sudo apt-get install -y certbot || sudo snap install --classic certbot

# 安装Webmin
echo "安装Webmin..."
# 添加Webmin仓库
cat << EOF | sudo tee /etc/apt/sources.list.d/webmin.list
deb [trusted=yes] http://download.webmin.com/download/repository sarge contrib
deb [trusted=yes] http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib
EOF

# 添加Webmin密钥
curl -fsSL https://download.webmin.com/jcameron-key.asc | sudo gpg --dearmor -o /usr/share/keyrings/webmin-archive-keyring.gpg
cat << EOF | sudo tee /etc/apt/sources.list.d/webmin.list
deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib
EOF

# 更新APT缓存并安装
sudo apt-get update -y
sudo apt-get install -y webmin || echo "无法安装Webmin"

# 修复Varnish配置
echo "修复Varnish配置..."
if [ -f /etc/systemd/system/varnish.service ]; then
    # 检查或创建Varnish配置
    if [ ! -f /etc/varnish/default.vcl ]; then
        sudo mkdir -p /etc/varnish
        cat << EOF | sudo tee /etc/varnish/default.vcl
vcl 4.1;

backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
EOF
    fi
    
    # 修正服务配置
    cat << EOF | sudo tee /etc/systemd/system/varnish.service
[Unit]
Description=Varnish HTTP accelerator
Documentation=https://www.varnish-cache.org/docs/
After=network.target

[Service]
Type=simple
LimitNOFILE=131072
LimitMEMLOCK=82000
ExecStart=/usr/sbin/varnishd -j unix,user=vcache -F -a :6081 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m
ExecReload=/usr/sbin/varnishreload
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
PrivateDevices=true

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载并启动服务
    sudo systemctl daemon-reload
    sudo systemctl restart varnish
else
    echo "Varnish服务配置不存在，可能需要重新安装"
fi

# 启用并启动所有已安装服务
echo "启用和启动所有已安装服务..."
for service in fail2ban rabbitmq-server varnish; do
    if systemctl list-unit-files | grep -q "$service.service"; then
        sudo systemctl enable $service
        sudo systemctl restart $service || echo "$service启动失败"
    fi
done

echo "===== 完成安装 ====="
echo "请检查各服务状态" 