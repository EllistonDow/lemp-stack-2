# Nginx 角色

此角色负责安装和配置Nginx Web服务器，包括ModSecurity Web应用防火墙集成。

## 主要功能

- 从Nginx官方仓库安装最新版本的Nginx
- 配置主要的Nginx设置
- 安装和配置ModSecurity (可选)
- 设置默认虚拟主机
- 根据配置创建和配置多个虚拟主机
- 优化性能和安全设置

## 角色变量

变量定义在 `defaults/main.yml` 中，可以在 `inventory/group_vars/all.yml` 中覆盖：

| 变量名                     | 默认值               | 说明                |
|---------------------------|---------------------|---------------------|
| nginx_version             | "1.27"              | Nginx版本           |
| nginx_worker_processes    | "auto"              | 工作进程数          |
| nginx_worker_connections  | 1024                | 每个进程的最大连接数 |
| nginx_client_max_body_size| "64m"               | 客户端请求体最大大小 |
| nginx_server_tokens       | "off"               | 是否显示版本信息    |
| nginx_install_modsecurity | true                | 是否安装ModSecurity |
| nginx_default_site_enabled| true                | 是否启用默认站点    |

完整的变量列表请参见 `defaults/main.yml` 文件。

## 使用方法

### 单独运行此角色

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/nginx.yml
```

### 与其他角色一起运行

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags nginx
```

## 虚拟主机配置

通过在 `inventory/group_vars/all.yml` 或 `host_vars` 中定义 `websites` 变量来配置虚拟主机：

```yaml
websites:
  - name: "example.com"
    server_name: "example.com www.example.com"
    root: "/var/www/example.com"
    php_version: "8.4"
    ssl: false
  
  - name: "secure.example.com"
    server_name: "secure.example.com"
    root: "/var/www/secure.example.com"
    php_version: "8.3"
    ssl: true
    certbot_email: "admin@example.com"
```

## ModSecurity 配置

默认安装并启用ModSecurity，使用OWASP核心规则集。可以通过设置 `nginx_install_modsecurity: false` 来禁用此功能。

ModSecurity日志位于 `/var/log/nginx/modsecurity_audit.log`。 