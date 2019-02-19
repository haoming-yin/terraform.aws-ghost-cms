#! /bin/bash

# func to log user data progress into a log file
function log() {
    echo -e "[$(date +%FT%TZ)] $1" >> /usr/assignment/outputs/user_data.out
}

log "Started running user data."

log "Setting up firewall config."
ufw allow ssh
ufw allow http
ufw allow https

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

apt-get -y install python3-pip
pip3 install -r /usr/assignment/qrious-sre-assignment/requirements.txt

log "Finished running user data script."