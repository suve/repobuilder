#!/bin/bash
set -u

cd "$( dirname "${BASH_SOURCE[0]}" )/../../"
. scripts/utils/messages.sh

# -- set up some vars for later use

if [ "$#" -eq 0 ]; then
	message FAIL "build-image.sh" "Expected a Fedora release number"
	exit 127
fi

fed_ver="$1"
dist="f${fed_ver}"
target_image="localhost/repobuilder-${dist}"

. scripts/utils/volumes.sh
mkdir -p "output/${dist}"

# -- check if the container image already exists

if ! podman image exists "${target_image}"; then
	source_image="registry.fedoraproject.org/fedora:${fed_ver}"
	create_options=""

	# fetch the base image if we don't have it
	if ! podman image exists "${source_image}"; then
		message INFO "image(${dist})" "Pulling from registry..."

		source_image="registry.fedoraproject.org/fedora:${fed_ver}"
		podman pull --quiet "$source_image" >/dev/null

		if [ "$?" -ne 0 ]; then
			message FAIL "image(${dist})" "Failed to pull from registry"
			exit 1
		fi
		message OK "image(${dist})" "Pulled successfully"
	fi

	verb_continuous="Building"
	verb_done="Built"
else
	if [ "${REPOBUILDER_BUILDER_SKIP}" -eq "1" ]; then
		exit
	fi

	source_image="${target_image}"

	create_options="--reuse"
	if [ "${REPOBUILDER_BUILDER_UPDATE}" -eq "1" ]; then
		create_options="${create_options} --update"
	fi

	verb_continuous="Updating"
	verb_done="Updated"
fi

# -- get deps

message INFO "image(${dist})" "${verb_continuous} image..."

container=$(podman create $vol_all --pull=never --quiet "$source_image" /repobuilder/scripts/container/install-build-requires.sh $create_options --package "${REPOBUILDER_PACKAGE}")
if [ "$?" -ne 0 ]; then
	message FAIL "image(${dist})" "Failed to create container from image"
	exit 1
fi

podman start --attach "$container" 2>/dev/null
dnf_status="$?"

# install-build-requires.sh breaks the "0 = success, everything else = fail" convention
# exitcode 1 is to be considered a success
if [ "${dnf_status}" -gt 1 ]; then
	message FAIL "image(${dist})" "Failed to run the container"
	exit 1
fi

# install-build-requires emits a 0 exitcode if no packages were installed/updated
if [ "${dnf_status}" -eq 0 ]; then
	message OK "image(${dist})" "No changes in packages; image is up to date"
	podman container rm "$container" >/dev/null 2>/dev/null
	exit 0
fi

message INFO "image(${dist})" "Committing container image..."

image_id="$(podman commit "$container" "${target_image}" 2>/dev/null)"
if [ "$?" -ne 0 ]; then
	podman container rm "$container" >/dev/null 2>/dev/null
	message FAIL "image(${dist})" "Failed to commit container-based image"
	exit 1
fi

podman image tag "${image_id}" "${target_image}:$(date --utc +%Y.%m%d.%H%M)" >/dev/null 2>/dev/null
message OK "image(${dist})" "${verb_done} successfully"

podman container rm "$container" >/dev/null 2>/dev/null

