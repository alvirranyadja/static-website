package org.staticsite

class DeployPolicy implements Serializable {
    static boolean enabled(script) {
        if (script.params.DEPLOY_ENABLED == false) {
            return false
        }
        def branch = script.env.BRANCH_NAME
        if (branch == null || branch.trim().isEmpty()) {
            return true
        }
        return branch == 'master' || branch == 'main'
    }
}
