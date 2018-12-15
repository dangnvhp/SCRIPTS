#!/bin/bash

printf "
   _____                   __
  / ___/____  ____  ____ _/ /_  ____ _____  ____  ____  ____
  \__ \/ __ \/ __ \/ __ `/ __ \/ __ `/ __ \/ __ \/ __ \/ __ \
 ___/ / /_/ / / / / /_/ / / / / /_/ / / / / /_/ / /_/ / /_/ /
/____/\____/_/ /_/\__, /_/ /_/\__,_/_/ /_/ .___/\____/\____/
                 /____/                 /_/


"
 
read -p "Site name: " sitename
if [ -z "$sitename" ]
then 
	echo "Sitename can't be empty."
else
	read -p "Document root [Default /var/www/$sitename/html]: " documentroot
	read -p "Apache port number [Default 8080]: " httpdport
	read -p "Nginx port number [Default 80]: " nginxport
	read -p "PHP version [php56,php70,php71,php72] [Default php56]: " phpversion
	read -p "PHP handler [0: Apache handler,1: fpm handler] [Default 0]: " phphandler
	read -p "Install php sqlsrv extension ? [y/n]: " sqlsrvext

	if [ $phphandler == 1 ]
	then 
		read -p "fpm port number [Default 9000]: " fpmport
		if [ -z "$fpmport" ]
		then 
			fpmport=9000
		fi 
	else fpmport=9000
	fi

	if [ -z "$documentroot" ]
	then 
		documentroot="/var/www/$sitename/html"
	fi

	if [ -z "$httpdport" ]
	then 
		httpdport=8080
	fi

	if [ -z "$nginxport" ]
	then 
		nginxport=80
	fi

	if [ -z "$phpversion" ]
	then 
		phpversion="php56"
	fi

	if [ -z "$phphandler" ]
	then 
		phphandler=0
	fi

	## Start

		## Remi Dependency on CentOS 7 and Red Hat (RHEL) 7 ##
			rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
			rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
			yum update
			yum -y install yum-utils
			
			if [ $phpversion == "php56" ]
			then
				yum-config-manager --enable remi-php56
				echo "PHP 5.6 enabled"
			elif [ $phpversion == "php70" ]
			then 
				yum-config-manager --enable remi-php70
				echo "PHP 7.0 enabled"
			elif [ $phpversion == "php71" ]
			then
				yum-config-manager --enable remi-php71
				echo "PHP 7.1 enabled"
			elif [ $phpversion == "php72" ]
			then
				yum-config-manager --enable remi-php72
				echo "PHP 7.2 enabled"
			fi
		## Install php httpd
			yum update
			yum -y install httpd php php-pdo php-xml php-pear php-devel php-pecl-apcu php-cli php-mysqlnd php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-zip php-ldap
		## Install nginx
			printf '[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/centos/7/$basearch/ \ngpgcheck=0\nenabled=1\n' > /etc/yum.repos.d/nginx.repo
			yum update 
			yum -y install nginx
			
		# Install php-fpm & config php-fpm
			if [ $phphandler == 1 ]
			then
				yum -y install php-fpm
				sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:$fpmport/g" /etc/php-fpm.d/www.conf
				
				cp /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf_bak
				oldhandler="SetHandler application/x-httpd-php"
				newhandler="SetHandler proxy:fcgi://127.0.0.1:$fpmport"
				sed -i "s%$oldhandler%$newhandler%g" /etc/httpd/conf.d/php.conf
			fi
				
		if [ ! -d "$documentroot" ]
		then 
				mkdir -p $documentroot
		fi
		
		# Configure httpd
			cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf_bak
			sed -i "s/Listen 80/Listen 127.0.0.1:$httpdport/g" /etc/httpd/conf/httpd.conf
			echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
			
			# Create vitual host
			if [ ! -d /etc/httpd/sites-available ]
			then 
				mkdir /etc/httpd/sites-available
			fi
			if [ ! -d /etc/httpd/sites-enabled ]
			then 
				mkdir /etc/httpd/sites-enabled
			fi
			printf "<VirtualHost 127.0.0.1:$httpdport>
ServerName www.$sitename
ServerAlias $sitename
DocumentRoot $documentroot
ErrorLog /var/log/httpd/$sitename.error.log
CustomLog /var/log/httpd/$sitename.access.log common
<Directory $documentroot>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
</Directory>
</VirtualHost>
" > /etc/httpd/sites-available/$sitename.conf
			ln -sf /etc/httpd/sites-available/$sitename.conf /etc/httpd/sites-enabled/$sitename.conf
			
		# Configure nginx
			cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_bak
			
			if [ ! -d /etc/nginx/sites-available ]
			then 
				mkdir /etc/nginx/sites-available
			fi
			
			oldline="keepalive_timeout  65;"
			newline="keepalive_timeout 5000;types_hash_max_size 2048;client_max_body_size 2000M;" 
			sed -i "s/$oldline/$newline/g" /etc/nginx/nginx.conf
			host='$host'
			remote_addr='$remote_addr'
			proxy_add_x_forwarded_for='$proxy_add_x_forwarded_for'
			uri='$uri'
			
			printf "server {
        listen $nginxport;

        server_name $sitename;
        root $documentroot;
        index index.php index.html index.htm;
        error_log /var/log/nginx/$sitename.error.log;
        access_log /var/log/nginx/$sitename.access.log;

        location / {
				proxy_pass   http://127.0.0.1:$httpdport;
				location ~* ^.+\.(jpeg|jpg|png|gif|bmp|ico|svg|tif|tiff|css|js|htm|html|ttf|otf|webp|woff|txt|csv|rtf|doc|docx|xls|xlsx|ppt|pptx|odf|odp|ods|odt|pdf|psd|ai|eot|eps|ps|zip|tar|tgz|gz|rar|bz2|7z|aac|m4a|mp3|mp4|ogg|wav|wma|3gp|avi|flv|m4v|mkv|mov|mpeg|mpg|wmv|exe|iso|dmg|swf)$ {
                        root $documentroot;
                        expires        max;
                        try_files      $uri @fallback;
                }
                proxy_set_header        Host $host;
                proxy_set_header        X-Real-IP $remote_addr;
                proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header        X-Forwarded-Proto https;
                proxy_redirect off;
                proxy_connect_timeout       6000;
                proxy_send_timeout          6000;
                proxy_read_timeout          6000;
                send_timeout                6000;
        }
		
		location @fallback {
                proxy_pass      http://127.0.0.1:$httpdport;
        }
}
" > /etc/nginx/sites-available/$sitename.conf
		ln -sf /etc/nginx/sites-available/$sitename.conf /etc/nginx/conf.d/$sitename.conf
		
	# Start service
	setenforce 0
	systemctl restart php-fpm 
	systemctl restart httpd 
	systemctl restart nginx
	firewall-cmd --permanent --zone=public --add-port=$nginxport/tcp
	firewall-cmd --reload
	
	echo "" > $documentroot/index.php
	echo "<?php phpinfo(); ?>" > $documentroot/info.php
	
	if [ $phphandler == 1 ]
	then
		if [ $(ps -ef | grep -v grep | grep php-fpm | wc -l) > 0 ] && [ $(ps -ef | grep -v grep | grep httpd | wc -l) > 0 ] && [ $(ps -ef | grep -v grep | grep nginx | wc -l) > 0 ]
		then 
			echo "Web server installed successfully."
			echo "Document root directory: $documentroot"
			echo "Apache configure: /etc/httpd/sites-available/$sitename.conf"
			echo "Nginx configure: /etc/nginx/sites-available/$sitename.conf"
			echo "Test link: $sitename/info.php"
		else 
			echo "Web server install unsuccessfully"
		fi
	else 
		if [ $(ps -ef | grep -v grep | grep httpd | wc -l) > 0 ] && [ $(ps -ef | grep -v grep | grep nginx | wc -l) > 0 ]
		then 
			echo "Web server installed successfully."
			echo "Document root directory: $documentroot"
			echo "Apache configure: /etc/httpd/sites-available/$sitename.conf"
			echo "Nginx configure: /etc/nginx/sites-available/$sitename.conf"
			echo "Test link: $sitename/info.php"
		else 
			echo "Web server install unsuccessfully"
		fi
	fi
fi
