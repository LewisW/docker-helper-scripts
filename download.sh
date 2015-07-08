#!/bin/bash

TUNNEL=
APT_CACHER=TEAMCITY=DOCKER=
OAUTH_KEY=
PUBLIC_KEY=

useradd teamcity
gpasswd -a teamcity docker

yum install unzip java-1.7.0-openjdk php php-cli git jq nc.x86_64 -y

cd /home/teamcity
git clone https://github.com/LewisW/docker-helper-scripts.git docker-scripts
#curl -O -L https://github.com/LewisW/docker-helper-scripts/archive/0.1.tar.gz
#tar -czf 0.1.tar.gz

chown -R teamcity:teamcity docker-scripts
chmod +x docker-scripts/*.sh

mkdir /home/teamcity/.ssh

#touch /home/teamcity/.ssh/authorized_keys
echo "ssh-rsa $PUBLIC_KEY" >> /home/teamcity/.ssh/authorized_keys

chown -R teamcity:teamcity /home/teamcity/.ssh
chmod 0700 /home/teamcity/.ssh
chmod 0600 /home/teamcity/.ssh/authorized_keys

curl https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
# Run as teamcity:
composer config -g github-oauth.github.com $OAUTH_KEY

# Put tunnel private key in /etc/ssh/id_rsa

echo "ssh -i /etc/ssh/id_rsa -f tunnel@$TUNNEL -L 8111:$TEAMCITY:8111 -L 5000:$TEAMCITY:5000 -L 3142:$APT_CACHER:3142 -N" >> /etc/rc.local
echo "cd /home/teamcity/docker-scripts/ && git reset --hard HEAD && git pull && chown -R teamcity:teamcity . && chmod +x ./*.sh" >> /etc/rc.local
echo "curl localhost:5000/v2/build/tags/list  | jq -r '.tags | join("\n")' | xargs -I {} docker pull localhost:5000/build:{}" >> /etc/rc.local

echo "127.0.0.1 $APT_CACHER $TEAMCITY $DOCKER" >> /etc/hosts
echo "teamcity ALL = NOPASSWD: ALL" >> /etc/sudoers
