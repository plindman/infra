#!/bin/bash
# config.sh - Working with the config.yaml file

get_config_file_path() {
    local project_name=$1
    local project_dir=$(get_projects_root_dir)
    local config_file="$project_dir/$project_name.yaml"
    echo $config_file
}

create_config_file() {
    local project_name=$1
    local server_names="${2:-$project_name}"
    local config_file=$(get_config_file_path "$project_name")

    # Path to the template and output configuration file
    TEMPLATE_PATH="$ROOT_DIR/templates/config.yaml.template"
    cp "$TEMPLATE_PATH" "$config_file"

    # Prepare the server names as a list in JSON format for yq
    local server_list
    if [[ "$server_names" =~ \  ]]; then
        # If there are spaces, split the server names into an array
        IFS=' ' read -r -a server_array <<< "$server_names"
    else
        # If no spaces, treat it as a single server name
        server_array=("$server_names")
    fi
    server_list=$(printf '"%s", ' "${server_array[@]}" | sed 's/, $//')  # Remove trailing comma and space
    server_list="[$server_list]"  # Wrap it in square brackets for the array format

    # echo "$server_names converted into $server_list"

    # Modify copied template with project details
    yq -y -i ".name = \"$project_name\"" $config_file
    yq -y -i ".servers = $server_list" $config_file

    print_info "Used template $TEMPLATE_PATH."
    print_info "Created $config_file."
    print_info "Edit it to add/change/remove servers and change defaults."
}

# Get server names from project config
get_server_names_from_config() {
    local project_name=$1
    local config_file=$(get_config_file_path $project_name)

    yq -r '.servers[]' $config_file | tr '\n' ' '  # Converts newlines to spaces
}
