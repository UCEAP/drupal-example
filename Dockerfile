FROM ghcr.io/uceap/devcontainer-drupal:v2.3.0

# Install SSH server
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y openssh-server \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
    && echo "Port 2222" >> /etc/ssh/sshd_config.d/azure.conf \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config.d/azure.conf \
    && echo 'root:Docker!' | chpasswd
COPY docker-uceap-entrypoint /usr/local/bin/docker-uceap-entrypoint
ENTRYPOINT ["docker-uceap-entrypoint"]

COPY build /var/www/build
COPY config /var/www/config
COPY composer.json /var/www/
COPY web /var/www/web

WORKDIR /var/www

RUN composer install --no-dev --no-interaction --no-progress --optimize-autoloader && \
  sed -i 's-/var/www/html-/var/www/web-' /etc/apache2/sites-available/*.conf && \
  sed -i 's/# Listen\s*80$/Listen 80/' /etc/apache2/ports.conf
