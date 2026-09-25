FROM docker.io/drupal:10.0-apache

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y git unzip && \
    unlink /var/www/html

# Copy repository files directly into /opt/drupal
COPY . /opt/drupal/

# Update Apache DocumentRoot to point directly to /opt/drupal
RUN sed -i 's|/var/www/html|/opt/drupal|g' /etc/apache2/sites-available/000-default.conf && \
    ln -s /opt/drupal /var/www/html && \
    cd /opt/drupal && \
    composer install --no-cache --no-dev --no-interaction --no-progress

EXPOSE 80
