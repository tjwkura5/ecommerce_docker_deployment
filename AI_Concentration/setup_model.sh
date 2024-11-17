#!/bin/bash

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Add codon key to authorized keys file 
SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="
echo "$SSH_PUB_KEY" >> /home/ubuntu/.ssh/authorized_keys

# Add the deadsnakes PPA to get more Python versions
sudo add-apt-repository ppa:deadsnakes/ppa -y

# Install Python 3.9 and venv
sudo apt install python3.9 python3.9-venv python3.9-dev -y

# Install software-properties-common (useful for managing PPAs)
# The suggestion to install the software-properties-common package came from a fellow student
# provides tools to manage software repositories
sudo apt install software-properties-common -y

# Install additional development tools (in case they're needed for Python packages)
sudo apt install build-essential libssl-dev libffi-dev -y

# Create a Python virtual environment in the root of the cloned repository..."
python3.9 -m venv venv 

# Activate the virtual environment
source venv/bin/activate

# Upgrade pip in the virtual environment
pip install --upgrade pip 

pip install pandas numpy scikit-learn