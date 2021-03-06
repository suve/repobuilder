#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

REPOBUILDER_BUILDER_SKIP="0"
REPOBUILDER_BUILDER_UPDATE="0"
REPOBUILDER_DEBUGINFO="--nodebuginfo"
REPOBUILDER_FORCE_CLEAN="0"
REPOBUILDER_OUTERNET="0"
REPOBUILDER_PACKAGE=""
REPOBUILDER_PARALLEL=""
REPOBUILDER_RELEASE=""
REPOBUILDER_RM="0"

while [ "$#" -gt 0 ]; do
	if [ "$1" == "--help" ]; then
cat <<EOHELP
Usage: repobuilder.sh [OPTIONS...]
Available options (in alphabetical order):
--builder-skip
  Do not perform the "install BuildRequires" step in the builder container.
  This can be useful if you're rebuilding some packages and you're 100% sure
  that the builder containers already contain all the dependencies.
  NOTE: This option will be ignored if the builder container does not exist.
--builder-update
  Update all packages in the container images.
  Normally, only direct dependencies of the packages being built are updated.
--force-clean
  Remove the output directory at the start.
--help
  Display this help message and exit.
--outernet
  Allow internet access during builds.
--package PKG
  Instead of all packages inside the package/ directory, build only PKG.
  PKG can be a single name, or multiple names separated with a comma.
--parallel NUMBER
  Limit the number of simultaneously running containers to NUMBER.
  The default value is the same as the number of available CPUs.
  Use 0 for "no limit".
--release NUMBER
  Build the packages for the specified Fedora release.
  You can specify multiple numbers separated by a comma.
  The default value is "\$N, \$N-1", where \$N is the release you're running.
--rm
  Remove the container images after finishing.
  NOTE: This removes only repobuilder's images, not the base Fedora images.
--version
  Display version information and exit.
--with-debuginfo
  Enable debuginfo generation.
  By default, building debuginfo packages is disabled.
EOHELP
		exit
	elif [ "$1" == "--builder-skip" ]; then
		REPOBUILDER_BUILDER_SKIP=1
	elif [ "$1" == "--builder-update" ]; then
		REPOBUILDER_BUILDER_UPDATE=1
	elif [ "$1" == "--force-clean" ]; then
		REPOBUILDER_FORCE_CLEAN=1
	elif [ "$1" == "--outernet" ]; then
		REPOBUILDER_OUTERNET=1
	elif [ "$1" == "--package" ]; then
		REPOBUILDER_PACKAGE="$(echo "$2" | tr ',' ' ')"
		shift
	elif [ "$1" == "--parallel" ]; then
		REPOBUILDER_PARALLEL="$2"
		shift
	elif [ "$1" == "--release" ]; then
		REPOBUILDER_RELEASE="$(echo "$2" | tr ',' ' ')"
		shift
	elif [ "$1" == "--rm" ]; then
		REPOBUILDER_RM=1
	elif [ "$1" == "--version" ]; then
		. ./scripts/utils/version.sh
		echo "repobuilder v.${REPOBUILDER_VERSION} by suve"
		exit
	elif [ "$1" == "--with-debuginfo" ] || [ "$1" == "--with-debug-info" ]; then
		REPOBUILDER_DEBUGINFO=""
	else
		echo "repobuilder.sh: Unrecognized argument \"$1\""
		exit 1
	fi

	shift
done

# -- set default values / validate values

if [ "${REPOBUILDER_BUILDER_SKIP}" -eq 1 ] && [ "${REPOBUILDER_BUILDER_UPDATE}" -eq 1 ]; then
	echo "repobuilder.sh: Conflicting options specified: --builder-skip and --builder-update"
	exit 1
fi

if [ "${REPOBUILDER_PACKAGE}" == "" ]; then
	for pkg in $(find packages/ -mindepth 1 -maxdepth 1 -type d); do
		pkg="$(basename "${pkg}")"
		REPOBUILDER_PACKAGE="${REPOBUILDER_PACKAGE} ${pkg}"

		if [ ! -f "packages/${pkg}/${pkg}.spec" ]; then
			echo "repobuilder.sh: The \"packages/${pkg}\" directory does not contain a spec file"
			exit 1
		fi
	done
else
	for pkg in ${REPOBUILDER_PACKAGE}; do
		if [ ! -d "packages/${pkg}" ]; then
			echo "repobuilder.sh: Cannot find package \"${pkg}\""
			exit 1
		fi
		if [ ! -f "packages/${pkg}/${pkg}.spec" ]; then
			echo "repobuilder.sh: The \"packages/${pkg}\" directory does not contain a spec file"
			exit 1
		fi
	done
fi

if [ "${REPOBUILDER_PARALLEL}" == "" ]; then
	REPOBUILDER_PARALLEL="$(nproc)"
fi

if [ "${REPOBUILDER_RELEASE}" == "" ]; then
	. ./scripts/utils/dist.sh

	fedora_current="${fed_ver}"
	fedora_previous="$(expr "${fed_ver}" - 1)"
	unset fed_ver dist

	REPOBUILDER_RELEASE="${fedora_current} ${fedora_previous}"
fi

# -- export everything

export REPOBUILDER_BUILDER_SKIP REPOBUILDER_BUILDER_UPDATE
export REPOBUILDER_DEBUGINFO
export REPOBUILDER_FORCE_CLEAN
export REPOBUILDER_OUTERNET
export REPOBUILDER_PACKAGE REPOBUILDER_PARALLEL
export REPOBUILDER_RELEASE REPOBUILDER_RM

# -- add a signal handler

. ./scripts/utils/messages.sh

function signal_handler() {
	message "STOP" "" "$1; killing all containers and child processes..."

	pkill --signal SIGKILL --parent "$$" xargs

	CONTAINERS=$(podman container list | grep 'localhost/repobuilder' | cut -f1 -d' ')
	echo "${CONTAINERS}" | xargs podman container kill --signal SIGKILL >/dev/null
	echo "${CONTAINERS}" | xargs podman container rm >/dev/null

	message "STOP" "" "Containers killed; repobuilder stopped"
	exit 13
}

trap "signal_handler 'Keyboard interrupt'" SIGINT
trap "signal_handler 'SIGTERM received'" SIGTERM

# -- call the main script proper

if ! ./scripts/host/repobuilder.sh; then
	exit "$?"
fi

# -- all done

message "DONE" "" "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

