# PHP 角色

此角色负责安装和配置PHP环境，支持多个PHP版本并安装所需的PHP扩展，还可配置PHP-FPM服务。

## 主要功能

- 安装多个PHP版本 (8.4 和 8.3)
- 配置PHP.ini设置
- 配置PHP-FPM
- 安装和配置常用PHP扩展
- 安装Composer (可选)
- 创建PHP信息页面 (可选)

## 角色变量

变量定义在 `defaults/main.yml` 中，可以在 `inventory/group_vars/all.yml` 中覆盖：

| 变量名                     | 默认值                | 说明                   |
|---------------------------|----------------------|------------------------|
| php_versions              | ["8.4", "8.3"]       | 要安装的PHP版本        |
| default_php_version       | "8.4"                | 默认PHP版本            |
| php_packages              | [扩展列表]            | 要安装的PHP扩展        |
| php_memory_limit          | "256M"               | PHP内存限制            |
| php_max_execution_time    | 60                   | 最大执行时间 (秒)       |
| php_upload_max_filesize   | "64M"                | 上传文件大小限制        |
| php_post_max_size         | "64M"                | POST数据大小限制        |
| php_expose_php            | "Off"                | 是否暴露PHP版本        |
| php_opcache_enable        | 1                    | 是否启用OPcache        |
| php_install_composer      | true                 | 是否安装Composer       |
| composer_version          | "2.8"                | Composer版本           |
| php_create_info_page      | true                 | 是否创建PHP信息页      |

完整的变量列表请参见 `defaults/main.yml` 文件。

## 使用方法

### 单独运行此角色

```bash
ansible-playbook -i inventory/hosts.yml playbooks/individual_roles/php.yml
```

### 与其他角色一起运行

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags php
```

## PHP-FPM配置

PHP-FPM进程管理器配置可通过以下变量进行调整：

```yaml
php_fpm_pm: dynamic
php_fpm_max_children: 50
php_fpm_start_servers: 5
php_fpm_min_spare_servers: 5
php_fpm_max_spare_servers: 35
php_fpm_max_requests: 500
```

## Composer配置

如果启用了Composer安装（默认启用），您可以通过设置 `composer_global_packages` 变量来安装全局Composer包：

```yaml
composer_global_packages:
  - phpunit/phpunit
  - squizlabs/php_codesniffer
  - phpstan/phpstan
```

## 注意事项

- 默认情况下，会创建一个PHP信息页面 (`info.php`)，生产环境中建议将 `php_create_info_page` 设置为 `false`
- 安全设置默认已配置为推荐的生产环境值（如 `expose_php = Off`, `allow_url_fopen = Off` 等） 