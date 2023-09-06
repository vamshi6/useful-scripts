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
