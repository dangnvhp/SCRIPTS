#!/bin/bash
mariadbrepo="/etc/yum.repos.d/Mariadb.repo"

//check repo mariadb
if [ -f "$mariadbrepo" ]
then
        echo "$mariadbrepo 10 found."
else


echo " [mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1 " >> /etc/yum.repos.d/Mariadb.repo

        echo "$mariadbrepo 10 install completed"
fi

if [ -f "$phprepo" ]
then
        echo "$phprepo found"
else

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
        echo "$phprepo install completed"
fi



echo  "Enter your command "
echo -n "1.php 7.0 - "
echo -n "2.php 7.1 - "
echo -n "3.php 7.2  "

read command

case "$command" in
1)
echo "enable config yum repo 7.0 "
echo "your system install completed php php-fpm php-mysql mariadb-server mariadb nginx"
yum-config-manager --enable remi-php70
yum install php php-mysql php-fpm mariadb-server mariadb nginx php-memcached php-opcache -y
;;
2)
echo "enable config yum repo 7.2"
yum-config-manager --enable remi-php71
yum install php php-mysql php-fpm mariadb-server mariadb nginx php-memcached php-opcache -y
echo "your system install completed php php-fpm php-mysql mariadb-server mariadb nginx"
;;
3)
echo "enable config yum repo 7.2"
yum-config-manager --enable remi-php72
yum install php php-mysql php-fpm mariadb-server mariadb nginx php-memcached php-opcache -y
echo "your system install completed php php-fpm php-mysql mariadb-server mariadb nginx"
;;
*)
echo "Bad command, your only input number : 1 , 2 , 3"
;;
esac
exit
