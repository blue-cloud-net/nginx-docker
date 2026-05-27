# NGINX Docker (Mainline)

本目录包含基于 Debian 13 与 Ubuntu 24.04 的 NGINX 最新版本自编译镜像。提供两个版本：

- **nightly 版本**：使用各项目的 master/main 主分支最新代码，通过 `git clone --depth=1` 浅层克隆获取，适合需要最新功能与修复的场景
- **all 版本**：使用指定版本号的源代码，编译过程更稳定可控

镜像集成以下特性与动态模块：

- OpenSSL 源码构建（`--with-openssl`）
- HTTP/2 与 HTTP/3（`--with-http_v2_module`, `--with-http_v3_module`）
- ModSecurity WAF 动态模块（`ModSecurity-nginx`）+ OWASP CRS 规则
- VTS（vhost_traffic_status）动态模块
- njs（JS）动态模块（`ngx_http_js_module`, `ngx_stream_js_module`）
- ngx_brotli 动态模块（`ngx_http_brotli_filter_module`, `ngx_http_brotli_static_module`）
- 其他常见内置模块：`ssl`, `slice`, `realip`, `auth_request`, `gzip_static`, `gunzip`, `image_filter`(dynamic), `xslt`(dynamic), `geoip`(dynamic), `stream_*` 等

## 目录结构

- `mainline/debian-nightly/Dockerfile`：基于 Debian 的 nightly 构建（主分支最新）
- `mainline/debian-all/Dockerfile`：基于 Debian 的稳定版本构建（指定版本号）
- `mainline/ubuntu-nightly/Dockerfile`：基于 Ubuntu 的 nightly 构建（主分支最新）
- `mainline/ubuntu-all/Dockerfile`：基于 Ubuntu 的稳定版本构建（指定版本号）
- `conf/`：Nginx 主配置与片段（`nginx.conf`, `http.conf.d/*.conf`）
- `entrypoint/`：容器入口与初始化脚本
- `html/`：默认静态页面

## 构建

请在项目根目录运行：

```zsh
# Nightly 版本（基于 master 主分支最新代码）
# 构建 Debian nightly
docker build -t my-nginx:debian-nightly -f build/nginx/mainline/debian-nightly/Dockerfile .
# 构建 Ubuntu nightly
docker build -t my-nginx:ubuntu-nightly -f build/nginx/mainline/ubuntu-nightly/Dockerfile .

# Stable 版本（基于指定版本号）
# 构建 Debian stable
docker build -t my-nginx:debian -f build/nginx/mainline/debian-all/Dockerfile .
# 构建 Ubuntu stable
docker build -t my-nginx:ubuntu -f build/nginx/mainline/ubuntu-all/Dockerfile .
```

构建产物包含 Nginx 可执行文件、动态模块与 ModSecurity 运行时依赖。

## 运行

```zsh
# 运行 Debian nightly 镜像
docker run --rm -p 8080:80 -p 8443:443 my-nginx:debian-nightly

# 运行 Ubuntu nightly 镜像
docker run --rm -p 8080:80 -p 8443:443 my-nginx:ubuntu-nightly

# 运行 Debian stable 镜像
docker run --rm -p 8080:80 -p 8443:443 my-nginx:debian

# 运行 Ubuntu stable 镜像
docker run --rm -p 8080:80 -p 8443:443 my-nginx:ubuntu
```

容器入口脚本位于 `/docker-entrypoint.sh`，会创建必要目录、链接日志和启用 ModSecurity。

## 验证

- 查看已编译模块与外部模块：

```zsh
# nightly 版本
docker run --rm my-nginx:debian-nightly nginx -V 2>&1 | tr ' ' '\n' | grep -E '(add-dynamic-module|with-http_|with-stream)'

# stable 版本
docker run --rm my-nginx:debian nginx -V 2>&1 | tr ' ' '\n' | grep -E '(add-dynamic-module|with-http_|with-stream)'
```

- 验证 Brotli：

```zsh
# 请求并声明支持 br
curl -H 'Accept-Encoding: br' -I http://localhost:8080/
```

如在 `conf/nginx.conf` 中已 `load_module` 两个 brotli 模块，且在 `http.conf.d/brotli.conf` 启用：

```nginx
brotli on;
brotli_comp_level 6;
brotli_static always;
brotli_types text/plain text/css text/xml application/xml application/json application/javascript application/x-javascript application/rss+xml application/atom+xml application/vnd.ms-fontobject font/ttf font/otf image/svg+xml;
```

- 验证 ModSecurity 与 CRS 已加载：检查 `/etc/nginx/modsecurity/modsecurity.conf` 与包含的 `owasp-crs` 规则。

## 可选模块（未启用但可根据需要添加）

- `--with-http_stub_status_module`（状态页）
- `--with-http_degradation_module`（低资源退化）
- `--with-http_perl_module[=dynamic]`（Perl 集成）
- `--with-google_perftools_module`（性能剖析）
- `--with-cpp_test_module`（测试，仅开发）
- `--with-stream=dynamic`、`--with-mail=dynamic`（改为动态装载）

若需要上述功能，请在两个 Dockerfile 的 `./auto/configure` 参数中加入对应 `--with-...` 并重新构建。

## 常见问题

- 动态模块依赖缺失（Debian runtime）：
  - `image_filter` 需要 `libgd3`
  - `xslt` 需要 `libxml2`, `libxslt1.1`
  - 解决方法：在 Debian 运行时层添加：

```dockerfile
apt-get install -y libgd3 libxml2 libxslt1.1
```

- 端口占用：确保宿主机未占用 `80/443`，或映射到其他端口。
- 证书：启用 HTTPS 时需提供证书与私钥。

## 许可

本仓库 Dockerfile 与脚本为自有工程文件；所引入的第三方代码按各自上游许可使用（OpenSSL、nginx、ModSecurity、OWASP CRS、ngx_brotli、njs 等）。
