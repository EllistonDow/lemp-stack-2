# ModSecurity 配置修复

## 问题描述
Nginx 错误日志中显示 "unknown directive 'modsecurity'" 错误，这是由于 ModSecurity 指令放置在错误的位置导致的。

## 解决方案
1. 将 ModSecurity 指令从独立的配置文件移动到 Nginx 主配置文件的 http 块内
2. 确保 ModSecurity 模块正确加载

## 具体步骤
1. 移除了错误的配置文件 `/etc/nginx/conf.d/modsecurity.conf`
2. 在 `/etc/nginx/nginx.conf` 的 http 块中添加以下配置：
   ```
   # ModSecurity 配置
   modsecurity on;
   modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;
   ```
3. 确认 ModSecurity 动态模块正确加载：
   ```
   # 加载动态模块
   include /etc/nginx/modules-enabled/*.conf;
   ```

## 验证
检查 Nginx 错误日志，确认没有再出现 "unknown directive 'modsecurity'" 错误，且显示 ModSecurity 正常加载。 