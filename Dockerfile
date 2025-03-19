# check=skip=SecretsUsedInArgOrEnv

FROM ghcr.io/uceap/devcontainer-drupal:v2.3.0
ARG MYSQL_HOST
ARG MYSQL_TCP_PORT
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_DATABASE
ARG REDIS_HOST
ARG REDIS_AUTH
ARG HASH_SALT

COPY build /var/www/build
COPY config /var/www/config
COPY composer.json /var/www/
COPY web /var/www/web

WORKDIR /var/www

RUN composer initialize-container && \
  composer install --no-dev --no-interaction --no-progress --optimize-autoloader && \
  sed -i 's-/var/www/html-/var/www/web-' /etc/apache2/sites-available/*.conf && \
  sed -i 's/# Listen\s*80$/Listen 80/' /etc/apache2/ports.conf
