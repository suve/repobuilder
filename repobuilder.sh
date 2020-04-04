#!/bin/bash

mkdir -p output/

image='registry.fedoraproject.org/fedora:31'
podman pull "$image"

container=$(podman create --volume ./:/repobuilder "$image" /repobuilder/scripts/install-build-requires.sh)
podman start --attach "$container"
