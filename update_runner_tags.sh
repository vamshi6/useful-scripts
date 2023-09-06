#!/bin/bash

# Function to get project ID by a specific tag
get_project_id_by_runner_tag() {
    local runner_tag="$1"
    local projects_info
    projects_info=$(curl --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" "$GITLAB_URL/api/v4/projects?membership=true")
    local project_id
    project_id=$(echo "$projects_info" | jq -r ".[] | select(.runners_token | contains(\"$runner_tag\")) | .id")
    echo "$project_id"
}

# Function to add, remove, or replace tags for a runner
update_runner_tags() {
    local runner_id="$1"
    local new_tags="$2"
    local action="$3"
    local current_tags
    current_tags=$(curl --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" "$GITLAB_URL/api/v4/runners/$runner_id" | jq -r '.tag_list[]')

    if [ "$action" = "add" ]; then
        new_tags=$(echo "$new_tags" | tr ',' '\n' | grep -vFxf <(echo "$current_tags") | paste -sd, -)
    elif [ "$action" = "remove" ]; then
        new_tags=$(echo "$current_tags" | tr ',' '\n' | grep -vFxf <(echo "$new_tags") | paste -sd, -)
    elif [ "$action" = "replace" ]; then
        new_tags="$2"  # Use the second argument as the replacement tag
    else
        echo "Error: Invalid action. Please use 'add,' 'remove,' or 'replace'."
        display_usage
    fi

    curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
        --data-urlencode "tag_list=$new_tags" "$GITLAB_URL/api/v4/runners/$runner_id"

    echo "Tags updated successfully: $new_tags"
}

# Display usage information
display_usage() {
    echo "Usage: $0 <runner_tag> <new_tags> <action> [replacement_tag] [environment]"
    echo "  <runner_tag>: The existing tag on the runner you want to search for."
    echo "  <new_tags>: A comma-separated list of new tags to add, remove, or replace."
    echo "  <action>: Specify either 'add,' 'remove,' or 'replace' to perform the corresponding action on the runner's tags."
    echo "  [replacement_tag]: (Optional) Specify the replacement tag when using the 'replace' action."
    echo "  [environment]: (Optional) Specify 'test' or 'prod' to determine the project ID and GitLab configuration based on the environment."
    exit 1
}

# Check for the correct number of command-line arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    display_usage
fi

runner_tag="$1"
new_tags="$2"
action="$3"
environment="$4"

# Validate action input
if [ "$action" != "add" ] && [ "$action" != "remove" ] && [ "$action" != "replace" ]; then
    echo "Error: Invalid action. Please use 'add,' 'remove,' or 'replace'."
    display_usage
fi

# Function to set GitLab API token and URL based on environment
set_gitlab_config_by_environment() {
    local env="$1"
    case "$env" in
        "test")
            GITLAB_API_TOKEN="TEST_API_TOKEN"
            GITLAB_URL="https://test-gitlab-url.com"
            ;;
        "prod")
            GITLAB_API_TOKEN="PROD_API_TOKEN"
            GITLAB_URL="https://prod-gitlab-url.com"
            ;;
        *)
            echo "Error: Invalid environment. Please specify 'test' or 'prod'."
            exit 1
            ;;
    esac
}

# Determine the project ID, GitLab API token, and GitLab URL based on the environment
if [ -n "$environment" ]; then
    set_gitlab_config_by_environment "$environment"
else
    echo "Warning: No environment specified. Using default configuration."
fi

# Get the project ID based on the runner tag
project_id=$(get_project_id_by_runner_tag "$runner_tag")

if [ -n "$project_id" ]; then
    runner_id=$(get_runner_id_by_runner_tag "$runner_tag")

    if [ -n "$runner_id" ]; then
        if [ "$action" = "replace" ] && [ "$#" -eq 5 ]; then
            replacement_tag="$5"
            update_runner_tags "$runner_id" "$new_tags" "$action" "$replacement_tag"
        else
            update_runner_tags "$runner_id" "$new_tags" "$action"
        fi
    else
        echo "Runner with tag \"$runner_tag\" not found."
        exit 1
    fi
else
    echo "No project found with a GitLab Runner tag \"$runner_tag\"."
    exit 1
fi
