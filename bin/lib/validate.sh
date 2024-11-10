#!/bin/bash
# lib/validate.sh

validate_config() {
    local config_file=$(get_config_file_path "$project_name")
    local errors=()
    
    # Check if file exists
    if [ ! -f "$config_file" ]; then
        print_error "Error: Config file not found: $config_file"
        exit 1
    fi
    
    print_info "Validating config file $config_file"

    # Required fields
    local name
    name=$(yq '.name' "$config_file")
    if [ "$name" = "null" ]; then
        errors+=("Missing required field: name")
    fi
    
    # Check defaults block - todo defaults is not mandatory
    local has_defaults
    has_defaults=$(yq '.defaults' "$config_file")
    if [ "$has_defaults" = "null" ]; then
        print_warning "No defaults block in config file"
        # errors+=("Missing required block: defaults")
    else
        # Validate required default fields
        local fields=("server_type" "image" "location")
        for field in "${fields[@]}"; do
            local value
            value=$(yq ".defaults.$field" "$config_file")
            if [ "$value" = "null" ]; then
                print_warning "Field $field not present in defaults"
                # errors+=("Missing required default field: $field")
            fi
        done
    fi
    
    # Check servers block
    local has_servers
    has_servers=$(yq '.servers' "$config_file")
    if [ "$has_servers" = "null" ] || [ "$has_servers" = "{}" ]; then
        errors+=("Missing or empty servers configuration")
    fi
    
    # If there are any validation errors, display them and exit
    if [ ${#errors[@]} -gt 0 ]; then
        print_error "Configuration validation failed:"
        printf '%s\n' "${errors[@]}"
        exit 1
    fi
    
    print_info "Configuration validation successful"
}