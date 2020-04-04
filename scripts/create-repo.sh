#!/bin/bash

. /repobuilder/scripts/dist.sh
. /repobuilder/scripts/messages.sh

message INFO "repo(${dist})" "Creating repository..."
if ! createrepo --update /repobuilder/output/ >/dev/null 2>/dev/null; then
	message FAIL "repo(${dist})" "Failed to create repository metadata"
	exit 1
fi

message OK "repo(${dist})" "Finished successfully"
