#! /bin/bash

set -e

apt update

while [[ $(ps aux | grep -i apt | wc -l) != 1 ]]; do
	echo 'apt is locked by another process.'
	sleep 15
	ps aux | grep -i apt | wc -l
done

echo 'apt is free. Let`s continue.'

apt install gnupg curl -y
curl -fsSL https://pgp.mongodb.com/server-4.4.asc | gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt update
apt install mongodb-org -y
systemctl start mongod
systemctl enable mongod
