import org.staticsite.DeployPolicy

def call() {
    if (!DeployPolicy.enabled(this)) {
        echo 'Test de fonctionnement ignoré : pas de déploiement pour cette branche.'
        return
    }
    def status = sh(script: 'bash ci/functional_test.sh', returnStatus: true)
    if (status == 0) {
        echo 'Test de fonctionnement réussi.'
        return
    }
    echo 'Test de fonctionnement en échec. Restauration de la release précédente.'
    sshagent(credentials: [credentialId()]) {
        def rolled = sh(script: 'bash ci/rollback.sh', returnStatus: true)
        if (rolled != 0) {
            error("Test de fonctionnement en échec, et le retour arrière a échoué (code ${rolled}).")
        }
    }
    error("Test de fonctionnement en échec (code ${status}). Release précédente restaurée.")
}

String credentialId() {
    def credId = params.SSH_CREDENTIALS_ID
    if (credId == null || credId.trim().isEmpty()) {
        return 'deploy-ssh-key'
    }
    return credId.trim()
}
