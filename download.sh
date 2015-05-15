#!/bin/bash

useradd teamcity
gpasswd -a teamcity docker

yum install unzip java-1.7.0-openjdk php php-cli git -y

cd /home/teamcity
git clone https://github.com/LewisW/docker-helper-scripts.git docker-helper-scripts
#curl -O -L https://github.com/LewisW/docker-helper-scripts/archive/0.1.tar.gz
#tar -czf 0.1.tar.gz

chown -R teamcity:teamcity docker-helper-scripts
chmod +x docker-helper-scripts/*.sh

mkdir /home/teamcity/.ssh

#touch /home/teamcity/.ssh/authorized_keys
echo "ssh-rsa __KEY_HERE__" >> /home/teamcity/.ssh/authorized_keys

chown -R teamcity:teamcity /home/teamcity/.ssh
chmod 0700 /home/teamcity/.ssh
chmod 0600 /home/teamcity/.ssh/authorized_keys

curl https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

echo 'teamcity ALL = NOPASSWD: ALL' >> /etc/sudoers
