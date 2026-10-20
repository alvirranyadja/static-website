def call() {
    archiveArtifacts artifacts: 'dist/*.tar.gz,dist/*.sha256', fingerprint: true
}
