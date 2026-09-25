FROM docker.io/drupal:10.0-apache

ENV DEBIAN_FRONTEND=noninteractive

# Install required utilities
RUN apt update && \
    apt install -y git unzip default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy Drupal repository contents
COPY . /opt/drupal/

# Configure Apache DocumentRoot to /opt/drupal and grant directory access
RUN sed -i 's|/var/www/html|/opt/drupal|g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's|/var/www/|/opt/drupal/|g' /etc/apache2/apache2.conf && \
    echo '<Directory /opt/drupal/>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# Set file ownership for Apache
RUN chown -R www-data:www-data /opt/drupal && \
    chmod -R 755 /opt/drupal

EXPOSE 80

CMD ["apache2-foreground"]
