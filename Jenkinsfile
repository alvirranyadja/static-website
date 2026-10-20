// Bibliothèque partagée chargée depuis ce dépôt (vars/ et src/).
// Jenkins : 16.192.73.184
// Déploiement : 16.192.253.80
//
// Job Pipeline from SCM, Script Path = Jenkinsfile.
// Plugins : Git, Pipeline, SSH Agent.
// Credential SSH Username with private key, id deploy-ssh-key, utilisateur deploy.

library identifier: 'static-website-pipeline@master', retriever: legacySCM(scm)

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '10'))
    }

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: '16.192.253.80', description: 'Machine de déploiement')
        string(name: 'DEPLOY_USER', defaultValue: 'deploy', description: 'Utilisateur SSH')
        string(name: 'DEPLOY_PATH', defaultValue: '/var/www/static-website', description: 'Répertoire des releases')
        string(name: 'SITE_URL', defaultValue: 'http://16.192.253.80', description: 'URL du test de fonctionnement')
        string(name: 'SSH_CREDENTIALS_ID', defaultValue: 'deploy-ssh-key', description: 'Credential Jenkins de la clé SSH')
        booleanParam(name: 'DEPLOY_ENABLED', defaultValue: true, description: 'Publier sur la machine de déploiement')
    }

    environment {
        JENKINS_HOST = '16.192.73.184'
        DEPLOY_HOST = "${params.DEPLOY_HOST}"
        DEPLOY_USER = "${params.DEPLOY_USER}"
        DEPLOY_PATH = "${params.DEPLOY_PATH}"
        SITE_URL = "${params.SITE_URL}"
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                siteBuild()
            }
        }

        stage('Acceptance') {
            steps {
                siteAcceptance()
            }
        }

        stage('Security') {
            steps {
                siteSecurity()
            }
        }

        stage('Package') {
            steps {
                sitePackage()
            }
        }

        stage('Archive') {
            steps {
                siteArchive()
            }
        }

        stage('Deploy') {
            steps {
                siteDeploy()
            }
        }

        stage('Functional test') {
            steps {
                siteFunctionalTest()
            }
        }
    }

    post {
        success {
            echo 'Pipeline terminé.'
        }
        failure {
            echo 'Pipeline en échec. Un test de fonctionnement raté restaure la release précédente.'
        }
    }
}
