#!/bin/bash

# Get the current hostname and convert it to lowercase
hostname=$(hostname | tr '[:upper:]' '[:lower:]')

# Check if the lowercase hostname starts with "dev"
if [[ $hostname == dev* ]]; then
    jamfurl="dev_host"
    invitation_code="dev_code"
    
    # Usage for dev environment
    echo "Running in DEV environment."
    echo "JAMF URL: $jamfurl"
    echo "Invitation Code: $invitation_code"
    
# Check if the lowercase hostname starts with "prod"
elif [[ $hostname == prod* ]]; then
    variable1="prod_var1"
    variable2="prod_var2"
    
    # Usage for prod environment
    echo "Running in PROD environment."
    echo "Variable 1: $variable1"
    echo "Variable 2: $variable2"
    
# Check if the lowercase hostname starts with "test"
elif [[ $hostname == test* ]]; then
    variableA="test_varA"
    variableB="test_varB"
    
    # Usage for test environment
    echo "Running in TEST environment."
    echo "Variable A: $variableA"
    echo "Variable B: $variableB"
    
# If the hostname doesn't match any pattern
else
    echo "Hostname does not match any known environment."
fi

# You can use the defined variables as needed below this point.
