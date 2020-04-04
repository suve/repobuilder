#!/bin/bash

fed_ver="$1"
dist="f${fed_ver}"

cd "$( dirname "${BASH_SOURCE[0]}" )/../"
. scripts/messages.sh
. scripts/volumes.sh

podman run --attach stdout --attach stderr --rm=true --network=none \
	$vol_scripts $vol_output \
	"localhost/repobuilder-${dist}" /repobuilder/scripts/create-repo.sh

