#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

. scripts/dist.sh
. scripts/messages.sh

fedora_current="${fed_ver}"
fedora_previous="$(expr "${fedora_current}" - 1)"
unset fed_ver dist

echo -n "${fedora_current} ${fedora_previous}" | xargs -P 0 -n 1 ./scripts/repobuilder.sh

echo "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

