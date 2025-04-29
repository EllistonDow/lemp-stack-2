# Percona 角色

此角色负责安装和配置Percona Server for MySQL 8.4，包括性能优化、安全设置和数据库初始化。

## 主要功能

- 从Percona官方仓库安装Percona Server for MySQL 8.4
- 设置和保护MySQL root密码
- 创建应用数据库和数据库用户
- 优化MySQL配置以提高性能
- 配置慢查询日志
- 设置自动备份

## 角色变量

变量定义在 `defaults/main.yml` 中，可以在 `inventory/group_vars/all.yml` 中覆盖：

| 变量名                      | 默认值                   | 说明                        |
|----------------------------|-------------------------|----------------------------|
| percona_version            | "8.4"                   | Percona版本                 |
| percona_root_password      | "StrongR00tPassw0rd"    | MySQL root密码              |
| percona_create_database    | true                    | 是否创建应用数据库           |
| percona_database.name      | "lemp_db"               | 应用数据库名                 |
| percona_database.user      | "lemp_user"             | 应用数据库用户               |
| percona_database.password  | "StrongDbPassw0rd"      | 应用数据库密码               |
| mysql_innodb_buffer_pool_size | "128M"                | InnoDB缓冲池大小            |
| mysql_max_connections      | 151                     | 最大连接数                   |

完整的变量列表请参见 `defaults/main.yml` 文件。

## 使用方法

### 单独运行此角色

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/percona.yml
```

### 与其他角色一起运行

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags percona
```

## 数据库配置

通过在 `inventory/group_vars/all.yml` 或 `host_vars` 中覆盖以下变量来配置应用数据库：

```yaml
percona_create_database: true
percona_database:
  name: "myapp_db"
  user: "myapp_user"
  password: "MyStrongPassword"
```

## 性能优化

MySQL配置是根据中小型服务器优化的。对于生产环境，建议根据服务器硬件和工作负载调整以下变量：

```yaml
mysql_innodb_buffer_pool_size: "2G"  # 建议设置为服务器内存的50-70%
mysql_innodb_log_file_size: "512M"
mysql_max_connections: 300
```

## 安全注意事项

- 默认情况下，MySQL只监听本地接口 (127.0.0.1)
- 已删除测试数据库和匿名用户
- 所有密码都应在生产环境中更改 