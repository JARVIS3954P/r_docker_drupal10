pipeline {
    agent any
    
    environment {
        APP_NAME = 'drupal10-fossee'
        BUILD_TAG = "build-${BUILD_NUMBER}"
        DB_CONTAINER = 'drupal-mariadb'
        SITE_CONTAINER = 'drupal-site'
        POD_NAME = 'drupal-pod'
    }
    
    stages {
        stage('Build Image with Podman') {
            steps {
                script {
                    sh """
                    podman build \
                      --build-arg REPO_DIR=. \
                      --build-arg ENV_USR=jenkins \
                      --build-arg ENV_HOST=64.227.171.68 \
                      -t ${APP_NAME}:${BUILD_TAG} \
                      -t ${APP_NAME}:latest \
                      -f Dockerfile .
                    """
                }
            }
        }
        
        stage('Deploy Containers') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'drupal-db-creds', passwordVariable: 'DB_PASS', usernameVariable: 'DB_USER')]) {
                    sh """
                    # Prevent Jenkins ProcessTreeKiller from killing Podman after pipeline completion
                    export JENKINS_NODE_COOKIE=dontKillMe
                    export BUILD_ID=dontKillMe

                    # Ensure lingering is active for user jenkins
                    loginctl enable-linger jenkins || true

                    # Reset old pod
                    podman pod rm -f ${POD_NAME} || true
                    
                    # Create pod binding port 80
                    podman pod create --name ${POD_NAME} -p 80:80

                    # Start DB Container
                    podman run -d --pod ${POD_NAME} \
                      --name ${DB_CONTAINER} \
                      --restart always \
                      -v mariadb_data:/var/lib/mysql:Z,U \
                      -e MYSQL_ROOT_PASSWORD=${DB_PASS} \
                      -e MYSQL_DATABASE=drupal \
                      -e MYSQL_USER=${DB_USER} \
                      -e MYSQL_PASSWORD=${DB_PASS} \
                      docker.io/library/mariadb:10.11

                    # Start Drupal Container
                    podman run -d --pod ${POD_NAME} \
                      --name ${SITE_CONTAINER} \
                      --restart always \
                      -v drupal_files:/opt/drupal/sites/default/files:Z,U \
                      -e ENV_HOST=127.0.0.1 \
                      -e ENV_DB=drupal \
                      -e ENV_USR=${DB_USER} \
                      -e ENV_PSWD=${DB_PASS} \
                      ${APP_NAME}:latest
                    """
                }
            }
        }
        
 stage('Runtime Drupal Setup') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'drupal-db-creds', passwordVariable: 'DB_PASS', usernameVariable: 'DB_USER'),
                    string(credentialsId: 'drupal-admin-pass', variable: 'ADMIN_PASS')
                ]) {
                    sh """
                    echo "Waiting for MariaDB service..."
                    until podman exec ${DB_CONTAINER} mariadb-admin ping -h 127.0.0.1 -u ${DB_USER} -p${DB_PASS} --silent; do
                        sleep 3
                    done

                    # Configure Apache DocumentRoot, Symlinks, and ServerName
                    podman exec -t ${SITE_CONTAINER} bash -c "
                        rm -rf /var/www/html && \
                        ln -s /opt/drupal /var/www/html && \
                        grep -q 'ServerName localhost' /etc/apache2/apache2.conf || echo 'ServerName localhost' >> /etc/apache2/apache2.conf && \
                        chown -R www-data:www-data /opt/drupal && \
                        chmod -R 755 /opt/drupal && \
                        apache2ctl graceful
                    "

                    # Execute Drush site installation using secure credential variable
                    podman exec -t ${SITE_CONTAINER} /opt/drupal/vendor/bin/drush site:install standard \
                      --site-name="FOSSEE R Drupal 10" \
                      --account-name="admin" \
                      --account-pass="${ADMIN_PASS}" \
                      -y

                    # Append trusted host patterns to settings.php
                    podman exec -i ${SITE_CONTAINER} bash -c "cat >> /opt/drupal/sites/default/settings.php" << 'EOF'
\$settings['trusted_host_patterns'] = ['.*'];
EOF

                    # Clear Drupal cache
                    podman exec -t ${SITE_CONTAINER} /opt/drupal/vendor/bin/drush cr
                    """
                }
            }
        } 
        stage('Cleanup') {
            steps {
                // Prune dangling build images without touching active containers
                sh "podman image prune -f"
            }
        }
    }
}
