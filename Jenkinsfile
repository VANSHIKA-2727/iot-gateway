pipeline {
    agent any
    options { skipDefaultCheckout(true) }
    stages {
        stage('Git Pull') {
            steps {
                echo 'Checking out the configured SCM revision'
                checkout scm
            }
        }
        stage('IoT Verification') {
            steps {
                sh '''
                    set -eu
                    test -f mqtt.conf || { echo 'ERROR: mqtt.conf is missing'; exit 1; }
                    grep -qx 'PORT=1883' mqtt.conf || { echo 'ERROR: mqtt.conf must contain PORT=1883'; exit 1; }
                    echo 'IoT configuration verified'
                '''
            }
        }
        stage('Image Packaging') {
            steps {
                sh '''
                    set -eu
                    command -v docker >/dev/null || { echo 'ERROR: Install Docker CLI on this Jenkins agent'; exit 1; }
                    docker info >/dev/null 2>&1 || { echo 'ERROR: Docker daemon is unavailable to this Jenkins agent'; exit 1; }
                    docker build -t iot-hub:latest .
                '''
            }
        }
    }
    post {
        success { echo 'IoT verification and image packaging completed' }
        failure { echo 'Pipeline failed; inspect the failing stage above' }
    }
}
