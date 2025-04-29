# LEMP Stack Ansible 自动化安装

使用Ansible自动化部署LEMP (Linux, Nginx, MySQL/Percona, PHP) 环境及相关组件的完整解决方案。

## 组件版本

| 组件        | 版本                |
|------------|---------------------|
| 操作系统     | Ubuntu 24.04        |
| Ansible    | 最新版               |
| Nginx      | 1.27.4 + ModSecurity  |
| Percona    | 8.4                 |
| PHP        | 8.4 + 8.3           |
| Redis      | Valkey 8            |
| OpenSearch | 2.19                |
| RabbitMQ   | 4                   |
| Varnish    | 7.6                 |
| Composer   | 2.8                 |
| Fail2ban   | 最新版               |
| Webmin     | 最新版               |
| phpMyAdmin | 最新版               |
| Certbot    | 最新版               |

## 目录结构

```
.
├── inventory/
│   ├── hosts.yml               # 主机清单
│   └── group_vars/             # 组变量
│       └── all.yml             # 全局变量
├── roles/                      # 角色目录
│   ├── common/                 # 基础设置
│   ├── nginx/                  # Nginx安装配置
│   ├── percona/                # Percona安装配置
│   ├── php/                    # PHP安装配置
│   ├── valkey/                 # Valkey(Redis)安装配置
│   ├── opensearch/             # OpenSearch安装配置
│   ├── rabbitmq/               # RabbitMQ安装配置
│   ├── varnish/                # Varnish安装配置
│   ├── composer/               # Composer安装配置
│   ├── fail2ban/               # Fail2ban安装配置
│   ├── webmin/                 # Webmin安装配置
│   ├── phpmyadmin/             # phpMyAdmin安装配置
│   └── certbot/                # Certbot安装配置
├── playbooks/
│   ├── site.yml                # 主playbook
│   └── individual_roles/       # 单独角色的playbook
├── vars/                       # 变量文件
│   └── main.yml                # 主变量文件
├── ansible.cfg                 # Ansible配置文件
├── LOCAL_INSTALLATION.md       # 本地安装指南
└── IMPLEMENTATION_GUIDE.md     # 实现指南
```

## 使用方法

### 本地安装（推荐）

对于在本地服务器上安装，请参考 [本地安装指南](LOCAL_INSTALLATION.md)。

### 远程安装

#### 前置条件

1. 控制节点已安装Ansible (最新版本)
2. 目标服务器可通过SSH密钥访问
3. 目标服务器为Ubuntu 24.04

#### 设置主机

编辑 `inventory/hosts.yml` 文件，添加您的服务器IP或域名。
为远程服务器安装时，需要修改配置以使用远程连接。

#### 配置变量

1. 根据需要修改 `inventory/group_vars/all.yml` 中的全局变量
2. 可选择修改各角色目录下的 `defaults/main.yml` 文件中的默认变量

#### 运行安装

全部组件安装:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

仅安装特定组件 (例如，只安装Nginx):

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/nginx.yml
```

## 安全建议

1. 默认配置已优化安全性，但生产环境使用前请根据需求进行安全审计
2. 所有数据库和服务默认只监听本地接口
3. 防火墙默认配置只开放必要端口

## 文档

每个组件的详细文档请参见各角色目录下的README.md文件。

## 授权许可

MIT 