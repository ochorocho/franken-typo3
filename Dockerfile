FROM php:8.2.0RC4-zts-bullseye

USER root

RUN apt update && \
    apt install -y git gnupg ca-certificates lsb-release bash-completion cron imagemagick golang-go ghostscript libfreetype6-dev \
                    libzip-dev libssl-dev libonig-dev libxml2-dev libpng-dev libjpeg-dev libwebp-dev libavif-dev

# Build and install PHP
RUN git clone --depth=1 --single-branch --branch=PHP-8.2 https://github.com/php/php-src.git /php-src

WORKDIR /php-src/

RUN ./buildconf && \
    ./configure \
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
    ldconfig

# Add composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Allow ImageMagick 6 to read/write pdf files
COPY config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Build and install frankenphp
RUN git clone --recursive https://github.com/dunglas/frankenphp.git /go/src/app/

WORKDIR /go/src/app/

# todo: automate this?
# see https://github.com/docker-library/php/blob/master/8.2-rc/bullseye/zts/Dockerfile#L57-L59 for php values
ENV CGO_LDFLAGS="-lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS" CGO_CFLAGS=$PHP_CFLAGS CGO_CPPFLAGS=$PHP_CPPFLAGS

RUN cd caddy/frankenphp && \
    go build && \
    cp frankenphp /usr/local/bin && \
    cp /go/src/app/caddy/frankenphp/Caddyfile /etc/Caddyfile


RUN rm -Rf /app && \
    composer create-project typo3/cms-base-distribution /app && \
    touch /app/public/FIRST_INSTALL

# Configure PHP
RUN mkdir -p /conf.d/
COPY config/php.ini /conf.d/php.ini

WORKDIR /app
CMD ["frankenphp", "run", "--config", "/etc/Caddyfile" ]
