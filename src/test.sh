#!/bin/bash

# Test script for Network & Service Status Checker
# This script performs basic functionality tests

set -e

SCRIPT_PATH="./network_service_checker.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Testing Network & Service Status Checker...${NC}"

# Test 1: Check if script is executable
echo -n "Test 1: Script executable... "
if [[ -x "$SCRIPT_PATH" ]]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    chmod +x "$SCRIPT_PATH"
    echo -e "${BLUE}Made script executable${NC}"
fi

# Test 2: Help option
echo -n "Test 2: Help option... "
if $SCRIPT_PATH --help >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 3: Version option
echo -n "Test 3: Version option... "
if $SCRIPT_PATH --version >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 4: JSON output
echo -n "Test 4: JSON output... "
if $SCRIPT_PATH --json --no-log >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 5: Hosts only
echo -n "Test 5: Hosts only check... "
if $SCRIPT_PATH --hosts-only --quiet --no-log >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 6: Services only
echo -n "Test 6: Services only check... "
if $SCRIPT_PATH --services-only --quiet --no-log >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test 7: Custom config
echo -n "Test 7: Custom config... "
if $SCRIPT_PATH -c config.conf --quiet --no-log >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo ""
echo -e "${GREEN}All tests completed!${NC}"
echo ""
echo -e "${BLUE}Run a full test:${NC}"
echo "$SCRIPT_PATH"
