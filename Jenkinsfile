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
                    podman pod rm -f ${POD_NAME} || true
                    podman pod create --name ${POD_NAME} -p 80:80

                    podman run -d --pod ${POD_NAME} \
                      --name ${DB_CONTAINER} \
                      --restart always \
                      -v mariadb_data:/var/lib/mysql:Z,U \
                      -e MYSQL_ROOT_PASSWORD=${DB_PASS} \
                      -e MYSQL_DATABASE=drupal \
                      -e MYSQL_USER=${DB_USER} \
                      -e MYSQL_PASSWORD=${DB_PASS} \
                      docker.io/library/mariadb:10.11

                    podman run -d --pod ${POD_NAME} \
                      --name ${SITE_CONTAINER} \
                      --restart always \
                      -v drupal_files:/opt/drupal/sites/default/files:Z,U \
                      ${APP_NAME}:latest
                    """
                }
            }
        }
        
        stage('Runtime Drupal Setup') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'drupal-db-creds', passwordVariable: 'DB_PASS', usernameVariable: 'DB_USER')]) {
                    sh """
                    echo "Waiting for MariaDB service to accept connections..."
                    until podman exec ${DB_CONTAINER} mariadb-admin ping -h 127.0.0.1 -u ${DB_USER} -p${DB_PASS} --silent; do
                        echo "MariaDB starting up..."
                        sleep 3
                    done

                    # Run Drush installation using explicit TCP driver syntax
                    podman exec -t ${SITE_CONTAINER} /opt/drupal/vendor/bin/drush site:install standard \
                      --db-url="mysql://${DB_USER}:${DB_PASS}@127.0.0.1:3306/drupal" \
                      --site-name="FOSSEE R Drupal 10" \
                      --account-name="admin" \
                      --account-pass="AdminPassword123!" \
                      -y

                    # Set trusted host patterns
                    podman exec -t ${SITE_CONTAINER} /opt/drupal/vendor/bin/drush php:eval \
                      '\$settings["trusted_host_patterns"] = [".*"];'
                    """
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                sh "podman image prune -f"
            }
        }
    }
}
