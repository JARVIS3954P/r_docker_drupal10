pipeline {
    agent any

    stages {
        stage('SCM Verification') {
            steps {
                sh 'git rev-parse --short HEAD'
                sh 'git branch --show-current || true'
                sh 'test -f composer.json'
                sh 'test -d sites'
                echo 'FOSSEE Drupal repository checkout verified'
            }
        }

        stage('Repository Validation') {
            steps {
                sh '''
                    set -eu

                    test -f composer.json
                    test -f composer.lock
                    test -d sites
                    test -d modules
                    test -d themes
                    test -d libraries

                    echo "Repository structure validation passed"
                '''
            }
        }
    }
}
