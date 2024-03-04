#! /bin/bash

set -e

apt update

while [[ $(ps aux | grep -i apt | wc -l) != 1 ]]; do
	echo 'apt is locked by another process.'
	sleep 15
	ps aux | grep -i apt | wc -l
done

echo 'apt is free. Let`s continue.'

apt install -y ruby-full ruby-bundler build-essential git
