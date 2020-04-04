#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
. scripts/messages.sh

# -- clean if forced to

message INFO "clean" "Removing previously built packages..."
if [ "${REPOBUILDER_FORCE_CLEAN}" -eq "1" ] && [ -d output/ ]; then
	if ! rm -rf output/; then
		message FAIL "clean" "Failed to remove old builds"
		exit 1
	fi
fi
message OK "clean" "Old builds removed successfully"

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

# -- create repositories

echo -n "${REPOBUILDER_RELEASE}" | xargs -P "${REPOBUILDER_PARALLEL}" -n 1 ./scripts/build-repo.sh

# -- cleanup

if [ "${REPOBUILDER_RM}" -eq "1" ]; then
	message INFO "rm" "Removing containers and images"
	for fed_ver in "${REPOBUILDER_RELEASE}"; do
		podman image rm "localhost/repobuilder-f${fed_ver}" >/dev/null
	done
	message OK "rm" "Container images removed successfully"
fi

