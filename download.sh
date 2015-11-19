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
echo "ServerAliveInterval 180" >> /etc/ssh/ssh_config

#sed -i.dist 's,universe$,universe multiverse,' /etc/apt/sources.list
#echo "deb http://ftp.us.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list


apt-get update -y
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install ruby1.9.3
apt-get install unzip lvm2 xfsprogs openjdk-7-jdk php5-cli php5-readline git jq ruby-full kpartx -y

# ec2-bundle-vol requires legacy grub and there should be no console setting
apt-get -y install grub
sed -i 's/console=hvc0/console=ttyS0/' /boot/grub/menu.lst
# the above is sufficient to fix 12.04 but 14.04 also needs the following
sed -i 's/LABEL=UEFI.*//' /etc/fstab

curl -sSL https://get.docker.com/ | sh

# Format the drive for direct-lvm devicemapper
sudo curl -o /usr/local/bin/docker-direct-lvm https://gist.githubusercontent.com/LewisW/75f1f0bee9858384ad1c/raw/docker-direct-lvm.sh
chmod +x /usr/local/bin/docker-direct-lvm
#sudo curl -o /usr/local/bin/docker-direct-lvm https://gist.githubusercontent.com/LewisW/75f1f0bee9858384ad1c/raw/docker-direct-lvm.sh
#git clone https://github.com/LewisW/docker-storage-setup.git /usr/lib/docker-storage-setup/
#chmod +x /usr/lib/docker-storage-setup/*.sh

# Stop docker
service docker stop
# Remove /var/lib/docker so we can create the drive later
rm -fr /var/lib/docker
# Remove the mount from fstab
sudo sed -i 's/\/dev\/xvdb/#\/dev\/xvdb/' /etc/fstab 
sudo umount /dev/xvdb

# Configure docker for the direct-lvm
#echo "--storage-opt dm.datadev=/dev/direct-lvm/data --storage-opt dm.metadatadev=/dev/direct-lvm/metadata" > /etc/sysconfig/docker

export EC2_BASE=/opt/ec2
export EC2_HOME=$EC2_BASE/tools
export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$EC2_HOME/bin

mkdir -p $EC2_HOME
curl -o /tmp/ec2-api-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
curl -o /tmp/ec2-ami-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip

unzip /tmp/ec2-api-tools.zip -d /tmp
unzip /tmp/ec2-ami-tools.zip -d /tmp

cp -r /tmp/ec2-api-tools-*/* $EC2_HOME
cp -rf /tmp/ec2-ami-tools-*/* $EC2_HOME

useradd -d /home/teamcity -m teamcity
gpasswd -a teamcity docker
echo "teamcity ALL = NOPASSWD: ALL" >> /etc/sudoers

#chkconfig docker on

cd /home/teamcity
git clone https://github.com/LewisW/docker-helper-scripts.git docker-scripts

chown -R teamcity:teamcity docker-scripts
chmod +x docker-scripts/*.sh

mkdir /home/teamcity/.ssh

#touch /home/teamcity/.ssh/authorized_keys
echo "ssh-rsa $PUBLIC_KEY" >> /home/teamcity/.ssh/authorized_keys
echo "127.0.0.1 $APT_CACHER $TEAMCITY $DOCKER" >> /etc/hosts

chown -R teamcity:teamcity /home/teamcity/.ssh
chmod 0700 /home/teamcity/.ssh
chmod 0600 /home/teamcity/.ssh/authorized_keys

curl https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer

ls -al /home/teamcity

# Run as teamcity:
sudo -H -u teamcity /usr/local/bin/composer config -g github-oauth.github.com $OAUTH_KEY

# Download the root certificate
mkdir -p /usr/local/share/ca-certificates/alphassl.org
cat <<EOF > /usr/local/share/ca-certificates/alphassl.org/alphassl_intermediate.crt
-----BEGIN CERTIFICATE-----
MIIETTCCAzWgAwIBAgILBAAAAAABRE7wNjEwDQYJKoZIhvcNAQELBQAwVzELMAkG
A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jv
b3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xNDAyMjAxMDAw
MDBaFw0yNDAyMjAxMDAwMDBaMEwxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
YWxTaWduIG52LXNhMSIwIAYDVQQDExlBbHBoYVNTTCBDQSAtIFNIQTI1NiAtIEcy
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2gHs5OxzYPt+j2q3xhfj
kmQy1KwA2aIPue3ua4qGypJn2XTXXUcCPI9A1p5tFM3D2ik5pw8FCmiiZhoexLKL
dljlq10dj0CzOYvvHoN9ItDjqQAu7FPPYhmFRChMwCfLew7sEGQAEKQFzKByvkFs
MVtI5LHsuSPrVU3QfWJKpbSlpFmFxSWRpv6mCZ8GEG2PgQxkQF5zAJrgLmWYVBAA
cJjI4e00X9icxw3A1iNZRfz+VXqG7pRgIvGu0eZVRvaZxRsIdF+ssGSEj4k4HKGn
kCFPAm694GFn1PhChw8K98kEbSqpL+9Cpd/do1PbmB6B+Zpye1reTz5/olig4het
ZwIDAQABo4IBIzCCAR8wDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8C
AQAwHQYDVR0OBBYEFPXN1TwIUPlqTzq3l9pWg+Zp0mj3MEUGA1UdIAQ+MDwwOgYE
VR0gADAyMDAGCCsGAQUFBwIBFiRodHRwczovL3d3dy5hbHBoYXNzbC5jb20vcmVw
b3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxzaWdu
Lm5ldC9yb290LmNybDA9BggrBgEFBQcBAQQxMC8wLQYIKwYBBQUHMAGGIWh0dHA6
Ly9vY3NwLmdsb2JhbHNpZ24uY29tL3Jvb3RyMTAfBgNVHSMEGDAWgBRge2YaRQ2X
yolQL30EzTSo//z9SzANBgkqhkiG9w0BAQsFAAOCAQEAYEBoFkfnFo3bXKFWKsv0
XJuwHqJL9csCP/gLofKnQtS3TOvjZoDzJUN4LhsXVgdSGMvRqOzm+3M+pGKMgLTS
xRJzo9P6Aji+Yz2EuJnB8br3n8NA0VgYU8Fi3a8YQn80TsVD1XGwMADH45CuP1eG
l87qDBKOInDjZqdUfy4oy9RU0LMeYmcI+Sfhy+NmuCQbiWqJRGXy2UzSWByMTsCV
odTvZy84IOgu/5ZR8LrYPZJwR2UcnnNytGAMXOLRc3bgr07i5TelRS+KIz6HxzDm
MTh89N1SyvNTBCVXVmaU6Avu5gMUTu79bZRknl7OedSyps9AsUSoPocZXun4IRZZ
Uw==
-----END CERTIFICATE-----
EOF
update-ca-certificates

# Put tunnel private key in /etc/ssh/id_rsa
#echo "$TUNNEL_KEY" > /etc/ssh/id_rsa
mv /tmp/id_rsa /etc/ssh/id_rsa
chmod 400 /etc/ssh/id_rsa
#ssh -i /etc/ssh/id_rsa -f tunnel@$TUNNEL -L 8443:$TEAMCITY:8443 -N

# Download the
#wget https://$TEAMCITY:8443/update/buildAgent.zip -P /home/teamcity/BuildAgent
#unzip /home/teamcity/BuildAgent/buildAgent.zip -d /home/teamcity/BuildAgent/
#chown -R teamcity:teamcity /home/teamcity/BuildAgent
#ls -al /home/teamcity/BuildAgent/
#chmod +x /home/teamcity/BuildAgent/bin/*.sh

#cp /home/teamcity/BuildAgent/conf/buildAgent.dist.properties /home/teamcity/BuildAgent/conf/buildAgent.properties
#sed -i -r 's/serverUrl=http:\/\/localhost:8111\//serverUrl=https:\/\/$TEAMCITY:8443/' /home/teamcity/BuildAgent/conf/buildAgent.properties


cat <<EOF > /etc/rc.local
    # send stderr to a log file
    exec 2> /var/log/rc.local.log
    # send stdout to the same log file
    exec 1>&2

    # tell sh to display commands before execution
    set -x

    # Tunnel to our office server
    ssh -i /etc/ssh/id_rsa -f tunnel@$TUNNEL -L 8111:$TEAMCITY:8111 -L 8443:$TEAMCITY:8443 -L 8080:$TEAMCITY:8080 -L 5000:$TEAMCITY:5000 -L 9000:$TEAMCITY:9000 -L 3142:$APT_CACHER:3142 -N

    umount /dev/xvdb
    /usr/local/bin/docker-direct-lvm /dev/xvdb

    # Self update the helper scripts
    cd /home/teamcity/docker-scripts/ && git reset --hard HEAD && git pull && chown -R teamcity:teamcity . && chmod +x ./*.sh

    # Pre-download the basic images
    docker pull lewisw/selenium-stable:latest

    # Download the latest tags for each product
    curl -s localhost:5000/v2/build/tags/list | jq -r '@sh "\(.tags)"' | xargs -n 1 | xargs -I '{}' -t docker pull localhost:5000/build:{}
EOF

#   # tell sh to display commands before execution
#    set -x
#
#    # Create the LVM drives
#    service docker stop || true
#    umount /dev/xvdb || /bin/true
#    rm -fr /var/lib/docker/devicemapper
#
#    (
#        set -a
#        set -x
#        . /usr/lib/docker-storage-setup/docker-storage-setup.conf
#        export VG="docker-storage"
#        export DEVS="/dev/xvdb"
#        /usr/lib/docker-storage-setup/docker-storage-setup.sh
#        set +a
#    )
#    echo 'DOCKER_OPTS="$DOCKER_OPTS --storage-driver=devicemapper --storage-opt dm.thinpooldev=docker--storage-docker--pool-tpool --storage-opt dm.fs=xfs --storage-opt dm.blocksize=512K"' | tee -a /etc/default/docker
#    service docker start

sudo sed -i -r 's/Defaults\s+(requiretty|!visiblepw)/#\0/' /etc/sudoers

lsblk
df -h
sudo cat /etc/fstab
