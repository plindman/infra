#!/bin/bash
# ssh.sh - SSH key management functions

# Generate SSH keys for all servers in a project
generate_project_ssh_keys() {
    local project_name=$1
    local server_names
    server_names=$(get_server_names_from_config "$project_name")

    for server_name in $server_names; do
        generate_ssh_key $server_name
    done
}

# Generate SSH key for a single server
generate_ssh_key() {
    local server_name=$1
    local key_path="$HOME/.ssh/${server_name}-key"
    local key_comment="${server_name}-key"

    if [ ! -f "$key_path" ]; then
        print_info "Generating SSH key for $server_name: $key_path"
        ssh-keygen -t ed25519 -C "$key_comment" -f "$key_path" -N ""
    else
        print_warn "SSH key already exists for $server_name: $key_path"
    fi
}

update_known_hosts () {
    local ip=$1

    # Check if known_hosts file exists, create it if it doesn't
    local known_hosts="$HOME/.ssh/known_hosts"
    if [ ! -f $known_hosts ]; then
        touch $known_hosts
        print_info "Created new $known_hosts file."
    fi

    # Check if the IP already exists in known_hosts
    if ! ssh-keygen -F "$ip" > /dev/null 2>&1; then
        print_info "IP $ip not found in $known_hosts. Adding it."
        
        # Generate the SSH key for the IP if it's not in known_hosts
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ip" 2>/dev/null

        # Use ssh-keyscan to add the key to known_hosts (suppress extra comments)
        ssh-keyscan -H "$ip" 2>/dev/null | tee -a "$HOME/.ssh/known_hosts" > /dev/null
    else
        print_warn "IP $ip already exists in known_hosts. Skipping ssh-keygen/ssh-keyscan."
    fi
}