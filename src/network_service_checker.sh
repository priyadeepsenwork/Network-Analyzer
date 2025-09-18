#!/bin/bash

# Network & Service Status Checker
# Author: Linux System Administrator
# Version: 1.0
# Description: Monitors network connectivity and essential system services

# Configuration
SCRIPT_NAME="Network & Service Status Checker"
VERSION="1.0"
LOG_FILE="/var/log/network_service_check.log"
CONFIG_FILE="./config.conf"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration (can be overridden by config file)
declare -a HOSTS=(
    "google.com"
    "8.8.8.8"
    "1.1.1.1"
    "github.com"
    "stackoverflow.com"
)

declare -a SERVICES=(
    "sshd"
    "systemd-resolved"
    "NetworkManager"
    "cron"
    "systemd-timesyncd"
)

# Ping configuration
PING_COUNT=3
PING_TIMEOUT=5

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show version information"
    echo "  -c, --config FILE   Use custom config file"
    echo "  -l, --log FILE      Use custom log file"
    echo "  -q, --quiet         Quiet mode (minimal output)"
    echo "  -j, --json          Output results in JSON format"
    echo "  --no-log            Don't write to log file"
    echo "  --hosts-only        Check only network hosts"
    echo "  --services-only     Check only system services"
    echo ""
    echo "Examples:"
    echo "  $0                  Run with default settings"
    echo "  $0 -c custom.conf   Run with custom configuration"
    echo "  $0 --json           Output results in JSON format"
}

# Function to display version
version() {
    echo "$SCRIPT_NAME v$VERSION"
}

# Function to load configuration file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${BLUE}[INFO]${NC} Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

# Function to log messages
log_message() {
    local message="$1"
    if [[ "$NO_LOG" != "true" ]]; then
        echo "[$TIMESTAMP] $message" >> "$LOG_FILE"
    fi
}

# Function to check network connectivity
check_network() {
    local host="$1"
    local result

    if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$host" > /dev/null 2>&1; then
        result="UP"
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo -e "${GREEN}[✓]${NC} $host is reachable"
        fi
        log_message "NETWORK: $host is reachable"
        return 0
    else
        result="DOWN"
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo -e "${RED}[✗]${NC} $host is unreachable"
        fi
        log_message "NETWORK: $host is unreachable"
        return 1
    fi
}

# Function to check service status
check_service() {
    local service="$1"
    local status

    if systemctl is-active --quiet "$service"; then
        status="RUNNING"
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo -e "${GREEN}[✓]${NC} $service is running"
        fi
        log_message "SERVICE: $service is running"
        return 0
    else
        status="STOPPED"
        if [[ "$QUIET_MODE" != "true" ]]; then
            echo -e "${RED}[✗]${NC} $service is not running"
        fi
        log_message "SERVICE: $service is not running"
        return 1
    fi
}

# Function to check if service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files "$service.service" > /dev/null 2>&1
}

# Function to generate JSON output
generate_json_output() {
    local network_results="$1"
    local service_results="$2"

    echo "{"
    echo '  "timestamp": "'$TIMESTAMP'",'
    echo '  "network": {'
    echo "$network_results"
    echo '  },'
    echo '  "services": {'
    echo "$service_results"
    echo '  }'
    echo "}"
}

# Function to run network checks
run_network_checks() {
    local network_json=""
    local network_failed=0
    local network_total=${#HOSTS[@]}

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${BLUE}=== Network Connectivity Check ===${NC}"
    fi

    for i in "${!HOSTS[@]}"; do
        local host="${HOSTS[$i]}"
        if check_network "$host"; then
            network_status="UP"
        else
            network_status="DOWN"
            ((network_failed++))
        fi

        if [[ "$JSON_OUTPUT" == "true" ]]; then
            network_json+='"'$host'": "'$network_status'"'
            if [[ $i -lt $((network_total - 1)) ]]; then
                network_json+=", "
            fi
        fi
    done

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${BLUE}Network Summary:${NC} $((network_total - network_failed))/$network_total hosts reachable"
        echo ""
    fi

    echo "$network_json"
    return $network_failed
}

# Function to run service checks
run_service_checks() {
    local service_json=""
    local service_failed=0
    local service_total=${#SERVICES[@]}

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${BLUE}=== System Service Check ===${NC}"
    fi

    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"

        if ! service_exists "$service"; then
            if [[ "$QUIET_MODE" != "true" ]]; then
                echo -e "${YELLOW}[!]${NC} $service does not exist on this system"
            fi
            log_message "SERVICE: $service does not exist"
            service_status="NOT_FOUND"
        else
            if check_service "$service"; then
                service_status="RUNNING"
            else
                service_status="STOPPED"
                ((service_failed++))
            fi
        fi

        if [[ "$JSON_OUTPUT" == "true" ]]; then
            service_json+='"'$service'": "'$service_status'"'
            if [[ $i -lt $((service_total - 1)) ]]; then
                service_json+=", "
            fi
        fi
    done

    if [[ "$QUIET_MODE" != "true" ]]; then
        echo -e "${BLUE}Service Summary:${NC} $((service_total - service_failed))/$service_total services running"
        echo ""
    fi

    echo "$service_json"
    return $service_failed
}

# Function to display final summary
display_summary() {
    local network_failed="$1"
    local service_failed="$2"
    local total_issues=$((network_failed + service_failed))

    if [[ "$QUIET_MODE" != "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${BLUE}=== Overall Summary ===${NC}"
        if [[ $total_issues -eq 0 ]]; then
            echo -e "${GREEN}[✓] All systems operational${NC}"
        else
            echo -e "${RED}[!] $total_issues issue(s) detected${NC}"
            if [[ $network_failed -gt 0 ]]; then
                echo -e "  ${RED}• $network_failed network connectivity issue(s)${NC}"
            fi
            if [[ $service_failed -gt 0 ]]; then
                echo -e "  ${RED}• $service_failed service issue(s)${NC}"
            fi
        fi
        echo ""
    fi

    return $total_issues
}

# Main execution function
main() {
    local network_failed=0
    local service_failed=0
    local network_json=""
    local service_json=""

    # Load configuration
    load_config

    # Check if log directory exists
    if [[ "$NO_LOG" != "true" ]]; then
        local log_dir=$(dirname "$LOG_FILE")
        if [[ ! -d "$log_dir" ]]; then
            sudo mkdir -p "$log_dir" 2>/dev/null || {
                echo -e "${YELLOW}[WARNING]${NC} Cannot create log directory. Logging to current directory."
                LOG_FILE="./network_service_check.log"
            }
        fi
    fi

    # Start logging
    log_message "Starting $SCRIPT_NAME v$VERSION"

    if [[ "$QUIET_MODE" != "true" && "$JSON_OUTPUT" != "true" ]]; then
        echo -e "${BLUE}$SCRIPT_NAME v$VERSION${NC}"
        echo -e "${BLUE}Started at: $TIMESTAMP${NC}"
        echo ""
    fi

    # Run checks based on options
    if [[ "$SERVICES_ONLY" != "true" ]]; then
        network_json=$(run_network_checks)
        network_failed=$?
    fi

    if [[ "$HOSTS_ONLY" != "true" ]]; then
        service_json=$(run_service_checks)
        service_failed=$?
    fi

    # Output results
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        generate_json_output "$network_json" "$service_json"
    else
        display_summary $network_failed $service_failed
    fi

    # Log completion
    local total_issues=$((network_failed + service_failed))
    log_message "Completed with $total_issues issue(s) detected"

    # Exit with appropriate code
    exit $total_issues
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            version
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET_MODE="true"
            shift
            ;;
        -j|--json)
            JSON_OUTPUT="true"
            shift
            ;;
        --no-log)
            NO_LOG="true"
            shift
            ;;
        --hosts-only)
            HOSTS_ONLY="true"
            shift
            ;;
        --services-only)
            SERVICES_ONLY="true"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main
