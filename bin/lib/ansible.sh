#!/bin/bash
# ansible.sh - Ansible management functions

get_ansible_dir() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local ansible_dir="$project_dir/ansible"
    echo $ansible_dir
}

# Create Ansible inventory from Terraform output
create_ansible_inventory() {
    local project_name=$1
    local ansible_dir=$(get_ansible_dir "$project_name")
    local inventory_file="$ansible_dir/hosts.ini"

    mkdir -p "$ansible_dir"

    # Get Terraform output
    local server_data
    server_data=$(get_terraform_servers $project_name)

    # Check if the server data is non-empty
    if [[ -z "$server_data" ]]; then
        print_error "No terraform server data found."
    fi

    # Create inventory file
    echo "[servers]" > "$inventory_file"

    # Parse JSON and add each server
    for name in $(echo "$server_data" | jq -r 'keys[]'); do
        local ip=$(echo "$server_data" | jq -r --arg name "$name" '.[$name]')
        local ssh_key_path="~/.ssh/$name-key"

        echo "$name ansible_host=$ip ansible_user=root ansible_ssh_private_key_file=$ssh_key_path ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> "$inventory_file"

        update_known_hosts $ip 
    done

    print_info "Ansible inventory created at $inventory_file"
}

# Run Ansible playbook
run_ansible() {
    local project_name=$1
    local ansible_dir=$(get_ansible_dir "$project_name")
    local inventory_file="$ansible_dir/hosts.ini"

    # Copy playbook template if it doesn't exist
    if [ ! -f "$ansible_dir/playbook.yml" ]; then
        cp "$ROOT_DIR/templates/ansible/playbooks/setup_servers.yml" "$ansible_dir/playbook.yml"
    fi

    # Run playbook
    ansible-playbook -i "$inventory_file" "$ansible_dir/playbook.yml"
}