# Manage infra with infra-manager

``` bash
server-manager/
├── bin/                     # Scripts and commands
│   ├── infra-manager        # Main command script
│   ├── lib/                 # Shared bash functions
│   │   ├── terraform.sh     # Terraform-related functions
│   │   ├── ansible.sh       # Ansible-related functions
│   │   ├── ssh.sh           # SSH key management functions
│   │   └── utils.sh         # Utility functions (env loading etc)
├── templates/               # Shared templates
│   ├── terraform/           
│   │   ├── main.tf
│   │   └── variables.tf
│   └── ansible/
│       ├── playbooks/
│       └── inventory_template.ini
└── projects/                # Where individual projects live
    ├── project1/
    │   └── config.yaml      # Project-specific server definitions
    └── project2/
        └── config.yaml
```

To use this:
- Create the directory structure as shown above
- Place each script in its appropriate location
- Make the main script executable: chmod +x bin/infra-manager
- Create your project template files in templates/terraform/ and templates/ansible/

``` bash
./bin/server-manager init my-project "server-name1 server-name2"       # Initialize a new project
# projects/my-project/config.yaml       # Edit the project config if needed
./bin/server-manager deploy my-project      # Deploy the project
./bin/server-manager list                   # List all projects
./bin/server-manager destroy my-project     # Destroy a project
```

The benefits of this structure:
- Modular code organization with separate files for different concerns
- Reusable functions that can be shared across commands
- Project-based structure where each project has its own config
- Template-based approach where core Terraform and Ansible configs are shared
- Simple command-line interface for managing everything
