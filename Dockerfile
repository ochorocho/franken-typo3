FROM alpine:3.19

USER root

COPY frankenphp-typo3-build.sh /frankenphp-typo3-build.sh
RUN ash /frankenphp-typo3-build.sh

# Configure PHP
COPY config/php.ini /conf.d/php.ini

# Allow ImageMagick 6 to read/write pdf files
COPY config/imagemagick-policy.xml /etc/ImageMagick-6/policy.xml

# Caddy config for TYPO3
COPY config/Caddyfile /etc/Caddyfile

WORKDIR /app
CMD ["frankenphp", "run", "--config", "/etc/Caddyfile" ]
