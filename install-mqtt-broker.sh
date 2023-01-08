#!/bin/bash

## GET mqtt service's username and passwrod from input
USERNAME=$1
PASSWORD=$2

## GET host name
HOST_NAME=$3
if [ -z $HOST_NAME ];
then
    HOST_NAME="mqtt-host-"$( tr -cd a-z </dev/urandom | head -c '4' ; echo '' )
fi

## Topic name
TOPIC_NAME=$4
if [ -z $TOPIC_NAME ];
then
    TOPIC_NAME="topic1"
fi

## GET IP
SYSTEM_IP=$5
if [ -z $SYSTEM_IP ];
then
    SYSTEM_IP=$(curl -s "https://api.ipify.org/" )
fi

## Check for docker
docker --version
if [ $? -ne 0 ]
then
    curl -fsSL https://get.docker.com | sh
fi

## Clear previous folders and stop the containers
sudo docker stop mosquitto-ssl || true
sudo docker rm mosquitto-ssl || true
sudo rm -rf ./config
sudo rm -rf ./data
sudo rm -rf ./log
sudo rm -rf ./client

## Create config and data folders
mkdir -p ./config/certs
mkdir -p ./data
mkdir -p ./log
mkdir -p ./client
touch ./config/passwordfile

## Add host name
sudo bash -c "echo \"$SYSTEM_IP $HOST_NAME\" >> /etc/hosts"

##
SUBJECT_CA="/C=SE/ST=Stockholm/L=Stockholm/O=himinds/OU=CA/CN=$HOST_NAME"
SUBJECT_SERVER="/C=SE/ST=Stockholm/L=Stockholm/O=himinds/OU=Server/CN=$HOST_NAME"
SUBJECT_CLIENT="/C=SE/ST=Stockholm/L=Stockholm/O=himinds/OU=Client/CN=$HOST_NAME"

function generate_CA () {
    echo "$SUBJECT_CA"
    openssl req -x509 -nodes -sha256 -newkey rsa:2048 -subj "$SUBJECT_CA"  -days 365 -keyout ca.key -out ca.crt
}

function generate_server () {
    echo "$SUBJECT_SERVER"
    openssl req -nodes -sha256 -new -subj "$SUBJECT_SERVER" -keyout server.key -out server.csr
    openssl x509 -req -sha256 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365
}

function generate_client () {
    echo "$SUBJECT_CLIENT"
    openssl req -new -nodes -sha256 -subj "$SUBJECT_CLIENT" -out client.csr -keyout client.key
    openssl x509 -req -sha256 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365
}

## Generate certificate files
cd ./config/certs
generate_CA
generate_server
generate_client
cd ../..

## Write acl file
cat <<EOF > ./config/acl
# This only affects clients with the username "userX".
user $USERNAME
topic read $TOPIC_NAME
topic write $TOPIC_NAME
EOF

## Write config file
cat <<EOF > ./config/mosquitto.conf
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

listener 8883

cafile /mosquitto/config/certs/ca.crt
certfile /mosquitto/config/certs/server.crt
keyfile /mosquitto/config/certs/server.key

require_certificate true
use_identity_as_username false

allow_anonymous false
password_file /mosquitto/config/passwordfile

acl_file /mosquitto/config/acl
EOF

## Run MQTT Broker inside docker
sudo docker run -d --restart always \
	-p 8883:8883 \
	--name mosquitto-ssl \
	--mount src=$PWD/config,target=/mosquitto/config,type=bind \
	--mount src=$PWD/data,target=/mosquitto/data,type=bind \
	--mount src=$PWD/log,target=/mosquitto/log,type=bind \
	eclipse-mosquitto

## Generate password file
cmd_str="sudo docker exec --tty mosquitto-ssl sh -c 'touch passwordfile; mosquitto_passwd -b passwordfile $USERNAME $PASSWORD; mv passwordfile mosquitto/config/; eval "$(exit 0)";'"
eval $cmd_str

## Enable passwordfile
sudo docker restart mosquitto-ssl

## Generate log and client folders to use in client side
sudo cp ./config/certs/ca.crt ./client/ca.crt
sudo cp ./config/certs/client.crt ./client/client.crt
sudo cp ./config/certs/client.key ./client/client.key
sudo chown -R $USER:$USER ./client/

cat <<EOF > ./config.log
    =========================================================
    Host : mqtts://$HOST_NAME
    Port : 8883
    Username : $USERNAME
    Password : $PASSWORD
    SSL/TLS : true
    Certificate : self signed
    SSL Secure : checked
    CA File : ./client/ca.crt
    Client Certificate File : ./client/client.crt
    Client key file : ./client/client.key
    Topic name : $TOPIC_NAME

    if you run this script in your server, you should add the $HOST_NAME to your local hosts (local PC)
    for ubuntu run following command :
    sudo bash -c "echo \"$SYSTEM_IP $HOST_NAME\" >> /etc/hosts"
    =========================================================
EOF

cat ./config.log



