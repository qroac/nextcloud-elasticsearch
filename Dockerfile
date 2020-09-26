# Copy from
# https://github.com/nextcloud/docker/blob/master/.examples/dockerfiles/full/apache/Dockerfile

#FROM nextcloud:19.0.3-apache
ARG  BASE_VERSION=latest
FROM nextcloud:${BASE_VERSION}

RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        libmagickcore-6.q16-6-extra \
        procps \
        smbclient \
        supervisor \
#       libreoffice \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libbz2-dev \
        libc-client-dev \
        libkrb5-dev \
        libsmbclient-dev \
    ; \
    \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install \
        bz2 \
        imap \
    ; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
;

COPY supervisord.conf /

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]

# Addition for libxml, soap
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libxml2 libxml2-dev samba-client libcurl4 \
        libc-client2007e libc-client2007e-dev libkrb5-3 libkrb5-dev libbz2-dev libsmbclient-dev \
    ; \
    docker-php-ext-install xml soap;

# Addition for indexing app and process
COPY start_indexing.sh /start_indexing.sh
RUN chown www-data:www-data /start_indexing.sh && chmod 550 /start_indexing.sh

