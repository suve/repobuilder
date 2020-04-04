#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
. scripts/dist.sh
. scripts/messages.sh

fedora_current="${fed_ver}"
fedora_previous="$(expr "${fedora_current}" - 1)"
unset fed_ver dist

echo -n "${fedora_current} ${fedora_previous}" | xargs -P 0 -n 1 ./scripts/build-image.sh

message INFO "build" "Building packages..."

(
	packages="$(find packages/ -mindepth 1 -maxdepth 1 -type d)"
	for pkg in $packages; do
		pkg="$(basename "$pkg")"

		echo "f${fedora_current} ${pkg}"
		echo "f${fedora_previous} ${pkg}"
	done
) | xargs -P 0 -n 2 ./scripts/build-package.sh

# -- cleanup

message INFO "cleanup" "Removing containers and images"
podman image rm "localhost/repobuilder-f${fedora_current}" "localhost/repobuilder-f${fedora_previous}" >/dev/null

