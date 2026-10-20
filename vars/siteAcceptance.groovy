def call() {
    sh '''
        set -eu
        if command -v python3 >/dev/null 2>&1; then
            python3 ci/acceptance_tests.py
        else
            python ci/acceptance_tests.py
        fi
    '''
}
