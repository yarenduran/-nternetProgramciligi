#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")

github_token=$(echo "$2")



#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "


  echo " "
  echo "--> $2"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Configure timezone"
timedatectl set-timezone ${timezone} --no-ask-password

info "Prepare root password for MySQL"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
echo "Done!"
info "Update OS software"
apt-get update
apt-get upgrade -y
info "Install additional software"
apt-get install -y mariadb-server mariadb-client apache2 php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-curl php7.0-gd php7.0-intl php-pear php-imagick php7.0-imap php7.0-mcrypt php-memcache php7.0-pspell php7.0-recode php7.0-sqlite3 php7.0-tidy php7.0-xmlrpc php7.0-xsl php7.0-mbstring php-gettext git nano unzip curl
apt-get -y install phpmyadmin --no-install-recommends
apt-get clean
info "Configure MariaDB"
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"
info "Configure apache2"
sed -i 's/user www-data/user vagrant/g' /etc/apache2/apache2.conf
sed -i 's/group www-data/group vagrant/g' /etc/apache2/apache2.conf
sed -i 's/owner www-data/owner vagrant/g' /etc/apache2/apache2.conf
echo "Done!"
info "Enabling site configuration"
rm -rf /etc/apache2/sites-enabled/
ln -s /vagrant/apache2 /etc/apache2/sites-enabled
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
sed -i '/AllowNoPassword/s/^    \/\///g' /etc/phpmyadmin/config.inc.php
echo "Done!"
a2enmod php7.0
a2enmod rewrite
info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE portal"
echo "Done!"
info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer config --global github.oauth.github.com ${github_token}