#!/bin/bash


# DEBUG - Travis-ci
TRAVIS=$1


# Variables
DBHOST=localhost
DBNAME=cppcms
DBUSER=root
DBPASSWD=vagrant


if [[ -z "${TRAVIS}" ]]; then

  echo -e "\n--- Processing server installation ---\n"

  APTGET="sudo apt-get -y -q=9"

  echo -e "\n--- Linux update ---\n"

else

  echo -e "\n--- Processing travis installation ---\n"

  export DEBIAN_FRONTEND=noninteractive

  mkdir ~/www

  APTGET="sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confnew\""

  echo -e "\n--- Travis linux update ---\n"

fi



echo -e "\n--- Processing server installation ---\n"

echo -e "\n--- Linux update ---\n"
eval $APTGET update
eval $APTGET upgrade

echo -e "\n--- Binaries (git, build-essential, valgrind, gdb ...) ---\n"
eval $APTGET install git build-essential gcc g++ gdb valgrind cmake libpcre3-dev zlib1g-dev libgcrypt11-dev libicu-dev python

echo -e "\n--- MySQL ---\n"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
eval $APTGET install mysql-server

echo -e "\n--- Apache2 & PHP5 ---\n"
eval $APTGET apache2-mpm-prefork apache2 php5-common libapache2-mod-php5 php5-cli php5-mysql

echo -e "\n--- PHPMyAdmin ---\n"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
eval $APTGET install phpmyadmin

echo -e "\n--- Setting up our MySQL user and db ---\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'127.0.0.1';"
mysql -uroot -p$DBPASSWD -e "FLUSH PRIVILEGES;"

echo -e "\n--- IP Tables ---\n"
echo "*filter

-P INPUT DROP
-P FORWARD ACCEPT
-P OUTPUT ACCEPT

-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -p igmp -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport ssh -j ACCEPT
-A INPUT -p tcp --dport http -j ACCEPT
-A INPUT -p tcp --dport https -j ACCEPT

# CPPCMS
-A INPUT -p tcp --dport 8080 -j ACCEPT

-A INPUT -j LOG --log-prefix \"paquet IPv4 inattendu\"

# /!\ WARNING
# /!\ WARNING - NEVER USE THIS RULE ON PRODUCTION SERVER
# /!\ WARNING - (Note change it with : -A INPUT -j REJECT)
# /!\ WARNING
-I INPUT -j ACCEPT

COMMIT

*nat
COMMIT

*mangle
COMMIT" > /home/vagrant/iptables.up.rules
sudo cp /home/vagrant/iptables.up.rules /etc/iptables.up.rules
sudo iptables-restore < /etc/iptables.up.rules

echo -e "\n--- Web server directory ---\n"

rm -rf /var/www
cd /home/vagrant
sudo ln -s /home/vagrant/www /var/www
sudo chown vagrant:vagrant -R /home/vagrant/www
cd /home/vagrant/www

echo "<?php phpinfo(); ?>" > /home/vagrant/www/info.php

echo -e "\n--- Installing CPPCMS ---\n"

cd /home/vagrant
wget http://freefr.dl.sourceforge.net/project/cppcms/cppcms/1.0.5/cppcms-1.0.5.tar.bz2
tar -xvf cppcms-1.0.5.tar.bz2
rm cppcms-1.0.5.tar.bz2
cd cppcms-1.0.5
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
make test
sudo make install

echo -e "\n--- Installing CPPDB ---\n"

cd /home/vagrant
wget http://freefr.dl.sourceforge.net/project/cppcms/cppdb/0.3.1/cppdb-0.3.1.tar.bz2
tar -xvf cppdb-0.3.1.tar.bz2
rm cppdb-0.3.1.tar.bz2
cd cppdb-0.3.1
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
make test
sudo make install

echo -e "\n--- Apache2 configuration --\n"
cd /home/vagrant
echo "<VirtualHost *:80>
  SCGIMount / 127.0.0.1:8080
        ServerAdmin contact@cavaencoreparlerdebits.fr
</VirtualHost>" > default-virtualhost
sudo cp -f default-virtualhost /etc/apache2/sites-available/default

sed -i 's/deb http://ftp.us.debian.org/debian/ wheezy main/deb http://ftp.us.debian.org/debian/ wheezy main non-free/' /etc/apt/source.list
sed -i 's/deb-src http://ftp.us.debian.org/debian/ wheezy main/deb-src http://ftp.us.debian.org/debian/ wheezy main non-free/' /etc/apt/source.list
sed -i 's/deb http://security.debian.org/ wheezy/updates main/deb http://security.debian.org/ wheezy/updates main non-free/' /etc/apt/source.list
sed -i 's/deb-src http://security.debian.org/ wheezy/updates main/deb-src http://security.debian.org/ wheezy/updates main non-free/' /etc/apt/source.list
eval $APTGET update
eval $APTGET install libapache2-mod-scgi
sudo a2enmod scgi
sudo a2moden alias
sudo service apache2 restart


echo -e "\n--- Hello world! ---\n"

cd /home/vagrant/www

echo "{
    \"service\" : {
        \"api\" : \"scgi\",
        \"ip\" : \"127.0.0.1\",
        \"port\" : 8080
    },
    \"http\" : {
        \"script_names\" : [ \"/hello\" ]
    }
}" > config.js

echo "#include <cppcms/application.h>
#include <cppcms/applications_pool.h>
#include <cppcms/service.h>
#include <cppcms/http_response.h>
#include <iostream>

class hello : public cppcms::application {
public:
  hello(cppcms::service &srv) :
    cppcms::application(srv)
  {
  }
  virtual void main(std::string url);
};

void hello::main(std::string /*url*/)
{
  response().out() <<
        \"<html>\n\"
        \"<body>\n\"
        \"  <h1>Hello World</h1>\n\"
        \"</body>\n\"
    \"</html>\n\";
}

int main(int argc,char ** argv)
{
  try {
    cppcms::service srv(argc,argv);

    srv.applications_pool().mount(
                                  cppcms::applications_factory<hello>()
                                    );


    srv.run();
  }
  catch(std::exception const &e) {
    std::cerr << e.what() << std::endl;
  }
}" > helloworld.cpp

c++ helloworld.cpp -lcppcms -o hello

echo "./hello -c config.js"
