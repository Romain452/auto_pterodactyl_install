#!/bin/bash

clear

echo "Bienvenue sur le script d'installation pterodactyl automatique"
echo " "
echo "https://github.com/Romain452/auto_pterodactyl_install.git"

echo " (Contact : r41411300@gmail.com si vous rencontrez un soucis). "

sleep 5
clear

 read -p "Voulez-vous utiliser un nom de domaine pour le Pterodactyl ? (y/n): " ptero_domain_boolean
    if [[ "$ptero_domain_boolean" == "y" ]]; then
      echo $e "${RED}Attention, le nom de domaine doit pointé vers l'adresse IP du serveur."
      read -p "Entrez le nom de domaine: " ptero_domain
    else
      read -p "Entrez l'adresse IP du serveur web (exemple : 10.0.10.12): " ptero_without_ssl_ip
      read -p "Entrez le port à utiliser (exemple : 80): " ptero_without_ssl_port
    fi

# Affiche le message de début
echo "Début de l'installation des dépendances"

sleep 5
clear

# Vérification des privilèges sudo
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant qu'utilisateur root (sudo)." 
   exit 1
fi

# Mise à jour des paquets
apt update

# Installation des dépendances
apt install -y sudo bash curl wget git

# Fin de l'installation
echo "Installation des dépendances terminée"


# Vérification des privilèges sudo
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant qu'utilisateur root (sudo)." 
   exit 1
fi

# Affiche le message de début
echo "Début de l'installation des serveurs webs "

# Mise à jour des paquets
apt update

# Installation des dépendances
apt install -y sudo bash curl wget git

# Installation de Nginx
apt install -y nginx

# Démarrage de Nginx
systemctl start nginx

# Activer le démarrage automatique de Nginx au démarrage du système
systemctl enable nginx

# Installation de MariaDB
apt install -y mariadb-server

# Démarrage de MariaDB
systemctl start mariadb

# Activer le démarrage automatique de MariaDB au démarrage du système
systemctl enable mariadb

# Affichage de l'état de Nginx
systemctl status nginx

# Fin de l'installation
echo "Installation de Nginx terminée"



# Database Configuration

mysql -u root


# Affiche le message de début d'installation pterodactyl
echo "Début de l'installation de pterodactyl"

# Add "add-apt-repository" command
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

#Ajouter le dépôt pour PHP 8.1
curl -sSL https://packages.sury.org/php/README.txt | sudo bash -x

# MariaDB repo setup script can be skipped on Ubuntu 22.04
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Install Dependencies
apt -y install php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

# install composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Download files 
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

cp .env.example .env
composer install --no-dev --optimize-autoloader


# the first time and do not have any Pterodactyl Panel data in the database.
php artisan key:generate --force

php artisan p:environment:setup
php artisan p:environment:database

# custom SMTP server, select "smtp".
php artisan p:environment:mail


php artisan migrate --seed --force


php artisan p:user:make


# If using NGINX or Apache (not on CentOS)
chown -R www-data:www-data /var/www/pterodactyl/*


 cat << EOF | sudo tee /etc/systemd/system/pteroq.service > /dev/null
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF


 sudo systemctl daemon-reload
    sudo systemctl enable pteroq.service
    sudo systemctl start pteroq.service
    sudo systemctl enable --now redis-server
    sudo systemctl enable --now pteroq.service
    if [[ "$ptero_domain_boolean" == "y" ]]; then
    sudo apt update -y
    sudo apt install python3-certbot-nginx -y
    certbot --nginx -d $ptero_domain
    cat << EOF | sudo tee /etc/nginx/sites-enabled/pterodactyl.conf > /dev/null
server_tokens off;
server {
    listen 80;
    server_name $ptero_domain;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $ptero_domain;

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration - Replace the example $ptero_domain with your domain
    ssl_certificate /etc/letsencrypt/live/$ptero_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$ptero_domain/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    else
      cat << EOF | sudo tee /etc/nginx/sites-enabled/pterodactyl.conf > /dev/null
server {
    listen $ptero_without_ssl_port;
    server_name $ptero_without_ssl_ip;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi

systemctl restart nginx




echo -n "Voulez-vous installer wings ? (yes/no): "
read choix

if [ "$choix" = "yes" ]; then
    echo "installation de wings"
    
    
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable --now docker

    mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    systemctl enable --now wings




else
    echo "Arrêt de l'exécution."
fi
