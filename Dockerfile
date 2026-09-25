FROM apache2-drupal-base:latest

# 1. Enable Apache mod_rewrite for Drupal clean URLs
RUN a2enmod rewrite

# 2. Update Apache DocumentRoot to point directly to /opt/drupal/web
RUN sed -i 's|/var/www/html|/opt/drupal/web|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|/var/www/html|/opt/drupal/web|g' /etc/apache2/apache2.conf

# 3. Configure Directory block to allow .htaccess overrides and symlinks
RUN echo '<Directory /opt/drupal/web>' >> /etc/apache2/apache2.conf && \
    echo '    Options Indexes FollowSymLinks' >> /etc/apache2/apache2.conf && \
    echo '    AllowOverride All' >> /etc/apache2/apache2.conf && \
    echo '    Require all granted' >> /etc/apache2/apache2.conf && \
    echo '</Directory>' >> /etc/apache2/apache2.conf

# 4. Ensure site files and web root are owned by www-data
WORKDIR /opt/drupal
RUN chown -R www-data:www-data /opt/drupal

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]
