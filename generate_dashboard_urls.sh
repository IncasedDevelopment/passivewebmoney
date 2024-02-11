#!/usr/bin/env bash

# Function to generate dashboard URLs for a given compose project name and device name.
# If the parameters are not provided, it tries to read them from the .env file.
# If the .env file is not found or the parameters are not set, it returns an error.
# The generated dashboard URLs are written to a file named "dashboards_URLs_<compose_project_name>-<device_name>.txt".
# The function uses the "docker ps" command to get the running containers and extract the port information.
# It then writes the URLs to the dashboard file if the port mapping is available.
# The function returns 0 on success and 1 on failure.

generate_dashboard_urls() {
    local compose_project_name=${1:-$(grep -oP 'COMPOSE_PROJECT_NAME=\K[^#\r]+' .env)}
    local device_name=${2:-$(grep -oP 'DEVICE_NAME=\K[^#\r]+' .env)}
    local env_file=".env"
    local dashboard_file

    # Validate if COMPOSE_PROJECT_NAME and DEVICE_NAME are set
    if [[ -z "${compose_project_name}" || -z "${device_name}" ]]; then
        echo "Error: COMPOSE_PROJECT_NAME and DEVICE_NAME must be provided."
        return 1
    fi

    dashboard_file="dashboards_URLs_${compose_project_name}-${device_name}.txt"

    # Get running docker containers and extract port information
    sudo docker ps --format "{{.Ports}} {{.Names}}" | while read -r line; do
        local container_info=${line##* }
        local port_mapping=$(echo "${line}" | awk -F'[0.0.0.0:]|->' '{print $2}')

        if [[ -n "${port_mapping}" ]]; then
            echo "If enabled you can visit the ${container_info} web dashboard on http://localhost:${port_mapping}" >> "${dashboard_file}"
        fi
    done

    echo "Dashboard URLs have been written to ${dashboard_file}"
}

# Call the function with arguments or read from .env
generate_dashboard_urls "$1" "$2"
