# multi-stage build for dockerized nginx

# set up nginx build container
FROM alpine:latest AS nginx
RUN apk add gcc g++ git curl make linux-headers tar gzip perl

# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

# download openssl
ARG OPENSSL_VER="openssl-3.0.1"
WORKDIR /src/openssl
RUN git clone -b $OPENSSL_VER git://git.openssl.org/openssl.git /src/openssl
RUN ./config && make -j"$CORE_COUNT"

# download zlib
WORKDIR /src/zlib
ARG ZLIB_VER="1.2.11"
RUN curl -L -O "https://www.zlib.net/zlib-$ZLIB_VER.tar.gz"
RUN tar xzf "zlib-$ZLIB_VER.tar.gz"

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

# download the nginx-http-flv module
RUN git clone https://github.com/winshining/nginx-http-flv-module.git /src/nginx-http-flv-module

# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

# configure and build nginx
WORKDIR /src/nginx/nginx-"$NGINX_VER"
RUN ./configure --prefix=/usr/share/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/run/nginx.pid \
                --lock-path=/run/lock/subsys/nginx \
                --http-client-body-temp-path=/tmp/nginx/client \
                --http-proxy-temp-path=/tmp/nginx/proxy \
                --user=www-data \
                --group=www-data \
                --with-threads \
                --with-file-aio \
                --with-zlib="/src/zlib/zlib-$ZLIB_VER" \
                --with-pcre="/src/pcre/pcre-$PCRE_VER" \
                --with-pcre-jit \
                --with-openssl="/src/openssl" \
                --with-http_addition_module \
                --with-http_ssl_module \
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
                --with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
                --with-ld-opt="-static"
ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

# set up the final container
FROM alpine:latest

# setup nginx folders and files
RUN adduser www-data -D -H -G www-data
RUN mkdir -p /etc/nginx && chown -R www-data:www-data /etc/nginx
RUN mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/
RUN mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html
RUN touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid
RUN mkdir -p /etc/nginx 

# copy in nginx configs
COPY nginx/ /etc/nginx/

# copy in dash and hls scripts
COPY scripts/* /usr/bin/

# copy in dash player
COPY js/ /var/www/html/js/

# add nginx binary
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx

# configure entrypoint
ENTRYPOINT ["/usr/sbin/nginx","-g","daemon off;"]
