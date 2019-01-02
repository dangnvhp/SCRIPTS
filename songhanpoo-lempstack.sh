#!/bin/bash


 
read -p "Site name: " sitename
if [ -z "$sitename" ]
then 
	echo "Sitename can't be empty."
else
	read -p "Document root [Default /home/$sitename]: " documentroot
	read -p "PHP version [php56,php70,php71,php72] [Default php72]: " phpversion
	read -p "PHP handler [0: Apache handler,1: fpm handler] [Default 1]: " phphandler
	read -p "Install phpmyadmin and authentication conn[default yes = 1] " phpmyadmin
	read -p "Locate phpmyadmin [Default /home/html] : " phpmyadminlocate
	

	if [ -z "$documentroot" ]
	then 
		documentroot="/home/$sitename"
	fi

	if [ -z "$phpversion" ]
	then 
		phpversion="php72"
	fi
	if [ -z "$phphandler" ]
	then 
		phphandler=1
	fi
	if [ -z "$phpmyadmin" ]
	then 
		phpmyadmin=1
	fi
	if [ -z "$phpmyadminlocate" ]
	then 
		phpmyadminlocate="/home/$phpmyadminlocate"
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
			yum -y install php php-pdo php-memcached php-opcache php-xml php-pear php-devel php-pecl-apcu php-cli php-mysqlnd php-pecl-memcache php-pecl-memcached php-gd php-mbstring php-mcrypt php-zip php-ldap
		## Install nginx
			printf '[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/centos/7/$basearch/ \ngpgcheck=0\nenabled=1\n' > /etc/yum.repos.d/nginx.repo
			yum update 
			yum -y install nginx
			
		# Install php-fpm & config php-fpm
			if [ $phphandler == 1 ]
			then
				yum -y install php-fpm
				sed -i "s/listen = 127.0.0.1:9000/listen = /run/php-fpm/php-fpm.sock/g" /etc/php-fpm.d/www.conf
				sed -i "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf
				sed -i "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf
				sed -i "s/;listen.owner = nobody/listen.owner  = nginx/g" /etc/php-fpm.d/www.conf
				sed -i "s/;listen.group = nobody/listen.group = nginx/g" /etc/php-fpm.d/www.conf
				sed -i "s/;cgi.fix_pathinfo = 1/cgi.fix_pathinfo = 0/g" /etc/php.ini
				sed -i "s/upload_max_filesize = 2M/cupload_max_filesize = 100M
/g" /etc/php.ini
sed -i "s/max_execution_time = 30/max_execution_time = 2000
/g" /etc/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 256M
/g" /etc/php.ini
sed -i "s/max_input_time = 60/max_input_time = -1
/g" /etc/php.ini
			fi

				
		if [ ! -d "$documentroot" ]
		then 
				mkdir -p $documentroot
		fi
		# Install phpmyadmin & config
		if [ ! -d "$phpmyadminlocate" ]
		then 
				mkdir -p $phpmyadminlocate
				if [ $phpmyadmin == 1 ]
			then
				yum -y install phpmyadmin
				ln -s /usr/share/phpMyAdmin $phpmyadminlocate
			fi
		fi
			
		
		# Configure nginx
			cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf_bak
			
			if [ ! -d /etc/nginx/sites-available ]
			then 
				mkdir /etc/nginx/sites-available
			fi
			
			oldline="keepalive_timeout  65;"
			newline="keepalive_timeout 5000;types_hash_max_size 2048;client_max_body_size 2000M;" 
			sed -i "s/$oldline/$newline/g" /etc/nginx/nginx.conf
			ip = `curl http://icanhazip.com`
		printf "
		server {
        listen   80;
        server_name $ip;
        root /home/html;

location / {
        index  index.php;
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/.htpasswd;
}

## Images and static content is treated different
        location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
        access_log        off;
        expires           30d;
}

location ~ /\.ht {
        deny  all;
}

location ~ /(libraries|setup/frames|setup/libs) {
        deny all;
        return 404;
}

location ~ \.php$ {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $phpmyadminlocate$fastcgi_script_name;
}
}

" > /etc/nginx/sites-available/$sitename.conf
		ln -sf /etc/nginx/sites-available/$sitename.conf /etc/nginx/conf.d/$sitename.conf	
			
		
			printf "
		server {
    listen 80;
        //ssl        on;
        //ssl_certificate         /data/ssl/certificate.pem;
        //ssl_certificate_key     /data/ssl/private.pem;
        //ssl_client_certificate  /data/ssl/cloudflare.crt;
        //ssl_verify_client on;

    server_name  $sitename;
    root   $documentroot;
    index index.php index.html index.htm;

    location / {
        server_tokens off;
        client_max_body_size 20m;
        client_body_buffer_size 128k;
        root $documentroot;
        index index.php index.html index.htm;
        try_files $uri $uri/ /index.php?$args;
        if (-f $request_filename) {
        expires 365d;
        break;
    }}
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root $documentroot;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $documentroot$fastcgi_script_name;
        include fastcgi_params;
    }
}
" > /etc/nginx/sites-available/$sitename.conf
		ln -sf /etc/nginx/sites-available/$sitename.conf /etc/nginx/conf.d/$sitename.conf
		
	# Start service
	setenforce 0
	systemctl restart php-fpm 
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
			echo "Please yum install -y httpd-tools and htpasswd -c /etc/nginx/.htpasswd userlogin "
			echo "Document root directory: $documentroot"
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
			echo "Nginx configure: /etc/nginx/sites-available/$sitename.conf"
			echo "Test link: $sitename/info.php"
		else 
			echo "Web server install unsuccessfully"
		fi
	fi
fi
