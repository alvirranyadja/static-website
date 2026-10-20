import org.staticsite.DeployPolicy

def call() {
    if (!DeployPolicy.enabled(this)) {
        echo 'Déploiement ignoré : réservé à master/main, ou DEPLOY_ENABLED est décoché.'
        return
    }
    sshagent(credentials: [credentialId()]) {
        sh 'bash ci/publish.sh'
    }
}

String credentialId() {
    def credId = params.SSH_CREDENTIALS_ID
    if (credId == null || credId.trim().isEmpty()) {
        return 'deploy-ssh-key'
    }
    return credId.trim()
}
