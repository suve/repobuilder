#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
. scripts/messages.sh

# -- build images

echo -n "${REPOBUILDER_RELEASE}" | xargs -P "${REPOBUILDER_PARALLEL}" -n 1 ./scripts/build-image.sh

# -- build packages

message INFO "build" "Building packages..."

(
	packages="$(find packages/ -mindepth 1 -maxdepth 1 -type d)"
	for pkg in $packages; do
		pkg="$(basename "$pkg")"

		for fed_ver in ${REPOBUILDER_RELEASE}; do
			echo "f${fed_ver} ${pkg}"
		done
	done
) | xargs -P "${REPOBUILDER_PARALLEL}" -n 2 ./scripts/build-package.sh

# -- cleanup

if [ "${REPOBUILDER_RM}" -eq "1" ]; then
	message INFO "cleanup" "Removing containers and images"
	for fed_ver in "${REPOBUILDER_RELEASE}"; do
		podman image rm "localhost/repobuilder-f${fed_ver}" >/dev/null
	done
fi

