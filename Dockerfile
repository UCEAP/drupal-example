FROM ghcr.io/uceap/devcontainer-drupal:v2.3.0

COPY web /var/www/web
COPY config /var/www/config
COPY composer.json /var/www/composer.json

WORKDIR /var/www

RUN composer install --no-dev --no-interaction --no-progress --optimize-autoloader

RUN echo 'DocumentRoot /var/www/web' >> /etc/apache2/apache2.conf
