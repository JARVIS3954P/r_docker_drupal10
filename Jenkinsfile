pipeline {
    agent any

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
    }
}
