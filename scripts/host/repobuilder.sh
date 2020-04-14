#!/bin/bash
set -u

cd "$( dirname "${BASH_SOURCE[0]}" )/../../"
. scripts/utils/messages.sh

# -- clean if forced to

if [ "${REPOBUILDER_FORCE_CLEAN}" -eq "1" ] && [ -d output/ ]; then
	message INFO "clean" "Removing previously built packages..."
	
	if ! rm -rf output/; then
		message FAIL "clean" "Failed to remove old builds"
		exit 2
	fi
	
	message OK "clean" "Old builds removed successfully"
fi

# -- build images

if ! echo -n "${REPOBUILDER_RELEASE}" | xargs -P "${REPOBUILDER_PARALLEL}" -n 1 ./scripts/host/build-image.sh; then
	exit 3
fi

# -- build packages

message INFO "build" "Building packages..."

(
	for pkg in ${REPOBUILDER_PACKAGE}; do
		for fed_ver in ${REPOBUILDER_RELEASE}; do
			echo "f${fed_ver} ${pkg}"
		done
	done
) | xargs -P "${REPOBUILDER_PARALLEL}" -n 2 ./scripts/host/build-package.sh

if [ "$?" -ne 0 ]; then
	exit 4
fi


# -- create repositories

if ! echo -n "${REPOBUILDER_RELEASE}" | xargs -P "${REPOBUILDER_PARALLEL}" -n 1 ./scripts/host/create-repo.sh; then
	exit 5
fi

# -- cleanup

if [ "${REPOBUILDER_RM}" -eq "1" ]; then
	message INFO "rm" "Removing containers and images"
	for fed_ver in ${REPOBUILDER_RELEASE}; do
		podman image rm "localhost/repobuilder-f${fed_ver}" >/dev/null
	done
	message OK "rm" "Container images removed successfully"
fi

