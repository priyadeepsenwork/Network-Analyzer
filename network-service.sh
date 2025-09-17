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

#===============================================================================
# CORE FUNCTIONS
#===============================================================================


#	Function to check if a host is reachable via pinging
check_host() {
	local host="$1"
	local ping_result

	# Increment total host counter
	((TOTAL_HOSTS++))

	# Perform ping check with timeout and limited count
	# Redirect both stdout and stderr to capture all output

	if  ping_result=$(ping -c "${PING_COUNT}" -W "${PING_TIMEOUT}" "$host" 2>&1); then
		# check if ping was actually successful by looking for successful transmission.
		if echo "$ping_result" | grep -q "1 packets transmitted, 1 received\|1 packets transmitted, 1 packets received"; then
			print_status "$COLOR_GREEN" "$host - REACHABLE"
			((SUCCESSFUL_PINGS++))
		else
			print_status "$COLOR_RED" "$host - UNREACHABLE (ping failed)"
			return 1
		fi 
	else
		print_status "$COLOR_RED" "$HOST - UNREACHABLE (connection failed)"
		return 1
	fi

}


#	Function to check if a service is running
check_service() {
	local service_name="$1"
	local service_status

	# Increment total services counter here
	((TOTAL_SERVICES++))

	# First check if systemctl is available and service exists
	if ! command -v systemctl >/dev/null 2>&1; then
		print_status "$COLOR_YELLOW" "$service_name - UNKNOWN (systemctl not available)"
		return 2
	fi

	# Now we have to check service status using systemctl is-active
	if systemctl is-active "$service_name" >/dev/null 2>&1; then
		# Double-check with systemctl status for more detailed info
		if echo "$service_status" | grep -q "Active: active (running)\|Active: active (exited)"; then
			print_status "$COLOR_GREEN" "$service_name - RUNNING"
			((RUNNING_SERVICES++))
			return 0
		fi
	fi
}






