#!/bin/bash

# Redirect stdout and stderr to a log file
exec > /var/log/user-data.log 2>&1

# Add codon key to authorized keys file 
SSH_PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSkMc19m28614Rb3sGEXQUN+hk4xGiufU9NYbVXWGVrF1bq6dEnAD/VtwM6kDc8DnmYD7GJQVvXlDzvlWxdpBaJEzKziJ+PPzNVMPgPhd01cBWPv82+/Wu6MNKWZmi74TpgV3kktvfBecMl+jpSUMnwApdA8Tgy8eB0qELElFBu6cRz+f6Bo06GURXP6eAUbxjteaq3Jy8mV25AMnIrNziSyQ7JOUJ/CEvvOYkLFMWCF6eas8bCQ5SpF6wHoYo/iavMP4ChZaXF754OJ5jEIwhuMetBFXfnHmwkrEIInaF3APIBBCQWL5RC4sJA36yljZCGtzOi5Y2jq81GbnBXN3Dsjvo5h9ZblG4uWfEzA2Uyn0OQNDcrecH3liIpowtGAoq8NUQf89gGwuOvRzzILkeXQ8DKHtWBee5Oi/z7j9DGfv7hTjDBQkh28LbSu9RdtPRwcCweHwTLp4X3CYLwqsxrIP8tlGmrVoZZDhMfyy/bGslZp5Bod2wnOMlvGktkHs="
echo "$SSH_PUB_KEY" >> /home/ubuntu/.ssh/authorized_keys

# Install Node Exporter
echo "Installing Node Exporter..."
sudo apt-get update -y
sudo apt-get install -y wget
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.6.0.linux-amd64.tar.gz
sudo mv node_exporter-1.6.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.6.0.linux-amd64*

cat <<EOL | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=ubuntu
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
echo "Node Exporter installed and running."

# Install Docker and Docker Compose
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker --version
echo "Docker installed successfully."

sleep 60

### Post Install Docker Group
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# Log into DockerHub
echo "Logging into DockerHub..."
echo "${docker_pass}" | docker login --username "${docker_user}" --password-stdin || {
  echo "Docker login failed!" >&2
  exit 1
}

# Create docker-compose.yaml and deploy
echo "Setting up Docker Compose..."
mkdir -p /app
cd /app
cat > docker-compose.yml <<EOF
${docker_compose}
EOF
docker compose pull
docker compose up -d --force-recreate
echo "Docker Compose services deployed."

# Cleanup
docker logout
docker system prune -f

echo "Cleanup complete."
