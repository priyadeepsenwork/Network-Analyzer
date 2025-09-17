#!/bin/bash

#===============================================================================
# SCRIPT: 	network-service.sh
# AUTHOR: 	github.com/priyadeepsenwork
# DESCRIPTION: 	Network and Service Health Monitor,
#		Pings external hosts and checks local service status.	
# VERSION:	1.0
# CREATED:	17th September, 2025
# USAGE:	./network-service.sh
#===============================================================================


# Enable 'STRICT MODE' for better error handling
set -o errexit	# Exit on any command failure
set -o pipefail # Exit if any command in the pipeline fails
set -o nounset	# Exit on undefined variables


#===============================================================================
# CONFIGURATION SECTION
#===============================================================================

# External hosts to ping (hostnames and IP addresses)
declare -a HOSTS_TO_PING=(
	"google.com"
	"8.8.8.8"
	"github.com"
	"cloudflare.com"
	"1.1.1.1"
)

# Local services to check
declare -a SERVICES_TO_CHECK=(
	"sshd"
	"nginx"
	"systemd-resolved"
	"NetworkManager"
)

# Configuration Variables
readonly PING_COUNT=1
readonly PING_TIMEOUT=3
readonly SCRIPT_NAME="$(basename "${0}")"

# Color codes for output format
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

# Status Tracking Variables
TOTAL_HOSTS=0
SUCCESSFUL_PINGS=0
TOTAL_SERVICES=0
RUNNING_SERVICES=0


#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

#	Function to Print colored output
print_status() {
	local color="$1"
	local message="$2"
	printf "${color}%s${COLOR_NC}\n" "$message"
}

#	Function to print section headers
print_header() {
	local header="$1"
	echo ""
	printf "${COLOR_BLUE}================================${COLOR_NC}"
	printf "${COLOR_BLUE}%s${COLOR_NC}\n" "$header"
	printf "${COLOR_BLUE}================================${COLOR_NC}"
}

#	Function to get timestamp
get_timestamp() {
	date '+%Y-%m-%d %H:%M:%S'
}





