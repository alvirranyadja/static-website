def call() {
    def version = libraryResource('org/staticsite/version.txt').trim()
    withEnv(["LIBRARY_VERSION=${version}"]) {
        sh 'bash ci/build.sh'
    }
}
