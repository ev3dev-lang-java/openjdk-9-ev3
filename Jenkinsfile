pipeline {
    agent {
        label '( linux || sw.os.linux ) && ( x64 || x86_64 || x86 || hw.arch.x86 ) && ( docker || sw.tool.docker ) && !test'
    }
    stages {
        stage('checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build cross-compilation OS') {
            steps {
                sh "docker build -t ev3dev-lang-java:jdk-stretch -f system/Dockerfile system "
            }
        }
        stage("Build cross-compilation environment") {
            steps {
                sh "docker build -t ev3dev-lang-java:jdk-build -f scripts/Dockerfile scripts "
            }
        }
        stage("Build") {
            steps {
                sh "rm -rf    /home/jenkins/workspace/openjdk-10-ev3-pipeline/build"
                sh "mkdir -p  /home/jenkins/workspace/openjdk-10-ev3-pipeline/build"
                sh "chmod 777 /home/jenkins/workspace/openjdk-10-ev3-pipeline/build"
                sh "docker run --rm -v /home/jenkins/workspace/openjdk-10-ev3-pipeline/build:/build -e JDKVER='10' -e JDKVM='client' -e AUTOBUILD='1' ev3dev-lang-java:jdk-build"
            }
        }
    }
}
