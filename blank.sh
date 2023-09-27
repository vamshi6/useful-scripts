#!/bin/bash

# Check if the script is being run with root (sudo) privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit 1
fi

# Replace 'USERNAME' with the actual username you want to enable auto login for
USERNAME="your_username_here"

# Enable auto login for the specified user using 'sed' to edit the file
sudo sed -i '' "/${USERNAME}:*/d" /etc/kcpassword
echo "${USERNAME}:*" | sudo tee -a /etc/kcpassword > /dev/null

# Add the specified user to the AutoLoginUser list
sudo defaults write /Library/Preferences/com.apple.loginwindow AutoLoginUser "$USERNAME"

echo "Auto login has been enabled for the user: $USERNAME"
