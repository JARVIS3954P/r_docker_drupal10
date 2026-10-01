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
    }
}
