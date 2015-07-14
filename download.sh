#!/bin/bash -xe

set -xe

#TUNNEL="{{user `tunnel_server`}}"
#TUNNEL_KEY="{{user `tunnel_key`}}"
#APT_CACHER="{{user `apt_cacher_server`}}"
#DOCKER="{{user `docker_server`}}"
#TEAMCITY="{{user `teamcity_server`}}"
#OAUTH_KEY="{{user `composer_oauth_key`}}"
#PUBLIC_KEY="{{user `public_key`}}"

ssh-keyscan -H $TUNNEL > /etc/ssh/ssh_known_hosts

# Format the drive for direct-lvm devicemapper
curl -O https://gist.githubusercontent.com/ambakshi/ddebac9148b4aea36446/raw/3954d97f367c05d41ae70791767afb74f65360d0/docker-direct-lvm.sh
chmod +x docker-direct-lvm.sh
./docker-direct-lvm.sh /dev/xvdb

yum update -y
yum install docker unzip java-1.7.0-openjdk php php-cli git jq nc.x86_64 -y

# Configure docker for the direct-lvm
#echo "--storage-opt dm.datadev=/dev/direct-lvm/data --storage-opt dm.metadatadev=/dev/direct-lvm/metadata" > /etc/sysconfig/docker

cat <<EOT > /etc/bashrc
export EC2_BASE=/opt/ec2
export EC2_HOME=\$EC2_BASE/tools
export PATH=\$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:\$EC2_HOME/bin
EOT
 
source /etc/bashrc

mkdir -p $EC2_HOME
curl -o /tmp/ec2-api-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
curl -o /tmp/ec2-ami-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip

unzip /tmp/ec2-api-tools.zip -d /tmp
unzip /tmp/ec2-ami-tools.zip -d /tmp

cp -r /tmp/ec2-api-tools-*/* $EC2_HOME
cp -rf /tmp/ec2-ami-tools-*/* $EC2_HOME

echo $EC2_HOME

ls -al $EC2_HOME/bin

useradd teamcity
gpasswd -a teamcity docker

chkconfig docker on

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

curl https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer
# Run as teamcity:
sudo -u teamcity /usr/local/bin/composer config -g github-oauth.github.com $OAUTH_KEY

# Put tunnel private key in /etc/ssh/id_rsa
#echo "$TUNNEL_KEY" > /etc/ssh/id_rsa
mv /tmp/id_rsa /etc/ssh/id_rsa
chmod 400 /etc/ssh/id_rsa

echo "ssh -i /etc/ssh/id_rsa -f tunnel@$TUNNEL -L 8111:$TEAMCITY:8111 -L 5000:$TEAMCITY:5000 -L 3142:$APT_CACHER:3142 -N" >> /etc/rc.local
echo "cd /home/teamcity/docker-scripts/ && git reset --hard HEAD && git pull && chown -R teamcity:teamcity . && chmod +x ./*.sh" >> /etc/rc.local
echo "curl localhost:5000/v2/build/tags/list  | jq -r '.tags | join(\"\\n\")' | xargs -I {} docker pull localhost:5000/build:{} || true" >> /etc/rc.local

echo "127.0.0.1 $APT_CACHER $TEAMCITY $DOCKER" >> /etc/hosts
echo "teamcity ALL = NOPASSWD: ALL" >> /etc/sudoers

sudo sed -i -r 's/Defaults\s+(requiretty|!visiblepw)/#\0/' /etc/sudoers

#As teamcity
service docker start

# Predownload the images
sudo -u teamcity docker pull lewisw/selenium:latest
sudo -u teamcity docker pull lewisw/docker-test-runner

#/etc/rc.local
