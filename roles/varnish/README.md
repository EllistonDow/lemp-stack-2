# Ansible Role: Varnish 7.6

这个角色用于在Ubuntu 24.04上安装和配置Varnish 7.6缓存服务器。

## 功能

- 安装Varnish 7.6版本
- 配置Varnish服务
- 创建自定义VCL配置
- 设置systemd服务
- 配置日志

## 配置项

所有配置项都在 `defaults/main.yml` 文件中定义，以下是一些主要的配置项：

| 变量名                  | 默认值                 | 描述                           |
|------------------------|------------------------|-------------------------------|
| varnish_version        | 7.6                    | Varnish版本                    |
| varnish_listen_port    | 6081                   | Varnish监听端口                |
| varnish_backend_host   | 127.0.0.1              | 后端服务器地址                  |
| varnish_backend_port   | 8080                   | 后端服务器端口                  |
| varnish_storage        | malloc,256m            | 存储配置                        |
| varnish_ttl            | 120                    | 默认缓存TTL（秒）               |

## 使用方法

### 基本用法

```yaml
- hosts: all
  roles:
    - varnish
```

### 自定义配置

```yaml
- hosts: all
  vars:
    varnish_listen_port: 80
    varnish_backend_port: 8080
    varnish_storage: "malloc,512m"
  roles:
    - varnish
```

## 配置Nginx与Varnish

为了让Varnish作为前端缓存服务器，需要将Nginx配置为在8080端口监听。建议在Nginx角色中添加以下配置：

```yaml
# 在nginx角色的配置中
nginx_listen_port: 8080
```

## 依赖

- 这个角色没有显式的依赖，但为了完全发挥Varnish的功能，推荐与Nginx角色一起使用。

## 注意事项

- Varnish将监听6081端口，Nginx后端应监听8080端口
- 在生产环境中，请适当调整缓存大小和TTL设置
- 确保Nginx和Varnish的端口配置正确匹配 