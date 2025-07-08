FROM ubuntu:22.04

LABEL maintainer="TouryPass Team"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create non-root user
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    locales \
    curl \
    tzdata \
    libnotify-bin \
    fonts-noto-color-emoji \
    cron \
    vim \
    sudo \
    build-essential \
    unzip \
    unixodbc-dev \
    gnupg \
    git \
    openssl \
    nginx \
    supervisor \
    && locale-gen en_US.UTF-8 \
    && add-apt-repository ppa:ondrej/php

# Verify nginx installation
RUN nginx -v && ls -la /usr/sbin/nginx

# Install PHP 8.2 and extensions
RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-pgsql \
    php8.2-gd \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-soap \
    php8.2-tokenizer \
    php8.2-xsl \
    php8.2-imagick \
    && apt-get clean

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable \
    && corepack prepare yarn@1.22.22 --activate

# Create developer user
RUN addgroup --gid ${USER_GID} ${USERNAME} \
    && adduser --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash --disabled-password --gecos "" ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Prepare required directories and permissions
RUN mkdir -p \
        /app/code/api/storage/logs \
        /app/code/api/bootstrap/cache \
        /var/log/supervisor \
        /var/log/nginx \
        /var/lib/nginx/body \
        /run/php \
    && touch /var/log/nginx/access.log /var/log/nginx/error.log \
    && chown -R ${USERNAME}:${USERNAME} /var/log/supervisor /var/log/nginx /var/lib/nginx /run/php \
    && chmod -R 775 /var/log/supervisor /var/log/nginx /var/lib/nginx /run/php \
    && chown -R www-data:www-data /app/code/api/storage /app/code/api/bootstrap/cache \
    && chmod -R 775 /app/code/api/storage /app/code/api/bootstrap/cache

# Configure nginx
RUN rm -f /etc/nginx/sites-enabled/default
COPY docker/app/config/dev/default.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Configure PHP-FPM
COPY docker/app/config/dev/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY docker/app/config/dev/php.ini /etc/php/8.2/fpm/php.ini

# Configure supervisor
COPY docker/app/config/dev/supervisord.conf /etc/supervisor/supervisord.conf

# Copy startup and init scripts
COPY docker/app/start-services.sh /usr/local/bin/start-services.sh
COPY docker/app/init-container.sh /usr/local/bin/init-container.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/start-services.sh /usr/local/bin/init-container.sh

RUN mkdir -p /home/developer/supervisor && \
    chown -R ${USERNAME}:${USERNAME} /home/developer/supervisor

COPY docker/app/config/dev/nginx.conf /etc/nginx/nginx.conf
COPY docker/app/config/dev/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf

# Use non-root user from here onward
USER ${USERNAME}
WORKDIR /app/code/api

ENTRYPOINT ["/usr/local/bin/init-container.sh"]
CMD ["/usr/local/bin/start-services.sh"]
