#!/bin/bash

# Set your GitLab API token and URL
GITLAB_API_TOKEN="YOUR_GITLAB_API_TOKEN"
GITLAB_URL="https://your-gitlab-url.com"  # Replace with your GitLab URL

# Function to get the runner ID by a specific tag
get_runner_id_by_tag() {
    local tag_to_find="$1"
    local runners_info
    runners_info=$(curl --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" "$GITLAB_URL/api/v4/runners")
    local runner_id
    runner_id=$(echo "$runners_info" | jq -r ".[] | select(.tag_list[] | contains(\"$tag_to_find\")) | .id")
    echo "$runner_id"
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
    echo "Usage: $0 <tag_to_find> <new_tags> <action> [replacement_tag]"
    echo "  <tag_to_find>: The existing tag on the runner you want to search for."
    echo "  <new_tags>: A comma-separated list of new tags to add, remove, or replace."
    echo "  <action>: Specify either 'add,' 'remove,' or 'replace' to perform the corresponding action on the runner's tags."
    echo "  [replacement_tag]: (Optional) Specify the replacement tag when using the 'replace' action."
    exit 1
}

# Check for the correct number of command-line arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    display_usage
fi

tag_to_find="$1"
new_tags="$2"
action="$3"

# Validate action input
if [ "$action" != "add" ] && [ "$action" != "remove" ] && [ "$action" != "replace" ]; then
    echo "Error: Invalid action. Please use 'add,' 'remove,' or 'replace'."
    display_usage
fi

runner_id=$(get_runner_id_by_tag "$tag_to_find")

if [ -n "$runner_id" ]; then
    if [ "$action" = "replace" ] && [ "$#" -eq 4 ]; then
        replacement_tag="$4"
        update_runner_tags "$runner_id" "$new_tags" "$action" "$replacement_tag"
    else
        update_runner_tags "$runner_id" "$new_tags" "$action"
    fi
else
    echo "Runner with tag \"$tag_to_find\" not found."
    exit 1
fi




#!/bin/bash

# Set your GitLab API token and URL
GITLAB_API_TOKEN="YOUR_GITLAB_API_TOKEN"
GITLAB_URL="https://your-gitlab-url.com"  # Replace with your GitLab URL

# Function to get project ID by a specific tag
get_project_id_by_runner_tag() {
    local runner_tag="$1"
    local projects_info
    projects_info=$(curl --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" "$GITLAB_URL/api/v4/projects?membership=true")
    local project_id
    project_id=$(echo "$projects_info" | jq -r ".[] | select(.runners_token | contains(\"$runner_tag\")) | .id")
    echo "$project_id"
}

# Function to perform an action on a project
perform_project_action() {
    local project_id="$1"
    local action="$2"

    case "$action" in
        "add")
            # Add your code here to perform the 'add' action on the project with ID $project_id
            echo "Adding action on project $project_id"
            ;;
        "remove")
            # Add your code here to perform the 'remove' action on the project with ID $project_id
            echo "Removing action on project $project_id"
            ;;
        "replace")
            # Add your code here to perform the 'replace' action on the project with ID $project_id
            echo "Replacing action on project $project_id"
            ;;
        *)
            echo "Error: Invalid action. Please use 'add,' 'remove,' or 'replace'."
            exit 1
            ;;
    esac
}

# Display usage information
display_usage() {
    echo "Usage: $0 <runner_tag> <action>"
    echo "  <runner_tag>: The existing tag on the GitLab Runner associated with the project."
    echo "  <action>: Specify either 'add,' 'remove,' or 'replace' to perform the corresponding action on the project."
    exit 1
}

# Check for the correct number of command-line arguments
if [ "$#" -ne 2 ]; then
    display_usage
fi

runner_tag="$1"
action="$2"

# Validate action input
if [ "$action" != "add" ] && [ "$action" != "remove" ] && [ "$action" != "replace" ]; then
    echo "Error: Invalid action. Please use 'add,' 'remove,' or 'replace'."
    display_usage
fi

project_id=$(get_project_id_by_runner_tag "$runner_tag")

if [ -n "$project_id" ]; then
    perform_project_action "$project_id" "$action"
else
    echo "No project found with a GitLab Runner tag \"$runner_tag\"."
    exit 1
fi


