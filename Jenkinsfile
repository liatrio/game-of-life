#!/bin/env groovy
pipeline {
  agent none
  environment {
    IMAGE = "liatrio/game-of-life-tomcat"
  }
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
    stage('Get Artifact') {
      agent {
        docker {
          image 'maven:3.5.0'
          args '-e INITIAL_ADMIN_USER -e INITIAL_ADMIN_PASSWORD --network=${LDOP_NETWORK_NAME}'
        }
      }
      steps {
        sh 'mvn clean'
        script {
          pom = readMavenPom file: 'pom.xml'
          getArtifact(pom.groupId, pom.artifactId + "-web", pom.version, "gameoflife")
        }
      }
    }
    stage('Build container') {
      agent any
      steps {
        script {
          sh "docker build -t liatrio/game-of-life-tomcat:${env.BRANCH_NAME} ."
          if ( env.BRANCH_NAME == 'master' ) {
            pom = readMavenPom file: 'pom.xml'
            containerVersion = pom.version
            sh "docker build -t liatrio/game-of-life-tomcat:${containerVersion} ."
          }
        }
      }
    }
    stage('Run local container') {
      agent any
      steps {
        sh 'docker rm -f game-of-life-tomcat-temp || true'
        sh "docker run -d -p 9080:8080 --network=${LDOP_NETWORK_NAME} --name game-of-life-tomcat-temp liatrio/game-of-life-tomcat:${env.BRANCH_NAME}"
      }
    }
    stage('Smoke test local') {
			agent { label 'master' }
			steps {
				sh "sleep 5s"
				sh "curl http://localhost:9080"
				echo "Should be accessible at http://localhost:9080/gameoflife"
			}
		}
    stage('Stop local container') {
      agent any
      steps {
        sh 'docker rm -f game-of-life-tomcat-temp || true'
      }
    }
    stage('Push to dockerhub') {
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'dockerPassword', usernameVariable: 'dockerUsername')]) {
          script {
            sh "docker login -u ${env.dockerUsername} -p ${env.dockerPassword}"
            if ( env.BRANCH_NAME == 'master' ) {
              sh "docker push liatrio/game-of-life-tomcat:${containerVersion}"
            }
            else {
              sh "docker push liatrio/game-of-life-tomcat:${env.BRANCH_NAME}"
            }
          }
        }
      }
    }
    stage('Deploy to dev') {
      agent any
      steps {
        script {
          if ( env.BRANCH_NAME == 'master' ) {
            deployToEnvironment("ec2-user", "dev.gameoflife.liatr.io", "petclinic-deploy-key", "${env.IMAGE}", "${containerVersion}", "game-of-life", "dev.gameoflife.liatr.io")
          }
          else {
            deployToEnvironment("ec2-user", "dev.gameoflife.liatr.io", "petclinic-deploy-key", "${env.IMAGE}", "${env.BRANCH_NAME}", "game-of-life", "dev.gameoflife.liatr.io")
          }
        }
      }
    }
    stage('Smoke test dev') {
      agent { label 'master' }
      steps {
        sh "sleep 5s"
        sh "curl -k https://dev.gameoflife.liatr.io/gameoflife"
        echo "Should be accessible at https://dev.gameoflife.liatr.io/gameoflife"
      }
    }
    stage('Deploy to qa') {
      when {
        branch 'master'
      }
      agent any
      steps {
        deployToEnvironment("ec2-user", "qa.gameoflife.liatr.io", "petclinic-deploy-key", "${env.IMAGE}", "${containerVersion}", "game-of-life", "qa.gameoflife.liatr.io")
      }
    }
    stage('Smoke test qa') {
      when {
        branch 'master'
      }
      agent { label 'master' }
      steps {
        sh "sleep 5s"
        sh "curl -k https://qa.gameoflife.liatr.io/gameoflife"
        echo "Should be accessible at https://qa.gameoflife.liatr.io/gameoflife"
      }
    }
  }
}
