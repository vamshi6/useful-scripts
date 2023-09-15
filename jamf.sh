#!/bin/bash

# Obtain an authentication token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Define your Jamf server URL and invitation code
JAMFURL="YOUR_JAMF_SERVER_URL"
computerInvitation="YOUR_INVITATION_CODE"

# Function to download and install the Jamf binary
jamfinstall() {
  /usr/bin/curl -ks "https://$JAMFURL/bin/jamf" -o /tmp/jamf
  /bin/mkdir -p /usr/local/jamf/bin /usr/local/bin
  /bin/mv /tmp/jamf /usr/local/jamf/bin
  /bin/chmod +x /usr/local/jamf/bin/jamf
  /bin/ln -s /usr/local/jamf/bin/jamf /usr/local/bin
}

# Check if jamf is installed
if ! command -v jamf &>/dev/null; then
  echo 'Jamf is not installed.'
  shouldEnroll=true
else
  # `jamf` command exists, check the connection to the server
  /usr/local/bin/jamf checkJSSConnection -retry 1
  status=$?

  if [ $status -eq 0 ]; then
    # `jamf` command was able to connect to the server correctly, we are already enrolled
    echo 'Already Jamf enrolled.'
    exit 0
  elif [ $status -eq 127 ]; then
    # `jamf` command not found so we are definitely not enrolled.
    echo 'Not already Jamf enrolled.'
    shouldEnroll=true
  else
    # `jamf` command exists, but had some other trouble contacting the server.
    echo 'Encountered a problem connecting to the Jamf server.'
    
    if [[ "$(jamf checkJSSConnection)" == *"Device Signature Error"* ]]; then
      echo 'Instance has likely moved to new physical hardware.'
      
      # Need to unenroll and then enroll as a new device.
      echo "Attempting to run 'jamf removeFramework'..."
      /usr/local/bin/jamf removeFramework
      removeStatus=$?
      
      if [ $removeStatus -eq 0 ]; then
        echo 'Jamf enrollment removed.'
        shouldEnroll=true
      else
        echo "'jamf removeFramework' failed with exit code $removeStatus."
        exit 1
      fi
    else
      echo "Run '/usr/local/bin/jamf checkJSSConnection' manually to troubleshoot."
      exit 1
    fi
  fi
fi

if [ "$shouldEnroll" = true ]; then
  echo 'Attempting to enroll in Jamf Pro...'
  
  # Download binaries from public host
  jamfinstall
  
  # Set the computer name based on instance ID
  instance_id=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
  /usr/local/bin/jamf setComputername --name "$instance_id"
  
  # Run the enrollment
  /usr/local/bin/jamf enroll -invitation "$computerInvitation" -noPolicy
  enrolled=$?
  
  if [ $enrolled -eq 0 ]; then
    /usr/local/bin/jamf update
    /usr/local/bin/jamf policy -event enrollmentComplete
    enrolled=$?
  fi
  
  /bin/rm -rf /private/tmp/Binaries
  exit $enrolled
fi
