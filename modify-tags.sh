#!/bin/bash

# Function to add tags to a GitLab project
add_tags() {
    local project_id="$1"
    local tag="$2"
    local new_tag="$3"

    # Construct the URL for adding tags
    URL="${GITLAB_URL}/api/v4/projects/${project_id}/tag"

    # Prepare JSON data for the API request
    DATA="{\"tag_name\":\"${new_tag}\"}"

    # Make the API request to add the new tag
    response=$(curl --header "PRIVATE-TOKEN: ${TOKEN}" --request POST --data "${DATA}" "${URL}")

    # Check if the request was successful
    if [[ $? -eq 0 && $response == "tag_name" ]]; then
        echo "Tag '$new_tag' added to project $project_id with tag '$tag'"
    else
        echo "Failed to add tag '$new_tag' to project $project_id"
    fi
}

# Function to delete tags from a GitLab project
delete_tags() {
    local project_id="$1"
    local tag="$2"
    local remove_tag="$3"

    # Construct the URL for deleting tags
    URL="${GITLAB_URL}/api/v4/projects/${project_id}/tag/${remove_tag}"

    # Make the API request to delete the tag
    response=$(curl --header "PRIVATE-TOKEN: ${TOKEN}" --request DELETE "${URL}")

    # Check if the request was successful
    if [[ $? -eq 0 && $response == "message" ]]; then
        echo "Tag '$remove_tag' deleted from project $project_id with tag '$tag'"
    else
        echo "Failed to delete tag '$remove_tag' from project $project_id"
    fi
}

# Function to replace tags on a GitLab project
replace_tags() {
    local project_id="$1"
    local tag="$2"
    local old_tag="$3"
    local new_tag="$4"

    # Check if the old tag exists
    if curl --header "PRIVATE-TOKEN: ${TOKEN}" --fail --output /dev/null --silent "${GITLAB_URL}/api/v4/projects/${project_id}/tag/${old_tag}"; then
        # Delete the old tag
        delete_tags "$project_id" "$tag" "$old_tag"
        # Add the new tag
        add_tags "$project_id" "$tag" "$new_tag"
    else
        echo "Old tag '$old_tag' does not exist on project $project_id with tag '$tag'"
    fi
}

# Function to display usage instructions
usage() {
    echo "Usage: $0 [--project-id PROJECT_ID] [--tag TAG] [--add NEW_TAG | --delete REMOVE_TAG | --replace OLD_TAG NEW_TAG]"
    exit 1
}

# Check if there are any arguments
if [[ $# -eq 0 ]]; then
    # Prompt for input if no arguments are provided
    echo "Enter GitLab URL:"
    read GITLAB_URL
    echo "Enter GitLab Token:"
    read TOKEN
    echo "Enter Project ID:"
    read project_id
    echo "Enter Tag:"
    read tag
    echo "Enter Action (add, delete, or replace):"
    read action

    if [[ "$action" == "add" ]]; then
        echo "Enter New Tag:"
        read new_tag
        add_tags "$project_id" "$tag" "$new_tag"
    elif [[ "$action" == "delete" ]]; then
        echo "Enter Tag to Remove:"
        read remove_tag
        delete_tags "$project_id" "$tag" "$remove_tag"
    elif [[ "$action" == "replace" ]]; then
        echo "Enter Old Tag to Replace:"
        read old_tag
        echo "Enter New Tag:"
        read new_tag
        replace_tags "$project_id" "$tag" "$old_tag" "$new_tag"
    else
        usage
    fi
else
    # Process command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-id)
                project_id="$2"
                shift 2
                ;;
            --tag)
                tag="$2"
                shift 2
                ;;
            --add)
                new_tag="$2"
                add_tags "$project_id" "$tag" "$new_tag"
                shift 2
                ;;
            --delete)
                remove_tag="$2"
                delete_tags "$project_id" "$tag" "$remove_tag"
                shift 2
                ;;
            --replace)
                old_tag="$2"
                new_tag="$3"
                replace_tags "$project_id" "$tag" "$old_tag" "$new_tag"
                shift 3
                ;;
            *)
                echo "Invalid argument: $1"
                usage
                ;;
        esac
    done
fi
