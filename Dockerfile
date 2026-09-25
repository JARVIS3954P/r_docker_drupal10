FROM docker.io/drupal:10.0-apache

# Accept the required build arguments
ARG REPO_DIR="."
ARG ENV_USR="jenkins"
ARG ENV_HOST="127.0.0.1"

ENV DEBIAN_FRONTEND=noninteractive \
    ENV_USR=${ENV_USR} \
    ENV_HOST=${ENV_HOST}

# Install dependencies including Composer and MySQL client
RUN apt-get update && \
    apt-get install -y git unzip default-mysql-client curl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    rm -rf /var/lib/apt/lists/*

# Copy codebase
COPY ${REPO_DIR} /opt/drupal/

WORKDIR /opt/drupal

# Install PHP dependencies and Drush via Composer inside the image build
RUN composer install --no-dev --no-interaction --no-progress

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
