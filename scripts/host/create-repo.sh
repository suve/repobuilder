#!/bin/bash
set -u

fed_ver="$1"
dist="f${fed_ver}"

cd "$( dirname "${BASH_SOURCE[0]}" )/../../"
. scripts/utils/volumes.sh

podman run --attach stdout --attach stderr --pull=never --rm=true --network=none \
	$vol_scripts $vol_output \
	"localhost/repobuilder-${dist}" /repobuilder/scripts/container/create-repo.sh

