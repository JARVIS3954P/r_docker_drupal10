FROM docker.io/drupal:10.6-apache

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/www/html \
    && mkdir -p /opt/drupal

COPY . /opt/drupal/

RUN ln -s /opt/drupal /var/www/html \
    && cd /opt/drupal \
    && composer install \
         --no-dev \
         --no-interaction \
         --no-progress \
         --prefer-dist

EXPOSE 80
