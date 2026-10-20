def call() {
    sh '''
        set -eu
        if command -v python3 >/dev/null 2>&1; then
            python3 ci/security_scan.py
        else
            python ci/security_scan.py
        fi
    '''
}
