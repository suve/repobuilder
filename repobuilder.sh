#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"
./scripts/repobuilder.sh

echo "All done! Your built packages can be found in the ${ANSI_BOLD}output/${ANSI_RESET} directory."

