#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

REPOBUILDER_NO_REFRESH="0"
REPOBUILDER_PARALLEL="0"
REPOBUILDER_RELEASE=""
REPOBUILDER_RM="0"
REPOBUILDER_OUTERNET="0"

while [ "$#" -gt 0 ]; do
	if [ "$1" == "--help" ]; then
cat <<EOHELP
Usage: repobuilder.sh [OPTIONS...]
Available options (in alphabetical order):
--help
  Display this help message and exit.
--no-refresh
  Do not update the container images.
  This can cause your build to fail if you added new packages
  or new BuildRequires to already existing packages.
--parallel NUMBER
  Limit the number of simultaneously running containers.
--release NUMBER
  Build the packages for the specified Fedora release.
  You can specify multiple numbers separated by a comma.
  The default value is "\$N, \$N-1", where \$N is the release you're running.
--rm
  Remove the container images after finishing.
--outernet
  Allow internet access during builds.
EOHELP
		exit
	elif [ "$1" == "--norefresh" ] || [ "$1" == "--no-refresh" ]; then
		REPOBUILDER_NO_REFRESH=1
	elif [ "$1" == "--parallel" ]; then
		REPOBUILDER_PARALLEL="$2"
		shift
	elif [ "$1" == "--release" ]; then
		REPOBUILDER_RELEASE="$(tr ',' ' ' "$2")"
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

if [ "${REPOBUILDER_RELEASE}" == "" ]; then
	. ./scripts/dist.sh

	fedora_current="${fed_ver}"
	fedora_previous="$(expr "${fed_ver}" - 1)"
	unset fed_ver dist

	REPOBUILDER_RELEASE="${fedora_current} ${fedora_previous}"
fi

export REPOBUILDER_NO_REFRESH
export REPOBUILDER_PARALLEL
export REPOBUILDER_RELEASE REPOBUILDER_RM
export REPOBUILDER_OUTERNET

# -- call the main script proper

./scripts/repobuilder.sh

# -- all done

. ./scripts/messages.sh
echo "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

