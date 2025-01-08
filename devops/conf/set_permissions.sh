#!/bin/bash

set -x

display_name=$1
descriptor=$2
allow_deny=$3
shift 3

log "$allow_deny permissions for $display_name: $*"

# az devops security permission namespace show --output table \
#     --namespace-id "$security_namespace_git_repositories"
security_namespace_git_repositories=2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87
# shellcheck disable=SC2034
{
    Administer=1                  # Administer
    GenericRead=2                 # Read
    GenericContribute=4           # Contribute
    ForcePush=8                   # Force push (rewrite history, delete branches and tags)
    CreateBranch=16               # Create branch
    CreateTag=32                  # Create tag
    ManageNote=64                 # Manage notes
    PolicyExempt=128              # Bypass policies when pushing
    CreateRepository=256          # Create repository
    DeleteRepository=512          # Delete or disable repository
    RenameRepository=1024         # Rename repository
    EditPolicies=2048             # Edit policies
    RemoveOthersLocks=4096        # Remove others' locks
    ManagePermissions=8192        # Manage permissions
    PullRequestContribute=16384   # Contribute to pull requests
    PullRequestBypassPolicy=32768 # Bypass policies when completing pull requests
    ViewAdvSecAlerts=65536        # Advanced Security: view alerts
    DismissAdvSecAlerts=131072    # Advanced Security: manage and dismiss alerts
    ManageAdvSecScanning=262144   # Advanced Security: manage settings
}

bit=0
for permission in "$@"; do
    value=${!permission}
    [ -z "$value" ] && return 1
    bit=$((bit | value))
done

access_control_entries=$(/devops/rest.sh POST \
    "AccessControlEntries/$security_namespace_git_repositories" '' \
    "{
        \"token\": \"repoV2/$SYSTEM_TEAMPROJECTID/\",
        \"merge\": true,
        \"accessControlEntries\": [
                {
                    \"descriptor\": \"$descriptor\",
                    \"$allow_deny\": $bit
                }
            ]
    }") &&
    count=$(node --print "($access_control_entries).count") &&
    [ "$count" -eq 1 ]
