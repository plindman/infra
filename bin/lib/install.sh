#!/bin/bash
# lib/install.sh

# TERRAFORM_VERSION="1.5.7"  # Update as needed
# ANSIBLE_VERSION="2.15.4"   # Update as needed

check_sudo() {
    if ! command -v sudo &> /dev/null; then
        echo "Error: 'sudo' is required but not installed"
        exit 1
    fi
}

install_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo "Installing Terraform..."
        check_sudo
        
        # Add HashiCorp GPG key
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
        wget -O- https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor | \
            sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

        # Add HashiCorp repo
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
            https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list

        # Install Terraform
        sudo apt-get update && sudo apt-get install -y terraform

        # Verify installation
        terraform version
    else
        echo "Terraform is already installed: $(terraform version)"
    fi
}

install_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        check_sudo
        
        # Add Ansible repository
        sudo apt-get update && sudo apt-get install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible

        # Install Ansible
        sudo apt-get install -y ansible

        # Verify installation
        ansible --version
    else
        echo "Ansible is already installed: $(ansible --version | head -n1)"
    fi
}

install_required_tools() {
    echo "Checking and installing required tools..."
    
    # Install essential tools
    sudo apt-get update && sudo apt-get install -y \
        jq \
        yq \
        curl \
        wget \
        git

    # Install Terraform and Ansible
    install_terraform
    install_ansible
}

check_required_tools() {
    local missing_tools=()
    
    # Check for required tools
    for tool in terraform ansible jq yq curl wget git; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # If any tools are missing, offer to install them
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "Missing required tools: ${missing_tools[*]}"
        read -p "Would you like to install missing tools? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_required_tools
        else
            echo "Required tools must be installed to continue."
            exit 1
        fi
    fi
}