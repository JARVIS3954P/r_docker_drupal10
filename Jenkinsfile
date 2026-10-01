pipeline {
    agent any

    environment {
        DEPLOY_DIR = '/var/lib/jenkins/.config/containers/systemd'
        DEPLOY_UNIT = 'fossee-drupal-stage4-http.service'
        DEPLOY_FILE = '/var/lib/jenkins/.config/containers/systemd/fossee-drupal-stage4-http.container'
    }

    stages {
        stage('SCM Verification') {
            steps {
                sh '''
                    set -eu

                    git rev-parse --short HEAD
                    git branch --show-current || true

                    test -f composer.json
                    test -f composer.lock
                    test -f Dockerfile
                    test -f .dockerignore
                    test -d sites
                    test -d modules
                    test -d themes
                    test -d libraries

                    echo "FOSSEE Drupal repository checkout verified"
                '''
            }
        }

        stage('Podman Build') {
            steps {
                sh '''
                    set -eu

                    IMAGE="localhost/fossee-drupal:${BUILD_NUMBER}"

                    podman build \
                        --tag "${IMAGE}" \
                        .

                    echo "Built image: ${IMAGE}"

                    podman image inspect \
                        "${IMAGE}" \
                        --format 'ID={{.Id}}'
                '''
            }
        }

        stage('Deploy with Quadlet') {
            steps {
                sh '''
                    set -eu

                    IMAGE="localhost/fossee-drupal:${BUILD_NUMBER}"
                    DEPLOY_FILE="/var/lib/jenkins/.config/containers/systemd/fossee-drupal-stage4-http.container"

                    echo "Deploying image: ${IMAGE}"

                    test -f "${DEPLOY_FILE}"

                    podman image inspect "${IMAGE}" >/dev/null

                    cp "${DEPLOY_FILE}" "${DEPLOY_FILE}.bak"

                    sed -i \
                        -E "s|^Image=localhost/fossee-drupal:.*$|Image=${IMAGE}|" \
                        "${DEPLOY_FILE}"

                    grep -E '^Image=' "${DEPLOY_FILE}"

                    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

                    systemctl --user daemon-reload
                    systemctl --user restart fossee-drupal-stage4-http.service

                    systemctl --user is-active \
                        --quiet fossee-drupal-stage4-http.service

                    echo "Drupal Quadlet deployment is active"
                '''
            }
        }

        stage('Deployment Verification') {
            steps {
                sh '''
                    set -eu

                    IMAGE="localhost/fossee-drupal:${BUILD_NUMBER}"

                    echo "===== Service ====="
                    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

                    systemctl --user status \
                        fossee-drupal-stage4-http.service \
                        --no-pager \
                        -l

                    echo
                    echo "===== Container ====="

                    podman inspect fossee-drupal-stage4-http \
                        --format 'Image={{.ImageName}}'

                    echo
                    echo "===== Expected image ====="
                    echo "${IMAGE}"

                    ACTUAL_IMAGE="$(
                        podman inspect fossee-drupal-stage4-http \
                            --format '{{.ImageName}}'
                    )"

                    test "${ACTUAL_IMAGE}" = "${IMAGE}"

                    echo
                    echo "Drupal container is running the expected build image."
                '''
            }
        }
    }
        post {
        always {
            sh '''
                set -eux
    
                echo "===== POST-BUILD CONTAINER CLEANUP ====="
    
                echo "--- Containers before prune ---"
                podman ps -a --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}"
    
                echo "--- Dangling images before prune ---"
                podman images --filter dangling=true
    
                echo "--- Removing stopped containers ---"
                podman container prune -f
    
                echo "--- Removing dangling images ---"
                podman image prune -f
    
                echo "--- Containers after prune ---"
                podman ps -a --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}"
    
                echo "--- Dangling images after prune ---"
                podman images --filter dangling=true
    
                echo "===== POST-BUILD CLEANUP COMPLETE ====="
            '''
        }
    }
}
