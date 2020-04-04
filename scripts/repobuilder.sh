#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
. messages.sh

cd ../

# -- output dir

mkdir -p output/

# -- pull from container registry

message INFO "image" "Pulling from registry..."

source_image='registry.fedoraproject.org/fedora:31'
podman pull --quiet "$source_image" >/dev/null

if [ "$?" -ne 0 ]; then
	message FAIL "image" "Failed to pull from registry"
	exit 1
fi
message OK "image" "Pulled successfully"

# -- get deps

message INFO "image" "Building image..."

container=$(podman create --quiet --volume ./:/repobuilder "$source_image" /repobuilder/scripts/install-build-requires.sh)
if [ "$?" -ne 0 ]; then
	message FAIL "image" "Failed to create container from image"
	exit 1
fi

podman start --attach "$container" 2>/dev/null
if [ "$?" -ne 0 ]; then
	message FAIL "image" "Failed to run the container"
	exit 1
fi

build_image=$(podman commit "$container" 2>/dev/null)
if [ "$?" -ne 0 ]; then
	message FAIL "image" "Failed to commit container-based image"
	exit 1
fi

message OK "image" "Built successfully"

# -- build packages

message INFO "build" "Building packages..."

find packages/ -mindepth 1 -maxdepth 1 -type d | xargs -P 0 -n 1 \
	podman run --attach stdout --attach stderr --volume ./:/repobuilder --network none --rm=true \
	"$build_image" /repobuilder/scripts/build-package.sh

# -- cleanup

message INFO "cleanup" "Removing containers and images"

podman container rm "$container" >/dev/null
podman image rm "$build_image" >/dev/null

echo "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

