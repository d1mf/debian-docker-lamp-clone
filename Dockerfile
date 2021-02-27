FROM debian:buster-slim

MAINTAINER myke94

COPY sed/php_replace.sed /
COPY sed/replace_opcache.sed /
COPY conf/xdebug.ini /

# Update the repository sources list
RUN apt-get update

# Install basics
RUN apt-get install -y \
	wget \
	nano \
	sudo \
	curl \
	unzip \
	git \
	systemd \
	gnupg2 \
	ca-certificates \
	lsb-release \
	apt-transport-https \
	telnet

RUN apt-get clean

# Configure Timezone
RUN echo "" >> /etc/profile
RUN echo "TZ='Europe/Paris'; export TZ" >> /etc/profile

# Install SSH
RUN apt-get install -y openssh-server
RUN echo 'root:docker' | chpasswd
RUN apt-get install -y passwd
RUN ssh-keygen -A
RUN mkdir -p /run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config

# Install Apache
RUN apt-get install -y \
	apache2 \
	apache2-doc \
	libapache2-mod-php \
	apache2-utils \
	apache2-bin \
	apache2-data
RUN a2enmod rewrite
RUN a2enmod deflate
RUN a2enmod headers

# Install openssl pour https : mod SSL
RUN apt-get install -y openssl
RUN a2enmod ssl
RUN a2ensite default-ssl

# Install PHP
ENV PHP_VERSION 7.3

RUN apt-get install -y php libapache2-mod-php php-cli php-fpm \
    php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear \
    php-bcmath php-common php-dom php-simplexml php-ssh2 php-xmlreader php-exif php-ftp \
    php-iconv php-imagick php-posix php-sockets php-tokenizer php-imap php-bz2 php-intl php-gmp php-gettext php-xdebug
RUN sed -i.back -f php_replace.sed /etc/php/$PHP_VERSION/apache2/php.ini
RUN sed -i.back -f replace_opcache.sed /etc/php/$PHP_VERSION/apache2/conf.d/10-opcache.ini
RUN cat xdebug.ini >> /etc/php/7.3/mods-available/xdebug.ini #/etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini
RUN mkdir /var/log/php
RUN echo "" >> /var/log/php/php_errors.log
# phpinfo access to http://localhost/phpinfo
RUN mkdir /usr/share/phpinfo
RUN echo "<?php phpinfo(); ?>" >> /usr/share/phpinfo/index.php
RUN echo "Alias /phpinfo /usr/share/phpinfo/" >> /etc/apache2/conf-available/phpinfo.conf
RUN a2enconf phpinfo.conf

# Install mariadb
RUN apt-get install -y mariadb-server mariadb-client

# alternative to　"mysql_secure_installation"
RUN service mysql start && \
    mysqladmin -u root password "docker" && \
    mysql -u root -pdocker -e "DELETE FROM mysql.user WHERE User='';" && \
    mysql -u root -pdocker -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1');" && \
    mysql -u root -pdocker -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" && \
    mysql -u root -pdocker -e "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY 'docker';" && \
    mysql -u root -pdocker -e "FLUSH PRIVILEGES;"

RUN sed -i 's/user = */user = debian-sys-maint/' /etc/mysql/debian.cnf
RUN sed -i 's/password = /password = docker/' /etc/mysql/debian.cnf
RUN sed -i 's/bind-address/#bind-address/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Install adminer (like phpmyadmin) access to http://localhost/adminer
ENV ADMINER_VERSION 4.7.7
RUN wget https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php
RUN mkdir /usr/share/adminer
RUN mv adminer-$ADMINER_VERSION.php /usr/share/adminer/index.php
COPY style/adminer.css /usr/share/adminer/adminer.css
COPY conf/adminer.conf /etc/apache2/conf-available/adminer.conf
RUN a2enconf adminer.conf
RUN mkdir /var/lib/adminer && mkdir /var/lib/adminer/upload

# Install supervisor access to http://localhost:9001
RUN apt-get install -y supervisor
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY conf/apache.conf /etc/supervisor/conf.d/apache.conf
COPY conf/mariadb.conf /etc/supervisor/conf.d/mariadb.conf
COPY conf/ssh.conf /etc/supervisor/conf.d/ssh.conf

# Install NodeJS/npm, composer, Less
ENV NODEJS_VERSION 14
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN curl -sL https://deb.nodesource.com/setup_$NODEJS_VERSION.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get install -y nodejs
RUN apt-get install -y build-essential
RUN npm install -g less

# mailDev http://localhost:1080
RUN npm install -g maildev
COPY conf/maildev.conf /etc/supervisor/conf.d/maildev.conf

# Install PimpMyLog  http://localhost/pimpmylog
RUN cd /usr/share; git clone https://github.com/potsky/PimpMyLog.git
RUN echo "Alias /pimpmylog /usr/share/PimpMyLog/" >> /etc/apache2/conf-available/pimpmylog.conf
ADD conf/config.user.json /usr/share/PimpMyLog/config.user.json
RUN a2enconf pimpmylog.conf

# http://localhost/apache
RUN mkdir /usr/share/apache2-defaultpage
RUN mv /var/www/html/index.html /usr/share/apache2-defaultpage/index.html
RUN echo "Alias /apache /usr/share/apache2-defaultpage/" >> /etc/apache2/conf-available/apache2-defaultpage.conf
RUN a2enconf apache2-defaultpage.conf

# Set correct rights
RUN chown -R www-data:www-data /var/www/html
RUN chown -R www-data:www-data /var/log
RUN chown -R www-data:www-data /usr/share/PimpMyLog
RUN chown -R www-data:www-data /usr/share/adminer
RUN chown -R www-data:www-data /usr/share/phpinfo
RUN chown -R www-data:www-data /usr/share/apache2-defaultpage

RUN apt-get clean
# file cleaning
RUN rm php_replace.sed
RUN rm replace_opcache.sed
RUN rm xdebug.ini
RUN rm composer-setup.php
RUN rm nodesource_setup.sh

VOLUME /var/www/html /var/lib/adminer/upload
# Open ports
# 22 = ssh; 25 = smtp; 80=http; 443=https; 1080=mailDev; 3306=mysql; 9000=xdebug; 9001=supervisor
EXPOSE 22 25 80 443 1080 3306 9000 9001

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
