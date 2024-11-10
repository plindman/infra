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
prepare_ansible() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local ansible_dir=$(get_ansible_dir "$project_name")
    local inventory_file="$ansible_dir/hosts.ini"

    # Copy playbook template if it doesn't exist
    cp -r "$ROOT_DIR/templates/ansible" $project_dir
    print_info "Ansible playbooks copied to project folder $ansible_dir"
}

# Run Ansible playbook
run_ansible() {
    local project_name=$1
    local ansible_dir=$(get_ansible_dir "$project_name")
    local inventory_file="$ansible_dir/hosts.ini"

    # Step 1: Generate the filename based on the existence of custom.yml
    playbook_file=$(if [ -f "$ansible_dir/playbooks/custom.yml" ]; then echo 'custom.yml'; else echo 'site.yml'; fi)
    playbook_path="$ansible_dir/playbooks/$playbook_file"

    # Step 2: Echo the selected playbook file
    echo "Using playbook: $playbook_path"

    # Step 3: Run the ansible-playbook command with the selected playbook
    ansible-playbook -i "$inventory_file" "$playbook_path"
}