#!/bin/bash

echo "Welcome to the automatic pterodactyl installation script"
echo " "
echo "https://github.com/Romain452/auto_pterodactyl_install.git"
echo " "
echo " This sript allows to update the pannel example you have an error 500, run this script and there will be no more error. If you have a theme issue too." 

sleep 5
clear

# Affiche le message de début
echo "Start of the panel update"

sleep 5
clear

# Vérification des privilèges sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be executed as root (sudo) user." 
   exit 1
fi

cd /var/www/pterodactyl

php artisan down

curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv

chmod -R 755 storage/* bootstrap/cache

composer install --no-dev --optimize-autoloader

php artisan view:clear
php artisan config:clear

php artisan migrate --seed --force

# If using NGINX or Apache (not on CentOS):
chown -R www-data:www-data /var/www/pterodactyl/*

php artisan queue:restart

php artisan up

clear 

echo " Here is the update just finished! " 
