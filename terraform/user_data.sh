#! /bin/bash

# func to log user data progress into a log file
function log() {
    echo -e "[$(date +%FT%TZ)] $1" >> /var/log/user_data.log
}

function instance_metadata() {
    ## Get Some Instance Metadeets
    INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)";
    LOCAL_HOSTNAME="$(curl http://169.254.169.254/latest/meta-data/local-hostname)";
    AVAILABILITY_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`;
    AWS_REGION="`echo \"$AVAILABILITY_ZONE\" | sed 's/[a-z]$//'`";
    ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`
}

function config_firewall() {
    log "Setting up firewall config."
    ufw allow ssh
    ufw allow http
    ufw --force enable
}

function get_parameter() {
    json=$(aws ssm get-parameters --names $1 --with-decryption)
    parameter=$(echo $json | python -c "import sys, json; print json.load(sys.stdin)['Parameters'][0]['Value']")
    echo "$parameter"
}

function install_docker() {
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
}

function get_db_host() {
    arns=$(aws rds describe-db-instances --query "DBInstances[].DBInstanceArn" --output text)
    for arn in $arns; do
        tags=$(aws rds list-tags-for-resource --resource-name "$arn" --query "TagList[]")
        is_match=$(echo $tags | python3 -c "import sys, json; print('true' if any([t['Value'] == 'terraform.aws-rds' for t in json.load(sys.stdin)]) else 'false')")
        if [[ "$is_match" == "true" ]]; then
            echo $(aws rds describe-db-instances --filter Name=db-instance-id,Values=$arn --query "DBInstances[].Endpoint.Address" --output text)
            break
        fi
    done
}

function install_ghost() {
    mkdir -p /usr/ghost
    DB_HOST=$(get_db_host)
    DB_PASSWORD=$(get_parameter "/db/password")
    
    cat > /etc/systemd/system/ghost.service <<END
[Unit]
Description=Ghost CMS
After=docker.service
Requires=docker.service
[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull ghost:2-alpine
ExecStart=/usr/bin/docker run \\
                                -e "url=https://haomingyin.com" \\
                                -e "database__client=mysql" \\
                                -e "database__connection__host=$DB_HOST" \\
                                -e "database__connection__user=root" \\ 
                                -e "database__connection__password=$DB_PASSWORD" \\
                                -e "database__connection__database=host" \\
                                -e "database__connection__port=3306" \\
                                -v /usr/ghost/content:/var/lib/ghost/content \\
                                --name %n \\
                                -p 2368:2369 \\
                                ghost:2-alpine 
ExecStop=/usr/bin/docker stop %n
[Install]
WantedBy=multi-user.target
END

}

function install_nginx-ghost() {
    cat > /etc/systemd/system/nginx-ghost.service <<END
[Unit]
Description=Nginx that serves Ghost CMS
After=docker.service
Requires=docker.service
[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker build -t nginx https://github.com/haoming-yin/terraform.aws-ghost-cms.git#:nginx
ExecStart=/usr/bin/docker run \\
                                --name %n \\
                                --network=host \\
                                nginx
ExecStop=/usr/bin/docker stop %n
[Install]
WantedBy=multi-user.target
END 

}

function install_ddns-cloudflare() {
    X_AUTH_EMAIL=$(get_parameter "/cloudflare/email")
    X_AUTH_KEY=$(get_parameter "/cloudflare/key")

    cat > /etc/systemd/system/ddns-cloudflare.service <<END
[Unit]
Description=DDNS Cloudflare
After=docker.service
Requires=docker.service
[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker build -t ddns-cloudflare https://github.com/haoming-yin/script.ddns-cloudflare.git
ExecStart=/usr/bin/docker run \\
                                -e "DDNS_PROFILE=ghost" \\
                                -e "X_AUTH_EMAIL=$X_AUTH_EMAIL" \\
                                -e "X_AUTH_KEY=$X_AUTH_KEY" \\
                                --name %n \\
                                ddns-cloudflare
ExecStop=/usr/bin/docker stop %n
[Install]
WantedBy=multi-user.target
END 

}

log "Started running user data."
config_firewall
install_docker

install_ghost
service ghost start 

install_nginx-ghost
service nginx-ghost start

install_ddns-cloudflare
service ddns-cloudflare start

log "Finished running user data script."