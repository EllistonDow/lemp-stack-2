# Common 角色

此角色负责配置基础系统环境，包括安装基础软件包、设置系统时区和区域、配置防火墙规则、系统限制等。

## 主要功能

- 安装基础系统软件包
- 设置系统时区和区域
- 更新所有软件包
- 配置并启用防火墙
- 设置主机名
- 根据需要创建swap文件
- 配置系统限制（打开文件数、最大进程数）
- 禁用不必要的系统服务

## 角色变量

变量定义在 `defaults/main.yml` 中，可以在 `inventory/group_vars/all.yml` 中覆盖：

| 变量名                  | 默认值                | 说明                 |
|------------------------|----------------------|---------------------|
| timezone               | 'UTC'                | 系统时区             |
| locale                 | 'en_US.UTF-8'        | 系统区域设置         |
| system_packages        | [软件包列表]          | 要安装的基础软件包   |
| firewall_enabled       | true                 | 是否启用防火墙       |
| firewall_allowed_tcp_ports | [22, 80, 443]    | 允许的TCP端口        |
| hostname               | 未定义                | 服务器主机名         |

## 使用方法

### 单独运行此角色

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/common.yml
```

### 与其他角色一起运行

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags common
```

## 示例配置

在 `inventory/group_vars/all.yml` 中：

```yaml
# 系统设置
timezone: 'America/Los_Angeles'
locale: 'en_US.UTF-8'
system_packages:
  - software-properties-common
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - python3-pip
  - unzip
  - vim
  - htop
  - git
  - wget

# 防火墙设置
firewall_enabled: true
firewall_allowed_tcp_ports:
  - 22   # SSH
  - 80   # HTTP
  - 443  # HTTPS
  - 10000 # Webmin
``` 