#!/bin/bash
# ANSI color codes for better console output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# Function to print messages with colors
print_info() {
    # echo -e "${BLUE}$1${RESET}"
    echo -e "${BLUE}[INFO]${RESET} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

# todo - refactor away the print_warnings
print_warning() {
    print_warn
}
print_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

print_error() {
    echo -e "${RED}[ERROR]]${RESET} $1"
}