#!/bin/bash

echo "packer: uninstall Ansible and remove PPA"
apt-get -y -qq remove --purge ansible
apt-add-repository --remove ppa:ansible/ansible
apt-get -y -qq autoremove
apt-get -y -qq clean

echo "packer: delete unneeded files"
rm -f /tmp/ansible/*.sh > /dev/null
rm -rf /tmp/ansible > /dev/null
