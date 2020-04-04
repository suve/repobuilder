#!/bin/bash

dist="$1"
pkg="$2"

cd "$( dirname "${BASH_SOURCE[0]}" )/../"
. scripts/messages.sh
. scripts/volumes.sh

podman run --attach stdout --attach stderr --network none --rm=true \
	$vol_all "localhost/repobuilder-${dist}" /repobuilder/scripts/rpmbuild.sh "${pkg}"

