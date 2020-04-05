#!/bin/bash

dist="$1"
pkg="$2"

cd "$( dirname "${BASH_SOURCE[0]}" )/../../"
. scripts/utils/volumes.sh

if [ "${REPOBUILDER_OUTERNET}" -eq "1" ]; then
	network="--network bridge"
else
	network="--network none"
fi

podman run --attach=stdout --attach=stderr --pull=never --rm=true \
	$network $vol_all \
	"localhost/repobuilder-${dist}" /repobuilder/scripts/container/rpmbuild.sh "${pkg}"
