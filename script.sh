#!/bin/bash

echo "Bienvenue sur le script d'installation pterodactyl automatique"
echo " "
echo "https://github.com/Romain452/auto_pterodactyl_install.git"

echo " (Contact : r41411300@gmail.com si vous rencontrez un soucis). "




# Vérification des privilèges sudo
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant qu'utilisateur root (sudo)." 
   exit 1
fi

# Affiche le message de début
echo "Début de l'installation des dépendances"

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