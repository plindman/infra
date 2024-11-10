#!/bin/bash
# terraform.sh - Terraform management functions

get_terraform_dir() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local terraform_dir="$project_dir/terraform"
    echo $terraform_dir
}

prepare_terraform_workspace() {
    local project_name=$1
    local terraform_dir=$(get_terraform_dir "$project_name")

    # print_info "Preparing Terraform workspace for project '$project_name'"

    # Ensure Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Error: Terraform is not installed"
        exit 1
    fi

    # Check if terraform directory already exists, create if it doesn't
    if [ ! -d "$terraform_dir" ]; then
        print_info "Creating terraform directory: $terraform_dir"
        mkdir -p "$terraform_dir"
    else
        print_warn "Terraform directory already exists: $terraform_dir"
    fi

    # Copy the Terraform templates to the terraform directory
    local template_dir="./templates/terraform"
    
    # Check if template directory exists
    if [ ! -d "$template_dir" ]; then
        print_error "No terraform template directory found in $template_dir"
        return 1
    fi

    # Copy templates from the project templates to the terraform workspace
    print_info "Copying Terraform templates..."
    cp -r "$template_dir"/*.tf "$terraform_dir"

    # Replace placeholders in Terraform files with actual project values (e.g., project name)
    generate_tfvars $1

    print_info "Initializing Terraform workspace"
    terraform -chdir=$terraform_dir init

    print_info "Prepared Terraform workspace for project '$project_name' in folder $terraform_dir."
}

# Generate terraform.tfvars.json from project config
generate_tfvars() {
    local project_name=$1
    local terraform_dir=$(get_terraform_dir "$project_name")
    local config_file=$(get_config_file_path $project_name)

    local tfvars_file="$terraform_dir/terraform.tfvars"

    # print_info "Creating tfvars_file file..."

    # Convert YAML to JSON using pipe and process with jq
    cat $config_file | yq | jq -r '

    "project_name = \"" + .name + "\"\n\n" + 
    "servers = {\n" +
    .defaults as $defaults |
    (
        # Iterate over each item in the `servers` array
        .servers | map(
            if type == "string" then
                # If item is a string, treat it as the server name with default values
                "  " + . + " = {\n" +
                "    server_type = \"" + ($defaults.server_type // "") + "\"\n" +
                "    image       = \"" + ($defaults.image // "") + "\"\n" +
                "    location    = \"" + ($defaults.location // "") + "\"\n" +
                "    labels = {\n" +
                (
                    ($defaults.labels // {}) | to_entries | map(
                        "      " + .key + " = \"" + .value + "\""
                    ) | join("\n")
                ) + "\n" +
                "    }\n" +
                "  }"
            elif type == "object" then
                # If item is an object, use server-specific values or fall back to defaults
                "  " + .name + " = {\n" +
                "    server_type = \"" + (.server_type // $defaults.server_type // "") + "\"\n" +
                "    image       = \"" + (.image // $defaults.image // "") + "\"\n" +
                "    location    = \"" + (.location // $defaults.location // "") + "\"\n" +
                "    labels = {\n" +
                (
                    # Check if `labels` exists, otherwise use defaults
                    ((.labels // $defaults.labels) | to_entries | map(
                        "      " + .key + " = \"" + .value + "\""
                    )) | join("\n")
                ) + "\n" +
                "    }\n" +
                "  }"
            else
                # Fallback for unexpected cases (e.g., empty or null values)
                ""
            end
        ) | join(",\n")
    ) +
    "\n}"

    ' > $tfvars_file

    print_info "Generated terraform.tfvars at $tfvars_file"
}

# Deploy infrastructure using Terraform
deploy_terraform() {
    local project_name=$1
    local terraform_dir=$(get_terraform_dir "$project_name")
    local project_dir=$(get_project_dir "$project_name")

    # Ensure Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Error: Terraform is not installed"
        exit 1
    fi

    # Check that terraform workspace has been prepared
    if [ ! -d "$terraform_dir" ]; then
        print_error "Error: Terraform workspace not prepared"
        exit 1
    fi

    # print_info "Initializing Terraform workspace"
    # terraform -chdir=$terraform_dir init
    terraform -chdir=$terraform_dir plan

    terraform -chdir=$terraform_dir apply -auto-approve

    print_info "Terraform deploy completed"
}

get_terraform_servers() {
    local project_name=$1

    # Check if terraform_dir exists
    local terraform_dir=$(get_terraform_dir "$project_name")

    if [[ ! -d "$terraform_dir" ]]; then
        print_error "Error: Terraform directory '$terraform_dir' not found."
        return 1
    fi

    # Check if server_ips is available in the output
    local server_data=$(terraform -chdir=$terraform_dir output -json server_ips)

    if [[ $? -ne 0 ]]; then
        print_error "Error: Failed to get server data from Terraform."
        return 1
    fi

    echo "$server_data"
}

# Destroy infrastructure
destroy_terraform() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")

    if [ -d "$project_dir/terraform" ]; then
        (cd "$project_dir/terraform" && \
            terraform destroy -auto-approve)
    fi
}