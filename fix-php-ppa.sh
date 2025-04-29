#!/bin/bash
# 脚本用于修复Ubuntu 24.04上PHP PPA仓库问题

# 允许仓库信息变更
sudo echo 'APT::Get::AllowReleaseInfoChange "true";' | sudo tee /etc/apt/apt.conf.d/99allow-release-info-change

# 删除旧的ondrej PHP PPA配置
sudo rm -f /etc/apt/sources.list.d/ondrej-php*

# 重新添加PHP PPA
sudo add-apt-repository -y ppa:ondrej/php

# 刷新APT仓库（允许仓库信息变更）
sudo apt-get update -y --allow-releaseinfo-change

echo "PHP PPA修复完成" 