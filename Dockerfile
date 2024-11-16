FROM ubuntu:18.04 as base

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y \
    expect subversion build-essential \
    lib32stdc++6 gcc-multilib g++-multilib \
    python-dev pypy-dev gdb python2.7-dbg \
    libcurl4-openssl-dev graphviz openssl libssl-dev swig gawk iotop lsof iftop \
    ifstat iptraf htop dstat iotop \
    ltrace strace sysstat bmon nethogs \
    silversearcher-ag libsasl2-2 sasl2-bin \
    libsasl2-modules python-setuptools luajit \
    curl wget unzip jq python-pip \
    libpcre3 libpcre3-dev zlib1g zlib1g-dev \ 
    libxml2-dev libbz2-dev libwebp-dev libjpeg-dev  \ 
    libpng-dev libfreetype6-dev libgmp-dev \ 
    libmcrypt-dev libreadline-dev libxslt-dev \
    && \
    rm -rf /var/lib/apt/lists/* /tmp/*

FROM base as install_nginx

# 安装宝塔; 我选择不安宝塔，手动配置环境
# RUN wget -O install.sh http://download.bt.cn/install/install-ubuntu_6.0.sh && \
#     echo "y" | bash install.sh > ~/bt_install.log

# Nginx 1.18 MySQL 5.6 Php 7.1, 编译安装
# 注：编译安装需要：libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
ARG NGINX_VERSION=nginx-1.1.18
ENV CFLAGS="-Wno-implicit-fallthrough"
RUN ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl && \
    cd /tmp && wget http://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxvf ${NGINX_VERSION}.tar.gz && \
    cd ${NGINX_VERSION} && \
    ./configure \ 
        --prefix=/usr \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
    && \
    make && make install && \
    mkdir -p /etc/nginx/sites-available && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /www/wwwroot && \
    rm -rf /tmp/*


FROM install_nginx as install_php

# php依赖 libxml2-dev libbz2-dev libwebp-dev libpng-dev
# GM后台使用了curl模块，所以--with--curl是必须的
# 注意php中 curl路径与现有curl路径是不同的
# 使用 ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl
COPY ./php-7.1.0.tar.gz /tmp/

RUN cd /tmp/ && \
    ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl && \
    ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
    tar -zxvf php-7.1.0.tar.gz && \
    cd /tmp/php-7.1.0 \ 
    && \ 
    ./configure --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --enable-fpm --with-fpm-user=www \
        --with-fpm-group=www \
        --with-mysqli \
        --with-pdo-mysql \
        --with-iconv-dir \
        --with-freetype-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib \
        --with-libxml-dir=/usr \
        --enable-xml \
        --disable-rpath \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --with-curl \
        --enable-mbregex \
        --enable-mbstring \
        --enable-ftp \
        --with-gd \
        --with-openssl \
        --with-mhash \
        --enable-pcntl \
        --enable-sockets \
        --with-xmlrpc \
        --enable-zip \
        --enable-soap \
        --without-pear \
        --with-gettext \
        --disable-fileinfo \
        --enable-maintainer-zts && \
    groupadd www && useradd -g www www && \
    make -j$(nproc) && make install && \
    mkdir -p /usr/local/php/etc/ && \
    cp php.ini-development /usr/local/php/etc/php.ini && \
    cp sapi/fpm/php-fpm.conf /usr/local/php/etc/php-fpm.conf && \
    cd /usr/local/php/etc && cp php-fpm.d/www.conf.default php-fpm.d/www.conf && \
    rm -rf /tmp/*

# ENTRYPOINT ["/bin/bash"]

FROM install_php as install_mongo

#     /usr/local/php/sbin/php-fpm
#     echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
# 然后，在浏览器中访问 http://localhost/info.php，

# 安装 MongoDB 3.6
ARG MONGO_URL=https://repo.mongodb.org/apt/ubuntu/dists/bionic/mongodb-org/3.6/multiverse/binary-amd64/
ARG MONGO_SERVER=mongodb-org-server_3.6.20_amd64.deb
ARG MONGO_MONGOS=mongodb-org-mongos_3.6.20_amd64.deb
ARG MONGO_TOOLS=mongodb-org-tools_3.6.20_amd64.deb
ARG MONGO_SHELL=mongodb-org-shell_3.6.20_amd64.deb

RUN wget ${MONGO_URL}${MONGO_SERVER} -O /tmp/${MONGO_SERVER} && \
    wget ${MONGO_URL}${MONGO_MONGOS} -O /tmp/${MONGO_MONGOS} && \
    wget ${MONGO_URL}${MONGO_TOOLS} -O /tmp/${MONGO_TOOLS} && \
    wget ${MONGO_URL}${MONGO_SHELL} -O /tmp/${MONGO_SHELL} && \
    dpkg -i /tmp/${MONGO_SERVER} /tmp/${MONGO_MONGOS} /tmp/${MONGO_TOOLS} /tmp/${MONGO_SHELL} || true && \
    apt-get install -f -y && \
    rm -f /tmp/${MONGO_SERVER} /tmp/${MONGO_MONGOS} /tmp/${MONGO_TOOLS} /tmp/${MONGO_SHELL} && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

    
FROM install_mongo as install_python_env

# 安装 Python 库和其他工具
RUN rm -rf /usr/lib/python2.7/dist-packages/OpenSSL && \
    rm -rf /usr/lib/python2.7/dist-packages/pyOpenSSL-0.15.1.egg-info && \
    pip install cython six lz4==0.8.2 numpy==1.16.0 \
    xlrd xdot rpdb psutil==5.6.7 fabric==1.7.3 pycurl pycrypto \
    M2Crypto==0.36.0 objgraph msgpack-python \
    backports.ssl-match-hostname Markdown toro \
    pymongo pyrasite pyopenssl ThinkingDataSdk==1.4.0 \
    tornado==4.4.2 Supervisor==3.3.0 cryptography==2.6 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*


FROM install_python_env

# 复制应用文件
COPY kdjx.tar.gz Entrypoint.sh game.conf nginx.conf /tmp/


# 解压文件 
# 将 default 文件移动到 /etc/nginx/sites-available/
# 解压 pokemon_server_test.tar.gz 到 /mnt 目录
# 解压 game.tar.gz 到 /www/wwwroot 目录
RUN cd /tmp && \
    tar -zxvf /tmp/kdjx.tar.gz && \
    tar -zxvf /tmp/mongodb.tar.gz -C / && \
    mv /tmp/default /etc/nginx/sites-available/ && echo "Moved default" && \
    tar -zxvf /tmp/pokemon_server_test.tar.gz -C /mnt && echo "Pokemon server test extracted" && \
    chmod 755 -R /mnt && \
    tar -zxvf /tmp/game.tar.gz -C /www/wwwroot && echo "Game extracted" && \ 
    chmod 777 -R /www/wwwroot/ && \
    mv /tmp/Entrypoint.sh /Entrypoint.sh && chmod +x /Entrypoint.sh && \
    mv /tmp/game.conf /usr/local/game.conf && \
    mv /tmp/nginx.conf /etc/nginx/nginx.conf && \
    mkdir -p /etc/nginx/snippets/ && \
    echo 'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' > /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param QUERY_STRING $query_string;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param REQUEST_METHOD $request_method;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param CONTENT_TYPE $content_type;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param CONTENT_LENGTH $content_length;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SCRIPT_NAME $fastcgi_script_name;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param REQUEST_URI $request_uri;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param DOCUMENT_URI $document_uri;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param DOCUMENT_ROOT $document_root;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SERVER_PROTOCOL $server_protocol;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param HTTPS $https if_not_empty;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param GATEWAY_INTERFACE CGI/1.1;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SERVER_SOFTWARE nginx/$nginx_version;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param REMOTE_ADDR $remote_addr;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param REMOTE_PORT $remote_port;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SERVER_ADDR $server_addr;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SERVER_PORT $server_port;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    echo 'fastcgi_param SERVER_NAME $server_name;' >> /etc/nginx/snippets/fastcgi-php.conf && \
    rm -rf /tmp/*



# 暴露端口
EXPOSE 80 27017 8888 888 20 21 80 44 13410
# 后台
EXPOSE 39081 81
# 登录、公告
EXPOSE 16666 18080 1104 1144
# 大区服务器端口 /mnt/pokemon/release/login/conf/serv.json
EXPOSE 28879

# 修改服务端文件的逻辑现在由启动脚本Entrypoint.sh完成

WORKDIR /mnt/pokemon/deploy_dev

ENTRYPOINT ["/Entrypoint.sh"]