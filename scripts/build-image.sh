#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/../"
. scripts/messages.sh

# -- set up some vars for later use

if [ "$#" -eq 0 ]; then
	message FAIL "repobuilder.sh" "Expected a Fedora release number"
	exit 127
fi

fed_ver="$1"
dist="f${fed_ver}"

. scripts/volumes.sh

mkdir -p "output/${dist}"

# -- pull from container registry

message INFO "image(${dist})" "Pulling from registry..."

source_image="registry.fedoraproject.org/fedora:${fed_ver}"
podman pull --quiet "$source_image" >/dev/null

if [ "$?" -ne 0 ]; then
	message FAIL "image(${dist})" "Failed to pull from registry"
	exit 1
fi
message OK "image(${dist})" "Pulled successfully"

# -- get deps

message INFO "image(${dist})" "Building image..."

container=$(podman create $vol_all --quiet "$source_image" /repobuilder/scripts/install-build-requires.sh "${dist}")
if [ "$?" -ne 0 ]; then
	message FAIL "image(${dist})" "Failed to create container from image"
	exit 1
fi

podman start --attach "$container" 2>/dev/null
if [ "$?" -ne 0 ]; then
	message FAIL "image(${dist})" "Failed to run the container"
	exit 1
fi

build_image=$(podman commit "$container" "localhost/repobuilder-${dist}" 2>/dev/null)
if [ "$?" -ne 0 ]; then
	message FAIL "image(${dist})" "Failed to commit container-based image"
	exit 1
fi

podman container rm "$container" >/dev/null
message OK "image(${dist})" "Built successfully"

