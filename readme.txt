git clone https://github.com/Romain452/auto_pterodactyl_install.git

chmod +x ./auto_pterodactyl_install/script.sh

cd /root/auto_pterodactyl_install

bash script.sh


-----------------------------

CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'YOUR_PASSWORD';

CREATE DATABASE panel;

GRANT ALL PRIVILEGES ON *.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;

exit