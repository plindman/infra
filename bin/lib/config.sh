#!/bin/bash
# config.sh - Working with the config.yaml file

create_config_file() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local server_names="${2:-$project_name}"

    # Path to the template and output configuration file
    TEMPLATE_PATH="$ROOT_DIR/templates/config.yaml.template"
    OUTPUT_PATH="$project_dir/config.yaml"

    cp "$TEMPLATE_PATH" "$OUTPUT_PATH"

    # Prepare the server names as a list in JSON format for yq
    local server_list
    IFS=' ' read -r -a server_array <<< "$server_names"
    server_list=$(printf '"%s", ' "${server_array[@]}" | sed 's/, $//')  # Remove trailing comma and space
    server_list="[$server_list]"  # Wrap it in square brackets for the array format

    # echo "$server_names converted into $server_list"

    # Modify copied template with project details
    yq -y -i ".name = \"$project_name\"" $OUTPUT_PATH
    yq -y -i ".servers = $server_list" "$OUTPUT_PATH"

    print_info "$OUTPUT_PATH created from template $TEMPLATE_PATH for servers $server_names."
    print_info "You can edit it to change servers and defaults."
}

get_config_file_name() {
    local project_name=$1
    local project_dir=$(get_project_dir "$project_name")
    local config_file="$project_dir/config.yaml"
    echo $config_file
}

# Get server names from project config
get_server_names() {
    local project_name=$1
    local config_file=$(get_config_file_name $project_name)

    yq -r '.servers[]' $config_file | tr '\n' ' '  # Converts newlines to spaces
}
