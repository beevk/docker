ARG ANONADDY_VERSION=0.11.0

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6:3.15-2.2.0.3

COPY --from=yasu / /
RUN apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    gnupg \
    gpgme \
    imagemagick \
    libgd \
    mysql-client \
    nginx \
    openssl \
    php8 \
    php8-cli \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-fileinfo \
    php8-fpm \
    php8-gd \
    php8-gmp \
    php8-iconv \
    php8-intl \
    php8-json \
    php8-opcache \
    php8-openssl \
    php8-pdo \
    php8-pdo_mysql \
    php8-pecl-imagick \
    php8-pecl-mailparse \
    php8-phar \
    php8-redis \
    php8-session \
    php8-simplexml \
    php8-sodium \
    php8-tokenizer \
    php8-xml \
    php8-xmlreader \
    php8-xmlwriter \
    php8-zip \
    php8-zlib \
    postfix \
    postfix-mysql \
    rspamd \
    rspamd-controller \
    rspamd-proxy \
    shadow \
    tar \
    tzdata \
  && cp /etc/postfix/master.cf /etc/postfix/master.cf.orig \
  && cp /etc/postfix/main.cf /etc/postfix/main.cf.orig \
  && apk --no-cache add -t build-dependencies \
    autoconf \
    automake \
    build-base \
    gpgme-dev \
    libtool \
    pcre-dev \
    php8-dev \
    php8-pear \
  && ln -s /usr/bin/php8 /usr/bin/php \
  && pecl8 install gnupg \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/www/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  SOCKLOG_TIMESTAMP_FORMAT="" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG ANONADDY_VERSION
WORKDIR /var/www/anonaddy
RUN apk --no-cache add -t build-dependencies \
    git \
    nodejs \
    npm \
  && node --version \
  && npm --version \
  && addgroup -g ${PGID} anonaddy \
  && adduser -D -h /var/www/anonaddy -u ${PUID} -G anonaddy -s /bin/sh -D anonaddy \
  && addgroup anonaddy mail \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
  && git clone --branch v${ANONADDY_VERSION} https://github.com/anonaddy/anonaddy . \
  && composer install --optimize-autoloader --no-dev --no-interaction --no-ansi \
  && npm config set unsafe-perm true \
  && chown -R anonaddy. /var/www/anonaddy \
  && npm install --global cross-env \
  && npm ci --ignore-scripts --only=production \
  && npm run production \
  && npm prune --production \
  && chown -R nobody.nogroup /var/www/anonaddy \
  && apk del build-dependencies \
  && rm -rf /root/.composer \
    /root/.config \
    /root/.npm \
    /var/www/anonaddy/.git \
    /var/www/anonaddy/node_modules \
    /tmp/*

COPY rootfs /

EXPOSE 25 8000 11334
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]
