FROM dunglas/frankenphp:latest

USER root

RUN apt update && \
    apt install -y gnupg ca-certificates lsb-release bash-completion cron imagemagick golang-go ghostscript libfreetype6-dev \
                    libzip-dev libssl-dev libonig-dev libxml2-dev libpng-dev libjpeg-dev libwebp-dev libavif-dev

# Build and install PHP
RUN git clone --depth=1 --single-branch --branch=PHP-8.2 https://github.com/php/php-src.git /php-src

WORKDIR /php-src/

RUN ./buildconf
RUN ./configure \
        --enable-embed \
        --enable-zts \
        --disable-zend-signals \
    	--enable-mysqlnd \
    	--enable-option-checking=fatal \
    	--with-mhash \
    	--with-pic \
        --enable-ftp \
    	--enable-mbstring \
        --enable-intl \
    	--with-password-argon2 \
    	--with-sodium=shared \
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		--with-curl \
		--with-iconv \
		--with-openssl \
		--with-readline \
		--disable-phpdbg \
        --with-pdo-mysql \
        --with-zip \
        --with-zlib \
        --with-freetype \
        --enable-gd --with-webp --with-jpeg --with-webp --with-avif \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" && \
    make -j$(nproc) && \
    make install && \
    rm -Rf php-src/ && \
    echo "Creating src archive for building extensions\n" && \
    tar -c -f /usr/src/php.tar.xz -J /php-src/ && \
    ldconfig && \
    php --version

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Allow ImageMagick 6 to read/write pdf files
COPY config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Get this wannabe zombie walking
RUN git clone --recursive https://github.com/dunglas/frankenphp.git /go/src/app/

WORKDIR /go/src/app/

# todo: automate this?
# see https://github.com/docker-library/php/blob/master/8.2-rc/bullseye/zts/Dockerfile#L57-L59 for php values
ENV CGO_LDFLAGS="-lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS" CGO_CFLAGS=$PHP_CFLAGS CGO_CPPFLAGS=$PHP_CPPFLAGS

RUN cd caddy/frankenphp && \
    go build && \
    cp frankenphp /usr/local/bin && \
    cp /go/src/app/caddy/frankenphp/Caddyfile /etc/Caddyfile

WORKDIR /app

RUN mkdir -p /app/public
RUN echo '<?php echo "The Walking Bread!"; phpinfo();' > /app/public/index.php

COPY config/docker-php-entrypoint.sh /usr/local/bin/docker-php-entrypoint
CMD ["frankenphp", "run", "--config", "/etc/Caddyfile" ]
