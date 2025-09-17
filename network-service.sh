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
		if service_Status=$(systemctl status "$service_name" 2>/dev/null); then
			if echo "$service_status" | grep -q "Active: active (running)\|Active: active (exited)"; then
				print_status "$COLOR_GREEN" "$service_name - RUNNING"
				((RUNNING_SERVICES++))
				return 0
			fi
		fi
		print_status "$COLOR_GREEN" "$service_name - RUNNING"
		((RUNNING_SERVICES++))
		return 0
	else
		# Check if service exists but is inactive
		if systemctl list-unit-files "$service_name.service" >/dev/null 2>&1; then
			print_status "$COLOR_RED" "$service_name - STOPPED"
		else
			print_status "$COLOR_YELLOW" "$service_name - NOT FOUND"
		fi
		return 1
	fi
}


#	Function to display summary statistics
display_summary() {
	local timestamp
	timestamp=$(get_timestamp)

	print_header "HEALTH CHECK SUMMARY"

	printf "${COLOR_BLUE}Report generated at: ${COLOR_NC} %s\n\n" "$timestamp"

	# Network connectivity summary
	printf "${COLOR_BLUE}🌐 Network Connectivity:${COLOR_NC}\n"
	if [ "$SUCCESSFUL_PINGS" -eq "$TOTAL_HOSTS" ]; then
		print_status "$COLOR_GREEN" "    All hosts reachable ($SUCCESSFUL_PINGS/$TOTAL_HOSTS)"
	elif [ "$SUCCESSFUL_PINGS" -gt 0 ]; then
		print_status "$COLOR_YELLOW" "    Partial connectivity ($SUCCESSFUL_PINGS/$TOTAL_HOSTS hosts reachable)"
	else
		print_status "$COLOR_RED" "    No hosts reachable ($SUCCESSFUL_PINGS/%$TOTAL_HOSTS)"
	fi

	echo ""

	# Service status summary
    	printf "${COLOR_BLUE}🔧 Service Status:${COLOR_NC}\n"
	if [ "$RUNNING_SERVICES" -eq "$TOTAL_SERVICES" ]; then
		print_status "$COLOR_GREEN" "    All services are running. list: ($RUNNING_SERVICES/$TOTAL_SERVICES)"
	elif [ "$RUNNING_SERVICES" -gt 0 ]; then
		print_status "$COLOR_YELLOW" "    Some services are down: list: ($RUNNING_SERVICES/$TOTAL_SERVICES running)"
	else
		print_status "$COLOR_RED" "    All services are down, please retry. list: ($RUNNING_SERVICES/$TOTAL_SERVICES)"
	fi

	echo ""


	# Overall system health
	printf "${COLOR_BLUE}🏥 Overall Health:${COLOR_NC} "
	local network_health_pct=$((SUCCESSFUL_PINGS * 100 / TOTAL_HOSTS))
	local service_health_pct=$((RUNNING_SERVICES * 100 / TOTAL_SERVICES))
	local overall_health_pct=$(((network_health_pct + service_health_pct) / 2))

	if [ "$overall_health_pct" -ge 90 ]; then
		print_status "$COLOR_GREEN" "EXCELLENT ($overall_health_pct%)"
	elif [ "$overall_health_pct" -ge 70 ]; then
		print_status "$COLOR_YELLOW" "GOOD ($overall_health_pct%)"
	elif [ "$overall_health_pct" -ge 50 ]; then
		print_status "$COLOR_YELLOW" "FAIR ($overall_health_pct%)"
	else
		print_status "$COLOR_RED" "POOR ($overall_health_pct%)"
	fi

	echo ""
}



#	--- ERROR HANDLING ---
error_handler() {
	local exit_code=$?
	local line_number=$1
	print_status "$COLOR_RED" "!!! Error occured on line $line_number (exit code: $exit_code)"
	echo ""
	print_status "$COLOR_YELLOW" "### Script Execution interrupted - partial results may be available"
	exit "$exit_code"
}


#	--- Function to display USAGE INFORMATION ---
show_usage() {
	echo "Usage: $SCRIPT_NAME [options]"
	echo ""
	echo "Options:"
	echo "  -h, --help	Show all the commands available"
	echo "  -v, --verbose	Enable verbose output"
	echo ""
	echo "Description:"

}

#===============================================================================
#	MAIN EXECUTION FLOW OF THE PROGRAM
#===============================================================================

# Setup Error handling
trap 'error_handler $LINEN0' ERR

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			show usage
			exit 0
			;;
		-v|--verbose)
			set -0 xtrace	# Enables verbose mode
			shift
			;;
		*)
			print_status "$COLOR_RED" "!Unknown Option: $1"
			show_usage
			exit 1
			;;
	esac
done










