#!/bin/bash

echo "packer: install Ansible"
apt-get install -yq update
apt-get install -yq software-properties-common
apt-add-repository ppa:ansible/ansible
apt-get -yq update
apt-get install -yq ansible
