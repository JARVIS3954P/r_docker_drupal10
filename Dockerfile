FROM docker.io/drupal:10.0-apache

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y git unzip default-mysql-client && \
    unlink /var/www/html

COPY . /opt/drupal/

RUN sed -i 's|/var/www/html|/opt/drupal|g' /etc/apache2/sites-available/000-default.conf && \
    ln -s /opt/drupal /var/www/html && \
    cd /opt/drupal && \
    composer install --no-cache --no-dev --no-interaction --no-progress && \
    chown -R www-data:www-data /opt/drupal/sites /opt/drupal/modules /opt/drupal/themes

EXPOSE 80

CMD ["apache2-foreground"]
