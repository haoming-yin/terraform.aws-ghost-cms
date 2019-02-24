#! /bin/bash

# func to log user data progress into a log file
mkdir -p /usr/outputs
function log() {
    echo -e "[$(date +%FT%TZ)] $1" >> /usr/outputs/user_data.out
}

log "Started running user data."

log "Setting up firewall config."
ufw allow ssh
ufw allow http

ufw --force enable

# install Docker CE
log "Installing docker and its dependencies."
apt-get update
apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
stable"

apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io
apt-get -y install docker-compose
usermod -aG docker ubuntu

# run docker compose
mkdir -p /usr/ghost
cd /usr
git clone https://github.com/haoming-yin/terraform.aws-ghost-cms.git

cd /usr/terraform.aws-ghost-cms
docker-compose build
docker-compose up -d

log "Finished running user data script."