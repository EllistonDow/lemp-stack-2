# Valkey 角色

此角色负责安装和配置Valkey（Redis兼容的内存数据存储），支持基本配置、性能优化和安全设置。

## 主要功能

- 从官方仓库安装Valkey 8
- 配置基本设置和性能参数
- 配置持久化（RDB和AOF）
- 设置内存限制和驱逐策略
- 配置安全选项（密码、绑定接口）
- 设置为系统服务

## 角色变量

变量定义在 `defaults/main.yml` 中，可以在 `inventory/group_vars/all.yml` 中覆盖：

| 变量名                  | 默认值               | 说明                     |
|------------------------|---------------------|--------------------------|
| valkey_version         | "8"                 | Valkey版本               |
| valkey_port            | 6379                | 监听端口                 |
| valkey_bind_interface  | "127.0.0.1"         | 绑定接口                 |
| valkey_password        | ""                  | 访问密码（空为无密码）    |
| valkey_maxmemory       | "128mb"             | 最大内存使用量           |
| valkey_maxmemory_policy| "allkeys-lru"       | 内存策略                 |
| valkey_appendonly      | "yes"               | 是否启用AOF持久化        |
| valkey_appendfsync     | "everysec"          | AOF同步策略              |

完整的变量列表请参见 `defaults/main.yml` 文件。

## 使用方法

### 单独运行此角色

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/valkey.yml
```

### 与其他角色一起运行

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags valkey
```

## 配置示例

### 基本配置

```yaml
valkey_port: 6379
valkey_bind_interface: "127.0.0.1"  # 只监听本地接口
```

### 启用密码保护

```yaml
valkey_password: "your_strong_password"
```

### 调整内存设置

```yaml
valkey_maxmemory: "1gb"
valkey_maxmemory_policy: "volatile-lru"  # 只删除设置了过期时间的键
```

### 持久化配置

```yaml
# RDB持久化设置
valkey_save:
  - "900 1"    # 900秒内至少1个键变化
  - "300 10"   # 300秒内至少10个键变化
  - "60 10000" # 60秒内至少10000个键变化

# AOF持久化设置
valkey_appendonly: "yes"
valkey_appendfsync: "everysec"  # 每秒同步一次
```

## 注意事项

- 默认情况下，Valkey只监听本地接口(127.0.0.1)，生产环境如需对外提供服务，请更改绑定接口并设置强密码
- 最大内存限制默认为128MB，生产环境中应根据服务器可用内存和应用需求调整
- 默认已启用AOF持久化，确保数据安全 