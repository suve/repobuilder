#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

REPOBUILDER_FORCE_CLEAN="0"
REPOBUILDER_NO_REFRESH="0"
REPOBUILDER_PACKAGE=""
REPOBUILDER_PARALLEL="0"
REPOBUILDER_RELEASE=""
REPOBUILDER_RM="0"
REPOBUILDER_OUTERNET="0"

while [ "$#" -gt 0 ]; do
	if [ "$1" == "--help" ]; then
cat <<EOHELP
Usage: repobuilder.sh [OPTIONS...]
Available options (in alphabetical order):
--force-clean
  Remove the output directory at the start.
--help
  Display this help message and exit.
--no-refresh
  Do not update the container images.
  This can cause your build to fail if you added new packages
  or new BuildRequires to already existing packages.
--package PKG
  Instead of all packages inside the package/directory, build only PKG.
  PKG can be a single name, or multiple names separated with a comma.
--parallel NUMBER
  Limit the number of simultaneously running containers.
--release NUMBER
  Build the packages for the specified Fedora release.
  You can specify multiple numbers separated by a comma.
  The default value is "\$N, \$N-1", where \$N is the release you're running.
--rm
  Remove the container images after finishing.
  NOTE: This removes only the rpmbuild images, not the base Fedora images.
--outernet
  Allow internet access during builds.
EOHELP
		exit
	elif [ "$1" == "--forceclean" ] || [ "$1" == "--force-clean" ]; then
		REPOBUILDER_FORCE_CLEAN=1
	elif [ "$1" == "--norefresh" ] || [ "$1" == "--no-refresh" ]; then
		REPOBUILDER_NO_REFRESH=1
	elif [ "$1" == "--package" ]; then
		REPOBUILDER_PACKAGE="$(echo "$2" | tr ',' ' ')"
		shift
	elif [ "$1" == "--parallel" ]; then
		REPOBUILDER_PARALLEL="$2"
		shift
	elif [ "$1" == "--release" ]; then
		REPOBUILDER_RELEASE="$(echo "$2" \ tr ',' ' ')"
		shift
	elif [ "$1" == "--rm" ]; then
		REPOBUILDER_RM=1
	elif [ "$1" == "--outernet" ]; then
		REPOBUILDER_OUTERNET=1
	else
		echo "repobuilder.sh: Unrecognized argument \"$1\""
		exit 1
	fi

	shift
done

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

if [ "${REPOBUILDER_RELEASE}" == "" ]; then
	. ./scripts/utils/dist.sh

	fedora_current="${fed_ver}"
	fedora_previous="$(expr "${fed_ver}" - 1)"
	unset fed_ver dist

	REPOBUILDER_RELEASE="${fedora_current} ${fedora_previous}"
fi

export REPOBUILDER_FORCE_CLEAN
export REPOBUILDER_NO_REFRESH
export REPOBUILDER_PACKAGE REPOBUILDER_PARALLEL
export REPOBUILDER_RELEASE REPOBUILDER_RM
export REPOBUILDER_OUTERNET

# -- call the main script proper

./scripts/host/repobuilder.sh

# -- all done

. ./scripts/utils/messages.sh
echo "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

