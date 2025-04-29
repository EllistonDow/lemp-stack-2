# LEMP Stack Ansible 项目实现指南

本指南说明如何完成剩余角色的实现，以及如何使用整个项目。

## 已实现的角色

目前已经实现了以下核心角色：

1. **common** - 基础系统设置和安全配置
2. **nginx** - 安装并配置Nginx 1.27与ModSecurity
3. **php** - 安装PHP 8.4和8.3，带有所有必要扩展
4. **percona** - 安装Percona MySQL 8.4服务器
5. **valkey** - 安装Valkey 8 (Redis兼容存储)

## 待实现的角色

按照相同的模式，需要实现以下角色：

1. **varnish** - 安装Varnish 7.6缓存服务器
2. **opensearch** - 安装OpenSearch 2.19
3. **rabbitmq** - 安装RabbitMQ 4
4. **composer** - 安装Composer 2.8
5. **fail2ban** - 安装最新版Fail2ban
6. **webmin** - 安装最新版Webmin控制面板
7. **phpmyadmin** - 安装最新版phpMyAdmin
8. **certbot** - 安装最新版Certbot

## 实现方法

对于每个待实现的角色，按照以下步骤进行：

1. 创建角色目录结构（已通过前面的命令创建）
2. 创建角色的单独playbook（在playbooks/individual_roles/目录下）
3. 定义角色的默认变量（在roles/[角色名]/defaults/main.yml中）
4. 实现角色的主要任务（在roles/[角色名]/tasks/main.yml中）
5. 创建必要的模板文件（在roles/[角色名]/templates/目录下）
6. 添加处理器（在roles/[角色名]/handlers/main.yml中）
7. 编写角色的README文件（在roles/[角色名]/README.md中）

每个角色应遵循相同的结构和命名约定，以保持一致性。

## 最佳实践

1. 确保每个角色都是自包含的，可以单独运行
2. 为每个配置选项提供合理的默认值
3. 使用模板化的配置文件，而不是静态文件
4. 记录所有变量和其作用
5. 确保角色之间的依赖关系得到处理

## 使用方法

### 准备环境

1. 确保控制节点已安装Ansible（最新版）
2. 克隆项目仓库
3. 编辑inventory/hosts.yml，添加目标服务器信息

### 配置

1. 根据需要修改inventory/group_vars/all.yml中的变量
2. 如果需要，在host_vars目录下创建特定主机的变量文件

### 运行安装

安装完整LEMP环境：

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

安装特定组件：

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags "nginx,php,percona"
```

单独运行一个角色：

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/nginx.yml
```

## 测试和验证

安装完成后，可以通过以下方式验证：

1. 使用浏览器访问服务器IP地址，应该显示Nginx默认页面
2. 访问http://[服务器IP]/info.php查看PHP信息（如果启用）
3. 使用MySQL客户端连接数据库服务器进行测试
4. 检查所有服务的运行状态：`systemctl status nginx php8.4-fpm mysql`

## 安全注意事项

1. 确保修改所有默认密码
2. 生产环境中禁用phpinfo页面
3. 限制对管理界面的访问
4. 定期更新所有组件 