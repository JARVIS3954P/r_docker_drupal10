FROM docker.io/drupal:10.0-apache

ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt update && \
    apt install -y git unzip default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy repository code to /opt/drupal
COPY . /opt/drupal/

# Re-point Apache's DocumentRoot symlink from /opt/drupal/web to /opt/drupal
RUN rm -rf /var/www/html && \
    ln -s /opt/drupal /var/www/html

# Grant Apache (<Directory /var/www/html>) permission to follow symlinks and access files
RUN echo '<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# Set permissions for www-data
RUN chown -R www-data:www-data /opt/drupal && \
    chmod -R 755 /opt/drupal

EXPOSE 80

CMD ["apache2-foreground"]
