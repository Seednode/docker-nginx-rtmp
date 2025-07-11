# multi-stage build for dockerized nginx

# set up nginx build container
FROM alpine:edge AS nginx

# install dependencies
RUN apk add --update-cache \
    curl \
    g++ \
    gcc \
    git \
    linux-headers \
    make \
    perl \
    tar \
    upx

# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER=10.45
RUN curl -L -O "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VER}/pcre2-${PCRE_VER}.tar.gz" \
    && tar xzf "/src/pcre/pcre2-${PCRE_VER}.tar.gz"

# download openssl
ARG OPENSSL_VER=openssl-3.5.1
WORKDIR /src/openssl
RUN git clone -b "${OPENSSL_VER}" https://github.com/openssl/openssl.git /src/openssl
ARG CORE_COUNT=1
RUN ./config && make -j"${CORE_COUNT}"

# download zlib
WORKDIR /src/zlib
ARG ZLIB_VER=1.3.1
RUN curl -L -O "https://www.zlib.net/zlib-${ZLIB_VER}.tar.gz" \
    && tar xzf "zlib-${ZLIB_VER}.tar.gz"

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

# download the http-flv module
RUN git clone https://github.com/winshining/nginx-http-flv-module.git /src/nginx-http-flv-module

# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-${NGINX_VER}.tar.gz" \
    && tar xzf "nginx-${NGINX_VER}.tar.gz"

# configure and build nginx
WORKDIR /src/nginx/nginx-"${NGINX_VER}"
RUN ./configure --prefix=/usr/share/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/tmp/nginx.pid \
                --lock-path=/run/lock/subsys/nginx \
                --http-client-body-temp-path=/tmp/nginx/client \
                --http-proxy-temp-path=/tmp/nginx/proxy \
                --with-threads \
                --with-file-aio \
                --with-zlib="/src/zlib/zlib-${ZLIB_VER}" \
                --with-ld-opt='lpcre' \
                --with-pcre="/src/pcre/pcre2-${PCRE_VER}" \
                --with-pcre-jit \
                --with-openssl="/src/openssl" \
                --with-http_addition_module \
                --with-http_random_index_module \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --with-http_sub_module \
                --add-module=/src/ngx-fancyindex \
                --add-module=/src/nginx-http-flv-module \
                --without-http_fastcgi_module \
                --without-http_uwsgi_module \
                --without-http_scgi_module \
                --without-select_module \
                --without-poll_module \
                --without-mail_pop3_module \
                --without-mail_imap_module \
                --without-mail_smtp_module \
                --with-cc-opt="-O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
                --with-ld-opt="-Wl,--gc-sections -s -static -static-libgcc" \
    && make -j"${CORE_COUNT}" \
    && make install

# compress the nginx binary
RUN upx --best /usr/sbin/nginx

# setup nginx folders and files
RUN mkdir -p /etc/nginx \
    && mkdir -p /tmp/nginx/client \
    && mkdir -p /tmp/nginx/proxy \
    && mkdir -p /usr/share/nginx/fastcgi_temp \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/www/html \
    && touch /tmp/nginx.pid

# copy in default nginx configs
COPY nginx/ /etc/nginx/

# set up the final container
FROM scratch

# create nonroot user
COPY passwd /etc/passwd

# run as nonroot
USER nonroot

# copy nginx files over
COPY --from=nginx --chown=nonroot:nonroot /etc/nginx /etc/nginx
COPY --from=nginx --chown=nonroot:nonroot /tmp/nginx.pid /tmp/nginx.pid
COPY --from=nginx --chown=nonroot:nonroot /tmp/nginx /tmp/nginx
COPY --from=nginx --chown=nonroot:nonroot /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx --chown=nonroot:nonroot /usr/share/nginx/fastcgi_temp /usr/share/nginx/fastcgi_temp
COPY --from=nginx --chown=nonroot:nonroot /var/log/nginx /var/log/nginx
COPY --from=nginx --chown=nonroot:nonroot /var/www/html /var/www/html
COPY --chown=nonroot:nonroot html/index.html /var/www/html/index.html
COPY fastcgi.conf /etc/nginx/
COPY fastcgi_params /etc/nginx/

# copy in dash and hls scripts
COPY --chown=nonroot:nonroot scripts/* /usr/bin/

# copy in dash player
COPY --chown=nonroot:nonroot js/ /var/www/html/js/

# listen on an unprivileged port
EXPOSE 1935
EXPOSE 8080

# configure entrypoint
ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
