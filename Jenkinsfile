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
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/JARVIS3954P/r_docker_drupal10.git'
            }
        }
        
        stage('Build Image with Podman') {
            steps {
                script {
                    sh """
                    podman build \
                      --build-arg REPO_DIR=. \
                      --build-arg ENV_USR=drupaluser \
                      --build-arg ENV_HOST=${env.SERVER_IP ?: 'localhost'} \
                      -t ${APP_NAME}:${BUILD_TAG} \
                      -t ${APP_NAME}:latest \
                      -f 10/Dockerfile .
                    """
                }
            }
        }
        
        stage('Deploy Containers') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'drupal-db-creds', passwordVariable: 'DB_PASS', usernameVariable: 'DB_USER')]) {
                    sh """
                    # Create pod if it doesn't exist
                    podman pod exists ${POD_NAME} || podman pod create --name ${POD_NAME} -p 80:80

                    # Spin up MariaDB 10.11 container with SELinux flags
                    podman run -d --pod ${POD_NAME} \
                      --name ${DB_CONTAINER} \
                      --replace \
                      -v mariadb_data:/var/lib/mysql:Z,U \
                      -e MYSQL_ROOT_PASSWORD=${DB_PASS} \
                      -e MYSQL_DATABASE=drupal \
                      -e MYSQL_USER=${DB_USER} \
                      -e MYSQL_PASSWORD=${DB_PASS} \
                      docker.io/library/mariadb:10.11

                    # Deploy Drupal 10 container
                    podman run -d --pod ${POD_NAME} \
                      --name ${SITE_CONTAINER} \
                      --replace \
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
                    sleep 12

                    # Run Drush site install if fresh database
                    podman exec -t ${SITE_CONTAINER} /opt/drupal/vendor/bin/drush site:install standard \
                      --db-url="mysql://${DB_USER}:${DB_PASS}@127.0.0.1:3306/drupal" \
                      --site-name="FOSSEE R Drupal 10" \
                      --account-name="admin" \
                      --account-pass="AdminPassword123!" \
                      -y || true

                    # Configure trusted host patterns
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
