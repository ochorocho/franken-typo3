FROM alpine:3.17

USER root

RUN apk add --no-cache \
		build-base  \
        alpine-sdk  \
        go \
        git \
        libssl3 \
        bison \
        git \
        imagemagick \
        ghostscript \
        freetype-dev \
		ca-certificates \
		curl \
		tar \
		xz \
		openssl \
		autoconf \
		dpkg-dev \
        dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
        libpq \
        libpq-dev \
		coreutils \
		linux-headers \
        zlib-dev \
        argon2-dev \
		curl-dev \
		gnu-libiconv-dev \
		libsodium-dev \
		libxml2-dev \
		oniguruma-dev \
		openssl-dev \
		readline-dev \
		sqlite-dev \
        libzip-dev  \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        libavif-dev \
        icu-dev  \
        nss-tools \
        musl-locales && \
    rm -rf /var/cache/apk/*

# Build and install PHP
RUN git clone --depth=1 --single-branch --branch=PHP-8.2 https://github.com/php/php-src.git /php-src && \
    cd /php-src/ && \
    ./buildconf && \
    ./configure \
        --enable-embed \
        --enable-zts \
        --disable-zend-signals \
    	--enable-mysqlnd \
        --with-pgsql \
        --with-mysqli \
    	--enable-option-checking=fatal \
    	--with-mhash \
    	--with-pic \
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
        --enable-gd  \
        --with-webp \
        --with-jpeg \
        --with-webp \
        --with-avif \
        --disable-cgi \
        --enable-opcache \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" && \
    make -j$(nproc) && \
    make install && \
    rm -Rf php-src/ && \
    echo "Creating src archive for building extensions\n" && \
    tar -c -f /usr/src/php.tar.xz -J /php-src/ \
    php --version && \
    rm -Rf /php-src/ && \
    mkdir -p /conf.d/

# Add composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Build and install frankenphp
# todo: automate this?
# see https://github.com/docker-library/php/blob/master/8.2-rc/bullseye/zts/Dockerfile#L57-L59 for php values
ENV CGO_LDFLAGS="-lssl -lcrypto -lreadline -largon2 -lcurl -lonig -lz $PHP_LDFLAGS" CGO_CFLAGS=$PHP_CFLAGS CGO_CPPFLAGS=$PHP_CPPFLAGS

RUN git clone --recursive https://github.com/dunglas/frankenphp.git /go/src/app/ && \
    cd /go/src/app/ && go mod graph | awk '{if ($1 !~ "@") print $2}' | xargs go get && cd caddy && go mod graph | awk '{if ($1 !~ "@") print $2}' | xargs go get && \
    cd /go/src/app/caddy/frankenphp && \
    go build && \
    cp frankenphp /usr/local/bin && \
    rm -rf /go/src/app \
      /root/.cache/* \
      /root/go

# Install TYPO3, so it can be used without a configured volume
RUN rm -Rf /app && \
    composer create-project typo3/cms-base-distribution /app && \
    touch /app/public/FIRST_INSTALL && \
    rm -Rf /root/.composer/*

# Configure PHP
COPY config/php.ini /conf.d/php.ini

# Allow ImageMagick 6 to read/write pdf files
COPY config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Caddy config for TYPO3
COPY config/Caddyfile /etc/Caddyfile

# Cleanup packages
RUN apk del  \
        go \
        make \
        g++ \
        libgcc  \
        gcc \
        binutils \
        autoconf \
        perl \
        build-base  \
        alpine-sdk \
        bison \
        freetype-dev \
        gcc \
        ncurses-dev \
        libgcc \
        dpkg \
        dpkg-dev \
        coreutils \
        linux-headers \
        ncurses-libs  \
        ncurses-dev \
        nghttp2-libs  \
        musl-utils \
        libc-utils \
        musl-dev \
        libc-dev \
        openssl-dev \
        libxml2-dev \
        libsodium-dev \
        gnu-libiconv-dev \
        curl-dev \
        zlib-dev \
        git

WORKDIR /app
CMD ["frankenphp", "run", "--config", "/etc/Caddyfile" ]
