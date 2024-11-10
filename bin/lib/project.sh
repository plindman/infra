#!/bin/bash
# lib/project.sh

# Get absolute path to project directory
get_projects_root_dir() {
    echo "$ROOT_DIR/projects"
}

get_project_dir() {
    local project_name=$1
    echo "$ROOT_DIR/projects/infra/$project_name"
}

# Initialize a new project
init_project() {
    local project_name=$1
    local server_names=$2
    local config_file=$(get_config_file_path "$project_name")
    local project_dir=$(get_project_dir "$project_name")

    if [ -f "$config_file" ] || [ -d "$project_dir" ]; then
        print_error "Error: Project '$project_name' already exists"
        exit 1
    fi

    if [ ! -d "$(get_projects_root_dir)" ]; then
        mkdir -p "$(get_projects_root_dir)"
    fi

    print_info "Creating new project: $project_name"
    create_config_file $1 $2
    mkdir -p "$project_dir"

    print_success "Project initialized at: $project_dir"
}

prepare_project() {
    local project_name=$1
    
    print_info "Preparing project: $project_name"
    
    # Validate configuration
    validate_config "$project_name"

    # Generate SSH keys for all servers
    generate_project_ssh_keys "$project_name"

    # Prepare Terraform workspace
    prepare_terraform_workspace "$project_name"
    
    print_success "Project preparation completed: $project_name"
}

deploy_project() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local config_file=$(get_config_file_path "$project_name")
    
    print_info "Deploying project: $project_name"
    
    # Deploy infrastructure
    deploy_terraform "$project_name"

    # Create Ansible inventory
    create_ansible_inventory "$project_name"

    # Run Ansible playbook
    run_ansible "$project_name"
    
    print_success "Project deployment completed: $project_name"
}

destroy_project() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    
    echo "Warning: This will destroy all resources in project: $project_name"
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Destroying project infrastructure..."
        
        # Destroy Terraform resources
        destroy_terraform "$project_name"
        
        # Optionally clean up local files
        read -p "Do you want to remove local project files? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing project directory: $project_dir"
            rm -rf "$project_dir"
        fi
        
        echo "Project destruction completed: $project_name"
    else
        echo "Project destruction cancelled"
    fi
}

prepare_terraform_workspace() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local terraform_dir="$project_dir/terraform"
    local template_dir="$ROOT_DIR/templates/terraform"
    
    # Create terraform directory if it doesn't exist
    mkdir -p "$terraform_dir"
    
    # Copy terraform template files
    cp "$template_dir"/*.tf "$terraform_dir/"
    
    # Generate tfvars from config
    generate_tfvars "$project_name"
}

generate_tfvars() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local config_file="$project_dir/config.yaml"
    local tfvars_file="$project_dir/terraform/terraform.tfvars.json"
    
    # Get defaults from config
    local defaults
    defaults=$(yq eval '.defaults' "$config_file")
    
    # Get server names
    local servers
    servers=$(yq eval '.servers | keys' "$config_file")
    
    # Start building the tfvars JSON
    echo "{" > "$tfvars_file"
    echo "  \"project_name\": \"$project_name\"," >> "$tfvars_file"
    echo "  \"servers\": {" >> "$tfvars_file"
    
    # Process each server
    local first=true
    for server in $(echo "$servers" | yq eval '.[]' -); do
        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$tfvars_file"
        fi
        
        # Get server-specific config or use defaults
        local server_config
        server_config=$(yq eval ".servers.[\"$server\"]" "$config_file")
        
        echo "    \"$server\": {" >> "$tfvars_file"
        echo "      \"server_type\": \"$(yq eval '.server_type // .defaults.server_type' "$config_file")\"," >> "$tfvars_file"
        echo "      \"image\": \"$(yq eval '.image // .defaults.image' "$config_file")\"," >> "$tfvars_file"
        echo "      \"location\": \"$(yq eval '.location // .defaults.location' "$config_file")\"," >> "$tfvars_file"
        echo "      \"labels\": $(yq eval '.labels // .defaults.labels' "$config_file" -o=json)" >> "$tfvars_file"
        echo "    }" >> "$tfvars_file"
    done
    
    # Close the JSON
    echo "  }" >> "$tfvars_file"
    echo "}" >> "$tfvars_file"
    
    echo "Generated terraform.tfvars.json at: $tfvars_file"
}