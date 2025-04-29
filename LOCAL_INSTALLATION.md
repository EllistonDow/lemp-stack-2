# LEMP Stack Ansible 本地安装指南

本项目已配置为可以在本地服务器上运行，无需远程SSH连接。以下是在本地Ubuntu 24.04系统上安装LEMP环境的步骤。

## 前置条件

1. Ubuntu 24.04服务器（物理机或虚拟机）
2. 管理员权限（sudo访问权限）
3. 安装Ansible（最新版本）

## 安装Ansible

如果您的系统上尚未安装Ansible，请按照以下步骤安装：

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
```

## 准备安装

1. 确保您已经克隆了本项目或下载了项目文件
2. 进入项目目录：`cd lemp`

## 配置

根据需要，修改以下配置文件：

1. `inventory/group_vars/all.yml` - 全局变量配置
2. 各个角色目录下的 `defaults/main.yml` - 角色默认变量

主要修改点：
- 密码（数据库root密码、应用数据库密码等）
- 性能配置（根据您的服务器资源调整）
- 网站配置（如果需要设置虚拟主机）

## 运行安装

使用以下命令运行安装：

```bash
# 安装完整LEMP环境
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# 或者安装特定组件
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags "nginx,php,percona"

# 单独运行一个角色
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/nginx.yml
```

如果您的用户需要输入sudo密码，请添加`--ask-become-pass`参数：

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --ask-become-pass
```

## 解决常见问题

### Ubuntu 24.04源仓库问题

在Ubuntu 24.04（Noble Numbat）上，有时会遇到PHP或其他PPA仓库的问题，出现类似错误：

```
Repository changed its 'Label' value
```

我们已经在playbook中添加了自动修复这个问题的步骤，但如果您仍然遇到问题，可以手动执行：

```bash
sudo echo 'APT::Get::AllowReleaseInfoChange "true";' > /etc/apt/apt.conf.d/99allow-release-info-change
sudo apt-get update -y --allow-releaseinfo-change
```

## 验证安装

安装完成后，验证各个组件是否正常工作：

1. 检查Nginx：`systemctl status nginx`
   浏览器访问：`http://localhost` 或 `http://127.0.0.1`

2. 检查PHP：
   浏览器访问：`http://localhost/info.php`（如果启用了info.php）

3. 检查MySQL/Percona：
   ```bash
   sudo mysql -u root -p
   ```

4. 检查Valkey/Redis：
   ```bash
   redis-cli ping
   ```

5. 检查所有服务：
   ```bash
   systemctl status nginx php8.4-fpm mysql valkey
   ```

## 其他常见问题及解决方案

1. 端口冲突：如果某些服务无法启动，可能是端口被占用
   ```bash
   sudo netstat -tulpn | grep <端口号>
   ```
   修改相应的配置文件中的端口配置

2. 如果需要在防火墙中开放端口：
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

## 安全注意事项

1. 生产环境中务必修改所有默认密码
2. 移除或禁用PHP信息页（info.php）
3. 定期更新所有组件
4. 考虑启用SSL（通过Certbot角色） 