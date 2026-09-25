FROM docker.io/drupal:10.0-apache

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y git unzip default-mysql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy codebase
COPY . /opt/drupal/

# Enable mod_rewrite for Drupal
RUN a2enmod rewrite

# Remove existing web symlink/dir and link /var/www/html directly to /opt/drupal
RUN rm -rf /var/www/html && \
    ln -s /opt/drupal /var/www/html

# Update Apache site configuration
RUN sed -i 's|/var/www/html|/opt/drupal|g' /etc/apache2/sites-available/000-default.conf

# Allow htaccess overrides and symlinks
RUN echo '<Directory /opt/drupal>' >> /etc/apache2/apache2.conf && \
    echo '    Options Indexes FollowSymLinks' >> /etc/apache2/apache2.conf && \
    echo '    AllowOverride All' >> /etc/apache2/apache2.conf && \
    echo '    Require all granted' >> /etc/apache2/apache2.conf && \
    echo '</Directory>' >> /etc/apache2/apache2.conf

# Set permissions
RUN chown -R www-data:www-data /opt/drupal

EXPOSE 80

CMD ["apache2-foreground"]
