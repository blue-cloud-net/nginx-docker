FROM ubuntu:24.04 AS build

RUN apt update \
    && apt upgrade -y \
    && apt install -y curl

ENV NGINX_VERSION=1.29.2
ENV OPENSSL_VERSION=3.6.0
ENV VTS_VERSION=0.2.4
ENV MODSECURITY_VERSION=3.0.14
ENV MODSECURITY_NGINX_VERSION=1.0.4
ENV CORERULESET_VERSION=4.19.0
ENV LIBINJECTION_VERSION=3.10.0
ENV MBED_TLS_VERSION=3.6.3
ENV BROTLI_VERSION=1.1.0
ENV NJS_VERSION=0.9.3

WORKDIR /workdir
RUN curl -Ljf https://github.com/nginx/nginx/archive/refs/tags/release-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && curl -Ljf https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz -o openssl.tar.gz \
    && curl -Ljf https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v${VTS_VERSION}.tar.gz -o vts.tar.gz \
    && curl -Ljf https://github.com/owasp-modsecurity/ModSecurity/archive/refs/tags/v${MODSECURITY_VERSION}.tar.gz -o modsecurity.tar.gz \
    && curl -Ljf https://github.com/owasp-modsecurity/ModSecurity-nginx/archive/refs/tags/v${MODSECURITY_NGINX_VERSION}.tar.gz -o modsecurity-nginx.tar.gz \
    && curl -Ljf https://github.com/coreruleset/coreruleset/releases/download/v${CORERULESET_VERSION}/coreruleset-${CORERULESET_VERSION}-minimal.tar.gz -o coreruleset.tar.gz \
    && curl -Ljf https://github.com/libinjection/libinjection/archive/refs/tags/v${LIBINJECTION_VERSION}.tar.gz -o libinjection.tar.gz \
    && curl -Ljf https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-${MBED_TLS_VERSION}.tar.gz -o mbedtls.tar.gz \
    && curl -Ljf https://github.com/google/ngx_brotli/archive/refs/heads/master.tar.gz -o brotli-nginx.tar.gz \
    && curl -Ljf https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz -o brotli.tar.gz \
    && curl -Ljf https://github.com/nginx/njs/archive/refs/tags/${NJS_VERSION}.tar.gz -o njs.tar.gz \
    && tar -zxvf nginx.tar.gz \
    && tar -zxvf openssl.tar.gz \
    && tar -zxvf vts.tar.gz \
    && tar -zxvf modsecurity.tar.gz \
    && tar -zxvf modsecurity-nginx.tar.gz \
    && tar -zxvf coreruleset.tar.gz \
    && tar -zxvf libinjection.tar.gz -C ModSecurity-${MODSECURITY_VERSION}/others/ \
    && tar -zxvf mbedtls.tar.gz -C ModSecurity-${MODSECURITY_VERSION}/others/ \
    && tar -zxvf brotli-nginx.tar.gz && mv ngx_brotli-master brotli-nginx \
    && tar -zxvf brotli.tar.gz -C brotli-nginx/deps/ \
    && tar -zxvf njs.tar.gz

# 移除文件夹版本号
RUN mv nginx-release-${NGINX_VERSION} nginx \
    && mv openssl-openssl-${OPENSSL_VERSION} openssl \
    && mv nginx-module-vts-${VTS_VERSION} vts-nginx \
    && mv ModSecurity-${MODSECURITY_VERSION} modsecurity \
    && mv ModSecurity-nginx-${MODSECURITY_NGINX_VERSION} modsecurity-nginx \
    && mv coreruleset-${CORERULESET_VERSION} coreruleset \
    && rm -rf modsecurity/others/libinjection modsecurity/others/mbedtls \
    && mv modsecurity/others/libinjection-${LIBINJECTION_VERSION} modsecurity/others/libinjection \
    && mv modsecurity/others/mbedtls-mbedtls-${MBED_TLS_VERSION} modsecurity/others/mbedtls \
    && rm -rf brotli-nginx/deps/brotli \
    && mv brotli-nginx/deps/brotli-${BROTLI_VERSION} brotli-nginx/deps/brotli \
    && mv njs-${NJS_VERSION} njs

# 安装编译工具和依赖
RUN apt install -y git build-essential cmake libtool pkg-config autoconf automake
RUN apt install -y libgeoip-dev libpcre2-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev

# 编译ModSecurity
WORKDIR /workdir/modsecurity
RUN ./build.sh \
    && ./configure \
        --prefix=/usr/local/lib/modsecurity \
        --disable-doxygen-doc \
        --disable-doxygen-html \
        --disable-examples \
        --with-geoip \
        --with-pcre2 \
    && make -j \
    && make install \
    && rm -f /usr/local/lib/modsecurity/lib/libmodsecurity.a \
    && rm -f /usr/local/lib/modsecurity/lib/libmodsecurity.la \
    && rm -rf /usr/local/lib/modsecurity/lib/pkgconfig

# 编译brotli
WORKDIR /workdir/brotli-nginx/deps/brotli
RUN mkdir -p out \
    && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_C_FLAGS="-Ofast -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
        -DCMAKE_CXX_FLAGS="-Ofast -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
        -DCMAKE_INSTALL_PREFIX=./installed .. \
    && cmake --build . --config Release --target brotlienc

# 设置编译环境变量
ENV MODSECURITY_INC=/workdir/modsecurity/headers/
ENV MODSECURITY_LIB=/workdir/modsecurity/src/.libs/

WORKDIR /workdir/nginx
RUN  ./auto/configure \
        --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
        --prefix=/opt/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/lock/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_geoip_module=dynamic \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_image_filter_module=dynamic \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-http_xslt_module=dynamic \
        --with-ipv6 \
        --with-mail=dynamic \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_geoip_module=dynamic \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-threads \
        --with-pcre \
        --with-pcre-jit \
        # --with-jemalloc \
        # 指定OpenSSL路径
        --with-openssl=../openssl \
        # 添加ModSecurity模块
        --add-dynamic-module=../modsecurity-nginx \
        # 添加VTS模块
        --add-dynamic-module=../vts-nginx \
        # 添加brotli动态模块
        --add-dynamic-module=../brotli-nginx \
        # 添加njs动态模块
        --add-dynamic-module=../njs/nginx \
        --with-debug \
    && make -j \
    && make install

FROM ubuntu:24.04 AS runtime

COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /usr/lib/nginx/modules/ /usr/lib/nginx/modules/
COPY --from=build /usr/local/lib/modsecurity/lib/ /usr/local/lib/modsecurity/
COPY conf/ /etc/nginx/
COPY --from=build /workdir/modsecurity/unicode.mapping /etc/nginx/modsecurity/unicode.mapping
COPY --from=build /workdir/modsecurity/modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
COPY --from=build /workdir/coreruleset/rules/ /etc/nginx/modsecurity/owasp-crs/rules/
COPY --from=build /workdir/coreruleset/crs-setup.conf.example /etc/nginx/modsecurity/owasp-crs/crs-setup.conf
COPY html/ /usr/share/nginx/html/

# create nginx user/group first, to be consistent throughout docker variants \
RUN groupadd --system nginx \
    && useradd --system -d /var/cache/nginx --shell /sbin/nologin -g nginx nginx \
    # install runtime dependencies
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl dnsutils net-tools iputils-ping \
        libpcre2-8-0 \
        libgeoip1 \
        libgd3 \
        libxml2 \
        libxslt1.1 \
    # clean up
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # link modsecurity libraries
    && ln -sf /usr/local/lib/modsecurity/libmodsecurity.so.3 /lib/libmodsecurity.so.3 \
    # create nginx folders
    && mkdir -p /etc/nginx/conf.d/ \
    && mkdir -p /etc/nginx/http.conf.d/ \
    && mkdir -p /etc/nginx/stream.conf.d/ \
    # set modsecurity
    && echo "modsecurity on;" > /etc/nginx/conf.d/modsecurity.conf \
    && echo "modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;" >> /etc/nginx/conf.d/modsecurity.conf \
    && sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf \
    && echo "\n\n\n" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo "SecAuditLogStorageDir /var/log/audit/\n\n" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo "Include /etc/nginx/modsecurity/owasp-crs/crs-setup.conf" >> /etc/nginx/modsecurity/modsecurity.conf \
    && echo "Include /etc/nginx/modsecurity/owasp-crs/rules/*.conf" >> /etc/nginx/modsecurity/modsecurity.conf \
    # create cache directories
    && install -d -m 755 /var/cache/nginx \
    # create modules folder
    && install -d -m 755 /usr/lib/nginx/modules \
    && ln -sf /usr/lib/nginx/modules /etc/nginx/modules \
    # forward request and error logs to docker log collector
    && install -d -m 755 /var/log/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    # create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d

COPY entrypoint/docker-entrypoint.sh /
COPY entrypoint/docker-entrypoint.d/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY entrypoint/docker-entrypoint.d/15-local-resolvers.envsh /docker-entrypoint.d
COPY entrypoint/docker-entrypoint.d/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY entrypoint/docker-entrypoint.d/30-tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR /usr/local/nginx
EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]