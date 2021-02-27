docker run -d  -p 80:80 -p 443:443 -v  /opt/html:/var/www/html  -t myke94/debian-docker-lamp:latest

# Debian Docker LAMP
A Debian buster slim Docker LAMP. Everything is in one container.

# Features
- Runs as a Docker Container
- Debian Buster slim
- Apache 2.4 (w/ SSL)
- MariaDB 10.3
- PHP 7.3 with OPcache
- SSH
- Adminer
- Git
- Xdebug
- Composer
- Python
- Supervisor
- NodeJS
- NPM
- LESSC
- PimpMyLog
- MailDev

# Example Usage with Data Inside Docker

 Download and run this container with: 
``docker run -d -p 22:22 -p 25:25 -p 80:80 -p 443:443 -p 1080:1080 -p 3306:3306 -p 9000:9000 -p 9001:9001 -t myke94/debian-docker-lamp:latest``

To access the web server visit [https://localhost:443](https://localhost:443) for SSL or [http://localhost](http://localhost) for no SSL.

To access default page apache visit [http://localhost/apache](http://localhost/apache)

To access phpinfo visit [http://localhost/phpinfo](http://localhost/phpinfo)

To access adminer visit [https://localhost/adminer](https://localhost/adminer)

To access PimpMyLog visit [http://localhost/pimpmylog](http://localhost/pimpmylog)

To access MailDev visit [http://localhost:1080](http://localhost:1080)

To access Supervisor status visit [http://localhost:9001](http://localhost:9001)

Attach to the container by running:
`sudo docker exec -i -t "your container id" /bin/bash`

SSH to the container by running:
`ssh root@localhost -p 22` Use password: docker. For Windows and Mac substitute `localhost` with the IP of your docker.
Default root password is docker.

Put your web code in /var/www/html/ inside the docker.

# Example Usage with Data Outside of Docker

Create a project folder and database folder:
`mkdir -p project/database && mkdir -p project/html`

Move into the project folder:
`cd project`

Run the command to launch the docker and map project and database directory:
``docker run -d -p 22:22 -p 25:25 -p 80:80 -p 443:443 -p 1080:1080 -p 3306:3306 -p 9000:9000 -p 9001:9001 -v `pwd`/html:/var/www/html -v `pwd`/database:/var/lib/adminer/upload -t myke94/debian-docker-lamp:latest``

You can now move a copy of your project files into the html folder and move an .sql dump into the database folder, or upload it using Adminer. 

To access the web server visit [https://localhost:443](https://localhost:443) for SSL or [http://localhost](http://localhost) for no SSL.

# To access the database with HeidiSQL

You must create an account.
Connect this in ssh to mysql, then enter the following commands :

`mysql> CREATE USER 'my_user'@'localhost' IDENTIFIED BY 'my_password';`

`mysql> GRANT ALL PRIVILEGES ON *.* TO 'my_user'@'localhost' WITH GRANT OPTION;`

`mysql> CREATE USER 'my_user'@'%' IDENTIFIED BY 'my_password';`

`mysql> GRANT ALL PRIVILEGES ON *.* TO 'my_user'@'%' WITH GRANT OPTION;`

To load Database :

`mysql> use my_db;`

`mysql> source /var/lib/phpMyAdmin/upload/dump.sql;`
