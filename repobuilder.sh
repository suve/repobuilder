#!/bin/bash

mkdir -p output/

source_image='registry.fedoraproject.org/fedora:31'
podman pull "$source_image"

container=$(podman create --volume ./:/repobuilder "$source_image" /repobuilder/scripts/install-build-requires.sh)
podman start --attach "$container"

build_image=$(podman commit "$container")
podman container rm "$container"

for PKG in $(find packages/ -mindepth 1 -maxdepth 1 -type d); do
	PKG=$(basename "$PKG")
	podman run --attach stdout --attach stderr --volume ./:/repobuilder \
		"$build_image" /repobuilder/scripts/build-package.sh "$PKG"
done
