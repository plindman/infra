#!/bin/bash
# utils.sh - Shared utility functions

# Load environment variables from .env file
load_env() {
    if [ -f .env ]; then
        # echo "Loading configuration from .env..."
        source .env
        # export HCLOUD_TOKEN
        export TF_VAR_hcloud_token="$HCLOUD_TOKEN"
        print_info ".env loaded successfully."
    else
        print_error "No .env file found. Exiting."
        exit 1
    fi
}

# Get absolute path to project directory
get_project_dir() {
    local project_name=$1
    echo "$ROOT_DIR/projects/$project_name"
}

# Validate project exists
validate_project() {
    local project_dir=$(get_project_dir "$1")
    if [ ! -d "$project_dir" ]; then
        echo "Error: Project '$1' not found"
        exit 1
    fi
}

# List all projects
list_projects() {
    echo "Available projects:"
    for project in "$ROOT_DIR"/projects/*/; do
        if [ -d "$project" ]; then
            project_name=$(basename "$project")
            echo "- $project_name"
        fi
    done
}
