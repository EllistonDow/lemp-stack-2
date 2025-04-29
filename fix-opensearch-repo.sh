#!/bin/bash
# 脚本用于修复OpenSearch仓库问题

# 删除错误的OpenSearch仓库配置
sudo rm -f /etc/apt/sources.list.d/opensearch*

# 创建新的OpenSearch仓库配置
cat << EOF | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
deb [trusted=yes] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main
EOF

# 更新APT缓存
sudo apt-get update -y --allow-insecure-repositories

echo "OpenSearch仓库修复完成" 