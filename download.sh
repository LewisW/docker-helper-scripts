#!/bin/bash

useradd teamcity
gpasswd -a teamcity docker

cd /home/teamcity
curl -O -L https://github.com/LewisW/docker-helper-scripts/archive/0.1.tar.gz
tar -czf 0.1.tar.gz

chown -R teamcity:teamcity docker-helper-scripts
chmod +x docker-helper-scripts/*.sh

mkdir /home/teamcity/.ssh
chown -R teamcity:teamcity /home/teamcity/.ssh
chmod 0700 /home/teamcity/.ssh

#touch /home/teamcity/.ssh/authorized_keys
echo "ssh-rsa __KEY_HERE__" >> /home/teamcity/.ssh/authorized_keys

chmod 0600 /home/teamcity/.ssh/authorized_keys

sudo yum install unzip java-1.7.0-openjdk -y

echo 'teamcity ALL = NOPASSWD: ALL' > /etc/sudoers
