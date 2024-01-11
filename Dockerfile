FROM alpine:3.19

ARG github_token
ARG php_version

USER root

# @todo: make php version interchangeable
RUN apk add --no-cache \
      git build-base go imagemagick ghostscript freetype-dev curl \
      php82-phar php82-iconv php82-openssl \
      # Install locales
      musl musl-utils musl-locales tzdata && \
    # Add composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    # Download FrankenPHP
    git clone https://github.com/dunglas/frankenphp /frankenphp && \
    cd /frankenphp && \
    # Build FrankenPHP
    GITHUB_TOKEN=$github_token \
    CLEAN=1 \
    PHP_VERSION=8.2 \
    PHP_EXTENSIONS=password-argon2,apcu,bcmath,bz2,ctype,curl,dba,dom,exif,fileinfo,filter,zlib,gd,iconv,igbinary,intl,openssl,mbstring,mbregex,mysqlnd,mysqli,opcache,pcntl,pdo,pdo_mysql,pgsql,pdo_pgsql,sqlite3,pdo_sqlite,phar,posix,readline,session,redis,simplexml,sockets,sysvsem,tokenizer,xml,zip \
    ./build-static.sh && \
    ls -lah /frankenphp/dist/ && \
    # Make FrankenPHP globally available
    cp -Rp /frankenphp/dist/frankenphp-* /usr/bin/frankenphp && \
    # Cleanup
    rm -rf /var/cache/apk/* /frankenphp /root/.cache/ /root/go/ && \
    apk del go make g++ libgcc gcc binutils autoconf perl build-base bison freetype-dev gcc libgcc linux-headers nghttp2-libs  musl-utils libc-utils musl-dev libc-dev zlib-dev git

# Configure PHP
COPY config/php.ini /conf.d/php.ini

# Allow ImageMagick 6 to read/write pdf files
COPY config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Caddy config for TYPO3
COPY config/Caddyfile /etc/Caddyfile

WORKDIR /app
CMD ["frankenphp", "run", "--config", "/etc/Caddyfile" ]
