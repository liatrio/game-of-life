pipeline {
    agent none
    stages {
       stage('Build') {
           agent {
               docker {
                   image 'maven:3.5.0'
                   args '-e INITIAL_ADMIN_USER -e INITIAL_ADMIN_PASSWORD --network=${LDOP_NETWORK_NAME}'
               }
           }
           steps {
               configFileProvider(
                       [configFile(fileId: 'nexus', variable: 'MAVEN_SETTINGS')]) {
                   sh 'mvn -s $MAVEN_SETTINGS clean deploy -DskipTests=true -B'
               }
           }
       }
       stage('Sonar') {
           agent  {
               docker {
                   image 'sebp/sonar-runner'
                   args '-e SONAR_ACCOUNT_LOGIN -e SONAR_ACCOUNT_PASSWORD -e SONAR_DB_URL -e SONAR_DB_LOGIN -e SONAR_DB_PASSWORD --network=${LDOP_NETWORK_NAME}'
               }
           }
           steps {
               sh '/opt/sonar-runner-2.4/bin/sonar-runner -e -D sonar.login=${SONAR_ACCOUNT_LOGIN} -D sonar.password=${SONAR_ACCOUNT_PASSWORD} -D sonar.jdbc.url=${SONAR_DB_URL} -D sonar.jdbc.username=${SONAR_DB_LOGIN} -D sonar.jdbc.password=${SONAR_DB_PASSWORD}'
           }
       }
       stage('Build container') {
           agent any
           steps {
               script {
                   sh "docker build -t gameoflife-tomcat:${env.BRANCH_NAME} ."
                       if ( env.BRANCH_NAME == 'master' ) {
                           pom = readMavenPom file: 'pom.xml'
                           containerVersion = pom.version
                           /*Need to check if version exists in the future*/
                           /*failIfVersionExists("liatrio","petclinic-tomcat",containerVersion)*/
                           sh "docker build -t gameoflife-tomcat:${containerVersion} ."
                       }
               }
           }
       }
       stage('Build container') {
             agent any
             steps {
                 sh 'docker build -t gameoflife-tomcat .'
             }
         }
         stage('Run local container') {
             agent any
             steps {
                 sh 'docker rm -f gameoflife-tomcat-temp || true'
                 sh 'docker run -p 18891:8080 -d --network=${LDOP_NETWORK_NAME} --name gameoflife-tomcat-temp gameoflife-tomcat'
             }
         }
         stage('Stop local container') {
           agent any
           steps {
             sh 'docker rm -f gameoflife-tomcat-temp || true'
           }
         }
         stage('Push to dockerhub') {
             agent any
             steps {
                 withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'dockerPassword', usernameVariable: 'dockerUsername')]){
                     script {
                         sh "docker login -u ${env.dockerUsername} -p ${env.dockerPassword}"
                         if ( env.BRANCH_NAME == 'master' ) {
                             sh "docker push gameoflife-tomcat:${containerVersion}"
                         }
                         else {
                             sh "docker push gameoflife-tomcat:${env.BRANCH_NAME}"
                         }
                     }
                 }
             }
         }
         stage('Deploy to dev') {
             agent any
             steps {
                 sh 'docker rm -f dev-gameoflife || true'
                 sh 'docker run -p 18892:8080 -d --network=${LDOP_NETWORK_NAME} --name dev-gameoflife gameoflife-tomcat'
             }
         }
         stage('Smoke test dev') {
             agent { label 'master' }
             steps {
                 sh "sleep 5s"
                 sh "curl http://dev-gameoflife:8080"
                 echo "Should be accessible at http://localhost:18892/gameoflife"
             }
         }
         stage('Deploy to QA') {
             agent any
             steps {
                 sh 'docker rm -f qa-gameoflife || true'
                 sh 'docker run -p 18893:8080 -d --network=${LDOP_NETWORK_NAME} --name qa-gameoflife gameoflife-tomcat'
             }
         }
         stage('Smoke test qa') {
             agent { label 'master' }
             steps {
                 sh "sleep 5s"
                 sh "curl http://qa-gameoflife:8080/gameoflife"
                 echo "Should be accessible at http://localhost:18893/gameoflife"
            }
         }
         stage('Deploy to prod') {
             agent any
             steps {
                 sh 'docker rm -f prod-gameoflife || true'
                 sh 'docker run -p 18894:8080 -d --network=${LDOP_NETWORK_NAME} --name prod-gameoflife gameoflife-tomcat'
             }
         }
         stage('Smoke Test prod') {
             agent { label 'master' }
             steps {
                 sh "sleep 5"
                 sh "curl http://prod-gameoflife:8080/gameoflife"
                 echo "Should be accessible at http://localhost:1884/gameoflife"

             }
          }
    }
}
