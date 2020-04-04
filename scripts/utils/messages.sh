function ANSI_COLOUR() {
	printf '\x1B[%dm' "$1"
}

ANSI_RED=$(ANSI_COLOUR 31)
ANSI_GREEN=$(ANSI_COLOUR 32)
ANSI_YELLOW=$(ANSI_COLOUR 33)
ANSI_CYAN=$(ANSI_COLOUR 36)

ANSI_RESET=$(ANSI_COLOUR 0)
ANSI_BOLD=$(ANSI_COLOUR 1)

function message() {
	local category="$1"
	local step="$2"
	shift 2

	local colour=""
	if [ "$category" == "FAIL" ]; then
		colour="$ANSI_RED"
	elif [ "$category" == "INFO" ]; then
		colour="$ANSI_CYAN"
	elif [ "$category" == "OK" ]; then
		colour="$ANSI_GREEN"
		category=" OK "
	else
		colour="$ANSI_YELLOW"
		category=" ?? "
	fi
	
	echo "${colour}[${category}]${ANSI_RESET} ${ANSI_BOLD}${step}${ANSI_RESET}:" "$@"
}
